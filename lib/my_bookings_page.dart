// lib/my_bookings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_ucs_app/constants.dart';
import 'package:flutter_ucs_app/models/room_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_ucs_app/booking_model.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({Key? key}) : super(key: key);

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> with SingleTickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  List<Booking> _userBookings = [];
  List<Booking> _filteredBookings = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterStatus = 'All';
  
  // Tab controller for upcoming/past bookings
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserBookings();
    
    // Listen for tab changes
    _tabController.addListener(() {
      _applyFilters();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Updated to use async Firebase calls
  Future<void> _loadUserBookings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (CurrentUser.userId != null) {
        // Get bookings from Firebase
        final bookings = await _bookingService.getUserBookings(CurrentUser.userId!);
        
        if (mounted) {
          setState(() {
            _userBookings = bookings;
            _applyFilters();
            _isLoading = false;
          });
        }
      } else {
        // Handle case where no user is logged in
        if (mounted) {
          setState(() {
            _userBookings = [];
            _filteredBookings = [];
            _isLoading = false;
          });
          
          _showSnackBar('No user logged in. Please log in to view your bookings.', 
              color: Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Error loading bookings: $e', color: Colors.red);
      }
    }
  }

  // Apply filters for search and status
  void _applyFilters() {
    if (!mounted) return;
    
    setState(() {
      // Start with all bookings
      var filtered = List<Booking>.from(_userBookings);
      
      // Filter by search query if not empty
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        filtered = filtered.where((booking) => 
          booking.location.toLowerCase().contains(query) ||
          booking.roomType.displayName.toLowerCase().contains(query) ||
          (booking.notes != null && booking.notes!.toLowerCase().contains(query))
        ).toList();
      }
      
      // Filter by status if not "All"
      if (_filterStatus != 'All') {
        filtered = filtered.where((booking) => 
          booking.status.toLowerCase() == _filterStatus.toLowerCase()
        ).toList();
      }
      
      // Filter by upcoming/past based on tab
      final now = DateTime.now();
      if (_tabController.index == 0) { // Upcoming
        filtered = filtered.where((booking) => 
          booking.dateTime.isAfter(now) && booking.status != 'cancelled'
        ).toList();
        
        // Sort by earliest first for upcoming
        filtered.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      } else { // Past or cancelled
        filtered = filtered.where((booking) => 
          booking.dateTime.isBefore(now) || booking.status == 'cancelled'
        ).toList();
        
        // Sort by most recent first for past
        filtered.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      }
      
      _filteredBookings = filtered;
    });
  }

  // Format a DateTime object into a readable string
  String _formatDateTime(DateTime dateTime) {
    final dateFormat = DateFormat('EEE, MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    return '${dateFormat.format(dateTime)} at ${timeFormat.format(dateTime)}';
  }

  // Get an icon based on the booking location
  IconData _getIconForLocation(String location) {
    switch (location) {
      case 'Taunton':
        return Icons.school;
      case 'Bridgwater':
        return Icons.account_balance;
      case 'Cannington':
        return Icons.park;
      default:
        return Icons.location_on;
    }
  }

  // Show a confirmation dialog and delete a booking if confirmed
  void _deleteBooking(Booking booking) {
    // Don't allow deleting past bookings or completed bookings
    if (booking.dateTime.isBefore(DateTime.now()) || 
        booking.status == 'completed' ||
        booking.status == 'cancelled') {
      _showSnackBar('Cannot delete past, completed or cancelled bookings', 
          color: Colors.red);
      return;
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: const Text('Are you sure you want to cancel this booking?'),
          actions: [
            // Cancel button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('NO', style: TextStyle(color: Colors.grey)),
            ),
            // Confirm button
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                setState(() => _isLoading = true);
                
                try {
                  // Update status to cancelled
                  bool success = await _bookingService.updateBookingStatus(
                    booking.id, 
                    'cancelled'
                  );
                  
                  if (mounted) {
                    if (success) {
                      _showSnackBar('Booking cancelled successfully', 
                          color: Colors.green);
                      // Reload bookings after cancellation
                      await _loadUserBookings();
                    } else {
                      _showSnackBar('Failed to cancel booking', 
                          color: Colors.red);
                      setState(() => _isLoading = false);
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    _showSnackBar('Error: $e', color: Colors.red);
                    setState(() => _isLoading = false);
                  }
                }
              },
              child: const Text('YES', style: TextStyle(color: primaryColor)),
            ),
          ],
        );
      },
    );
  }
  
  // Show booking details dialog
  void _showBookingDetails(Booking booking) {
    final formattedDateTime = _formatDateTime(booking.dateTime);
    final endTime = booking.dateTime.add(Duration(minutes: booking.duration));
    final formattedEndTime = DateFormat('h:mm a').format(endTime);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getIconForLocation(booking.location),
              color: primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Booking Details',
                style: TextStyle(color: primaryColor),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Location', booking.location),
              _buildDetailRow('Room Type', booking.roomType.displayName),
              _buildDetailRow('Date & Time', formattedDateTime),
              _buildDetailRow('End Time', formattedEndTime),
              _buildDetailRow('Duration', '${booking.duration} minutes'),
              _buildDetailRow('Status', _getStatusText(booking.status)),
              if (booking.notes != null && booking.notes!.isNotEmpty)
                _buildDetailRow('Notes', booking.notes!),
              if (booking.features.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Room Features:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: booking.features.map((feature) {
                    return Chip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(feature.icon, size: 16),
                          const SizedBox(width: 4),
                          Text(feature.displayName),
                        ],
                      ),
                      backgroundColor: Colors.grey.shade100,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (booking.dateTime.isAfter(DateTime.now()) && 
              booking.status != 'cancelled' &&
              booking.status != 'completed')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteBooking(booking);
              },
              child: const Text('Cancel Booking', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }
  
  // Helper method for building detail rows in the dialog
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  // Get formatted status with color coding
  String _getStatusText(String status) {
    return status.substring(0, 1).toUpperCase() + status.substring(1);
  }
  
  // Get color for status
  Color _getStatusColor(String status) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context), // Navigate back
        ),
        title: const Text(
          'My Bookings',
          style: TextStyle(color: primaryColor),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          indicatorColor: primaryColor,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past & Cancelled'),
          ],
        ),
        actions: [
          // Add a refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: primaryColor),
            onPressed: _loadUserBookings,
            tooltip: 'Refresh bookings',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                // Search and filter bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Search field
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search bookings...',
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
                      const SizedBox(width: 8),
                      
                      // Status filter
                      DropdownButton<String>(
                        value: _filterStatus,
                        hint: const Text('Status'),
                        underline: Container(
                          height: 2,
                          color: primaryColor,
                        ),
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
                    ],
                  ),
                ),
                
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Upcoming bookings tab
                      _userBookings.isEmpty
                          ? _buildEmptyState()
                          : _filteredBookings.isEmpty
                              ? _buildNoResultsState()
                              : _buildBookingsList(),
                              
                      // Past bookings tab
                      _userBookings.isEmpty
                          ? _buildEmptyState()
                          : _filteredBookings.isEmpty
                              ? _buildNoResultsState()
                              : _buildBookingsList(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () => Navigator.pop(context), // Navigate back to booking page
        child: const Icon(Icons.add, color: secondaryColor),
        tooltip: 'Book a new room',
      ),
    );
  }

  // Build the UI for the empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.calendar_today,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text(
            'No bookings found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'You haven\'t made any bookings yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => Navigator.pop(context), // Navigate back
            child: const Text(
              'Book Now',
              style: TextStyle(color: secondaryColor),
            ),
          ),
        ],
      ),
    );
  }
  
  // Build the UI for no search results
  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text(
            'No matching bookings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _filterStatus = 'All';
              });
              _applyFilters();
            },
            child: const Text(
              'Clear Filters',
              style: TextStyle(color: secondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  // Build the list of bookings
  Widget _buildBookingsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredBookings.length,
      itemBuilder: (context, index) {
        final booking = _filteredBookings[index];
        final formattedDateTime = _formatDateTime(booking.dateTime);
        final isUpcoming = booking.dateTime.isAfter(DateTime.now());
        final statusColor = _getStatusColor(booking.status);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: booking.status == 'cancelled'
                  ? Colors.red.withAlpha(77)
                  : isUpcoming
                      ? primaryColor.withAlpha(77)
                      : Colors.grey.withAlpha(77),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () => _showBookingDetails(booking),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildLocationIcon(booking.location, booking.status, isUpcoming),
                      const SizedBox(width: 16),
                      _buildBookingDetails(booking, formattedDateTime),
                      if (booking.status != 'cancelled' && booking.status != 'completed' && isUpcoming)
                        IconButton(
                          icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                          onPressed: () => _deleteBooking(booking),
                          tooltip: 'Cancel Booking',
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  
                  // Status banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(booking.status),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Build the location icon widget
  Widget _buildLocationIcon(String location, String status, bool isUpcoming) {
    final Color iconColor = status == 'cancelled'
        ? Colors.red
        : status == 'completed'
            ? Colors.blue
            : isUpcoming 
                ? primaryColor 
                : Colors.grey;
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: iconColor.withAlpha(26),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        _getIconForLocation(location),
        color: iconColor,
        size: 30,
      ),
    );
  }

  // Build the booking details widget
  Widget _buildBookingDetails(Booking booking, String formattedDateTime) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${booking.location} Campus',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: booking.status == 'cancelled'
                  ? Colors.red
                  : booking.status == 'completed'
                      ? Colors.blue
                      : primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                booking.roomType.icon,
                size: 16,
                color: booking.status == 'cancelled' ? Colors.grey : primaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                booking.roomType.displayName,
                style: TextStyle(
                  fontSize: 14,
                  color: booking.status == 'cancelled' ? Colors.grey : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            formattedDateTime,
            style: TextStyle(
              fontSize: 14,
              color: booking.status == 'cancelled' ? Colors.grey : Colors.black87,
            ),
          ),
          // Add duration info
          if (booking.duration > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Duration: ${booking.duration} minutes',
              style: TextStyle(
                fontSize: 14,
                color: booking.status == 'cancelled' ? Colors.grey : Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }
}