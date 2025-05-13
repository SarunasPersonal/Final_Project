// lib/admin/bookings_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_ucs_app/constants.dart';
import 'package:flutter_ucs_app/booking_model.dart';
import 'package:flutter_ucs_app/models/room_model.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:logging/logging.dart';

class BookingsManagementScreen extends StatefulWidget {
  const BookingsManagementScreen({super.key});

  @override
  State<BookingsManagementScreen> createState() => _BookingsManagementScreenState();
}

class _BookingsManagementScreenState extends State<BookingsManagementScreen> with SingleTickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  final RoomService _roomService = RoomService();
  final Logger _logger = Logger('BookingsManagementScreen');
  
  List<Booking> _bookings = [];
  List<Booking> _filteredBookings = [];
  final Map<String, Room> _roomsCache = {}; // Made final as suggested
  bool _isLoading = true;
  
  // Filtering and sorting
  String _searchQuery = '';
  String _filterStatus = 'All';
  String _filterCampus = 'All Campuses';
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
    
    // Add listener for tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _applyFilters();
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // Load all bookings from Firebase
  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get all bookings
      final allBookings = await _bookingService.getAllBookings();
      
      // Preload room data for all bookings
      await _preloadRoomData(allBookings);
      
      if (mounted) {
        setState(() {
          _bookings = allBookings;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.warning('Error loading bookings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Error loading bookings: $e', color: Colors.red);
      }
    }
  }
  
  // Preload room data to avoid repeated Firestore queries
  Future<void> _preloadRoomData(List<Booking> bookings) async {
    try {
      // Extract unique room IDs - Fix: using non-nullable Set<String>
      final Set<String> roomIds = bookings
          .where((b) => b.roomId != null)
          .map((b) => b.roomId!)
          .toSet();
      
      // Load each room's data
      for (final roomId in roomIds) {
        if (!_roomsCache.containsKey(roomId)) {
          final room = await _roomService.getRoomById(roomId);
          if (room != null) {
            _roomsCache[roomId] = room;
          }
        }
      }
    } catch (e) {
      _logger.warning('Error preloading room data: $e');
    }
  }
  
  // Apply filters based on search query, status, and tab
  void _applyFilters() {
    if (!mounted) return;
    
    setState(() {
      // Start with all bookings
      List<Booking> filtered = List<Booking>.from(_bookings);
      
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        filtered = filtered.where((booking) => 
          booking.userEmail.toLowerCase().contains(query) ||
          booking.location.toLowerCase().contains(query) ||
          (booking.notes != null && booking.notes!.toLowerCase().contains(query))
        ).toList();
      }
      
      // Filter by status
      if (_filterStatus != 'All') {
        filtered = filtered.where((booking) => 
          booking.status.toLowerCase() == _filterStatus.toLowerCase()
        ).toList();
      }
      
      // Filter by campus/location
      if (_filterCampus != 'All Campuses') {
        filtered = filtered.where((booking) => 
          booking.location == _filterCampus
        ).toList();
      }
      
      // Filter by tab
      final now = DateTime.now();
      if (_tabController.index == 0) { // All bookings
        // No additional filtering
      } else if (_tabController.index == 1) { // Upcoming
        filtered = filtered.where((booking) => 
          booking.dateTime.isAfter(now) && booking.status != 'cancelled'
        ).toList();
      } else if (_tabController.index == 2) { // Past & Cancelled
        filtered = filtered.where((booking) => 
          booking.dateTime.isBefore(now) || booking.status == 'cancelled'
        ).toList();
      }
      
      // Sort by date, newest first
      filtered.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      _filteredBookings = filtered;
    });
  }
  
  // View booking details
  void _viewBookingDetails(Booking booking) {
    // Lookup room from cache
    final String roomId = booking.roomId ?? '';
    final room = _roomsCache[roomId];
    // Removed unused variable
    final endTime = booking.dateTime.add(Duration(minutes: booking.duration));
    final formattedEndTime = DateFormat('h:mm a').format(endTime);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Details', style: TextStyle(color: primaryColor)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Status', booking.status, getStatusColor(booking.status)),
              const Divider(),
              _buildDetailItem('User', booking.userEmail),
              _buildDetailItem('Campus', booking.location),
              _buildDetailItem('Room', room?.name ?? roomId),
              _buildDetailItem('Room Type', booking.roomType.displayName),
              _buildDetailItem('Date', DateFormat('EEEE, MMMM d, yyyy').format(booking.dateTime)),
              _buildDetailItem('Time', '${DateFormat('h:mm a').format(booking.dateTime)} - $formattedEndTime'),
              _buildDetailItem('Duration', '${booking.duration} minutes'),
              
              if (booking.notes != null && booking.notes!.isNotEmpty)
                _buildDetailItem('Notes', booking.notes!),
                
              if (booking.features.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Room Features:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: booking.features.map((feature) {
                    return Chip(
                      label: Text(feature.displayName, style: const TextStyle(fontSize: 12)),
                      avatar: Icon(feature.icon, size: 16),
                      backgroundColor: Colors.grey.shade100,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          // Cancel button
          if (booking.dateTime.isAfter(DateTime.now()) && booking.status != 'cancelled')
            TextButton(
              child: const Text('Cancel Booking', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.pop(context);
                _cancelBooking(booking);
              },
            ),
            
          // Close button
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
          
          // Mark as completed button (for admin)
          if (booking.dateTime.isBefore(DateTime.now()) && booking.status != 'completed' && booking.status != 'cancelled')
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: const Text('Mark Completed', style: TextStyle(color: secondaryColor)),
              onPressed: () {
                Navigator.pop(context);
                _updateBookingStatus(booking, 'completed');
              },
            ),
        ],
      ),
    );
  }
  
  // Cancel a booking
  Future<void> _cancelBooking(Booking booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cancellation'),
        content: Text('Are you sure you want to cancel the booking for ${booking.userEmail}?'),
        actions: [
          TextButton(
            child: const Text('No'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _bookingService.updateBookingStatus(booking.id, 'cancelled');
      _loadBookings(); // Reload all bookings
      
      if (mounted) {
        _showSnackBar('Booking cancelled successfully', color: Colors.green);
      }
    } catch (e) {
      _logger.warning('Error cancelling booking: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Error cancelling booking: $e', color: Colors.red);
      }
    }
  }
  
  // Update booking status
  Future<void> _updateBookingStatus(Booking booking, String status) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _bookingService.updateBookingStatus(booking.id, status);
      _loadBookings(); // Reload all bookings
      
      if (mounted) {
        _showSnackBar('Booking marked as $status', color: Colors.green);
      }
    } catch (e) {
      _logger.warning('Error updating booking status: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Error updating booking: $e', color: Colors.red);
      }
    }
  }
  
  // Helper to build a detail item in the dialog
  Widget _buildDetailItem(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
  
  // Show a snackbar message
  void _showSnackBar(String message, {Color color = Colors.black}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  // Get color for booking status
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section with title and stats
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage Bookings',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total bookings: ${_bookings.length}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                // Refresh button
                IconButton(
                  icon: const Icon(Icons.refresh, color: primaryColor),
                  onPressed: _loadBookings,
                  tooltip: 'Refresh bookings',
                ),
              ],
            ),
          ),
          
          // Tab bar for filtering
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'All Bookings'),
              Tab(text: 'Upcoming'),
              Tab(text: 'Past & Cancelled'),
            ],
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primaryColor,
          ),
          
          // Search and filter bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Search field
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by user email or campus...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                
                // Status filter
                DropdownButton<String>(
                  value: _filterStatus,
                  hint: const Text('Status'),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _filterStatus = newValue;
                      });
                      _applyFilters();
                    }
                  },
                  items: <String>['All', 'Pending', 'Confirmed', 'Cancelled', 'Completed']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                
                const SizedBox(width: 16),
                
                // Campus filter
                DropdownButton<String>(
                  value: _filterCampus,
                  hint: const Text('Campus'),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _filterCampus = newValue;
                      });
                      _applyFilters();
                    }
                  },
                  items: <String>['All Campuses', 'Taunton', 'Bridgwater', 'Cannington']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          // Bookings table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : _filteredBookings.isEmpty
                    ? _buildEmptyState()
                    : _buildBookingsTable(),
          ),
        ],
      ),
    );
  }
  
  // Build empty state message
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No bookings found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _filterStatus != 'All' || _filterCampus != 'All Campuses'
                ? 'Try adjusting your filters'
                : 'No bookings have been made yet',
            style: const TextStyle(color: Colors.grey),
          ),
          if (_searchQuery.isNotEmpty || _filterStatus != 'All' || _filterCampus != 'All Campuses')
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                child: const Text('Clear Filters', style: TextStyle(color: secondaryColor)),
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _filterStatus = 'All';
                    _filterCampus = 'All Campuses';
                  });
                  _applyFilters();
                },
              ),
            ),
        ],
      ),
    );
  }
  
  // Build bookings data table
  Widget _buildBookingsTable() {
    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 12,
      minWidth: 800,
      columns: const [
        DataColumn2(
          label: Text('User'),
          size: ColumnSize.M,
        ),
        DataColumn2(
          label: Text('Campus'),
          size: ColumnSize.S,
        ),
        DataColumn2(
          label: Text('Room'),
          size: ColumnSize.M,
        ),
        DataColumn2(
          label: Text('Date & Time'),
          size: ColumnSize.L,
        ),
        DataColumn2(
          label: Text('Status'),
          size: ColumnSize.S,
        ),
        DataColumn2(
          label: Text('Actions'),
          size: ColumnSize.S,
        ),
      ],
      rows: _filteredBookings.map((booking) {
        final roomId = booking.roomId ?? '';
        final room = _roomsCache[roomId];
        final isUpcoming = booking.dateTime.isAfter(DateTime.now());
        
        return DataRow(
          cells: [
            // User
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(booking.userEmail, overflow: TextOverflow.ellipsis),
                ],
              ),
              onTap: () => _viewBookingDetails(booking),
            ),
            // Campus
            DataCell(
              Text(booking.location),
              onTap: () => _viewBookingDetails(booking),
            ),
            // Room
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(room?.name ?? 'Unknown Room', overflow: TextOverflow.ellipsis),
                  Text(
                    booking.roomType.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              onTap: () => _viewBookingDetails(booking),
            ),
            // Date & Time
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('MMM d, yyyy').format(booking.dateTime)),
                  Text(
                    '${DateFormat('h:mm a').format(booking.dateTime)} (${booking.duration} min)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              onTap: () => _viewBookingDetails(booking),
            ),
            // Status
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: getStatusColor(booking.status).withAlpha(26), // Using withAlpha instead of withOpacity
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  booking.status,
                  style: TextStyle(
                    color: getStatusColor(booking.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onTap: () => _viewBookingDetails(booking),
            ),
            // Actions
            DataCell(
              Row(
                children: [
                  // View details button
                  IconButton(
                    icon: const Icon(Icons.visibility, color: primaryColor),
                    onPressed: () => _viewBookingDetails(booking),
                    tooltip: 'View Details',
                  ),
                  // Cancel booking button (only for upcoming bookings)
                  if (isUpcoming && booking.status != 'cancelled')
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                      onPressed: () => _cancelBooking(booking),
                      tooltip: 'Cancel Booking',
                    ),
                  // Complete booking button (for past bookings that aren't complete or cancelled)
                  if (!isUpcoming && booking.status != 'completed' && booking.status != 'cancelled')
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                      onPressed: () => _updateBookingStatus(booking, 'completed'),
                      tooltip: 'Mark Completed',
                    ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}