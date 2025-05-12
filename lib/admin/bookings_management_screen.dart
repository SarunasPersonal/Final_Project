import 'package:flutter/material.dart';
import 'package:flutter_ucs_app/constants.dart';
import 'package:flutter_ucs_app/models/room_model.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

enum BookingStatus {
  pending,
  confirmed,
  cancelled,
  completed;

  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
    }
  }

  Color get color {
    switch (this) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.completed:
        return Colors.blue;
    }
  }

  static BookingStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'completed':
        return BookingStatus.completed;
      default:
        return BookingStatus.pending;
    }
  }
}

class Booking {
  final String id;
  final String userId;
  final String location;
  final RoomType roomType;
  final DateTime dateTime;
  final int duration;
  final String? notes;
  final BookingStatus status;

  Booking({
    required this.id,
    required this.userId,
    required this.location,
    required this.roomType,
    required this.dateTime,
    required this.duration,
    this.notes,
    this.status = BookingStatus.pending,
  });

  // Get end time
  DateTime get endTime => dateTime.add(Duration(minutes: duration));
  
  // Check if booking is upcoming
  bool get isUpcoming => dateTime.isAfter(DateTime.now());

  // Create a Booking from a Firestore document
  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    return Booking(
      id: doc.id,
      userId: data['userId'] ?? 'Unknown',
      location: data['location'] ?? 'Unknown',
      roomType: _parseRoomType(data['roomType']),
      dateTime: _parseDateTime(data['dateTime']),
      duration: data['duration'] ?? 60,
      notes: data['notes'],
      status: _parseStatus(data['status']),
    );
  }

  // Helper method to parse room type from string
  static RoomType _parseRoomType(String? type) {
    if (type == null) return RoomType.studyRoom;
    
    switch (type) {
      case 'quietRoom': return RoomType.quietRoom;
      case 'conferenceRoom': return RoomType.conferenceRoom;
      case 'studyRoom': return RoomType.studyRoom;
      default: return RoomType.studyRoom;
    }
  }

  // Helper method to parse dateTime from Firestore
  static DateTime _parseDateTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  // Helper method to parse status from string
  static BookingStatus _parseStatus(String? status) {
    if (status == null) return BookingStatus.pending;
    return BookingStatus.fromString(status);
  }

  // Convert booking to a map for Firestore
  Map<String, dynamic> toFirestore() {
    String roomTypeString;
    switch (roomType) {
      case RoomType.quietRoom:
        roomTypeString = 'quietRoom';
        break;
      case RoomType.conferenceRoom:
        roomTypeString = 'conferenceRoom';
        break;
      case RoomType.studyRoom:
        roomTypeString = 'studyRoom';
        break;
    }

    return {
      'userId': userId,
      'location': location,
      'roomType': roomTypeString,
      'dateTime': Timestamp.fromDate(dateTime),
      'duration': duration,
      'notes': notes,
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger('BookingService');
  final String _collectionName = 'bookings';

  // Get all bookings from Firestore
  Future<List<Booking>> getAllBookings() async {
    try {
      // Check if collection exists and create sample data if not
      bool collectionExists = await _checkCollectionExists();
      if (!collectionExists) {
        await _createSampleBookings();
      }
      
      // Get bookings from Firestore, ordered by date/time descending
      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('dateTime', descending: true)
          .get();
      
      // Convert documents to Booking objects
      final bookings = snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
      
      if (bookings.isEmpty && !(await _checkCollectionExists())) {
        await _createSampleBookings();
        
        // Try fetching again
        final retrySnapshot = await _firestore
            .collection(_collectionName)
            .orderBy('dateTime', descending: true)
            .get();
            
        return retrySnapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
      }
      
      return bookings;
    } catch (e) {
      _logger.warning('Error fetching bookings: $e');
      
      // If Firestore query fails, return mock data
      bool collectionExists = await _checkCollectionExists();
      if (!collectionExists) {
        return _getMockBookings();
      } else {
        // Just return an empty list instead of mock data if the collection exists but query failed
        return [];
      }
    }
  }

  // Check if the bookings collection exists
  Future<bool> _checkCollectionExists() async {
    try {
      final snapshot = await _firestore.collection(_collectionName).limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      _logger.warning('Error checking if collection exists: $e');
      return false;
    }
  }

  // Delete a booking from Firestore
  Future<bool> deleteBooking(String bookingId) async {
    try {
      await _firestore.collection(_collectionName).doc(bookingId).delete();
      _logger.info('Deleted booking: $bookingId');
      return true;
    } catch (e) {
      _logger.severe('Error deleting booking: $e');
      return false;
    }
  }

  // Update booking status
  Future<bool> updateBookingStatus(String bookingId, BookingStatus status) async {
    try {
      await _firestore.collection(_collectionName).doc(bookingId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _logger.info('Updated booking status: $bookingId to ${status.name}');
      return true;
    } catch (e) {
      _logger.warning('Error updating booking status: $e');
      return false;
    }
  }
  
  // Create sample bookings in Firestore for testing
  Future<void> _createSampleBookings() async {
    try {
      _logger.info('Creating sample bookings...');
      
      // Sample room data
      final rooms = [
        {'id': 'taunton-quiet-1', 'name': 'Quiet Study Room 1', 'campus': 'Taunton', 'type': RoomType.quietRoom},
        {'id': 'bridgwater-conference-1', 'name': 'Conference Room A', 'campus': 'Bridgwater', 'type': RoomType.conferenceRoom},
        {'id': 'cannington-study-1', 'name': 'Study Room 1', 'campus': 'Cannington', 'type': RoomType.studyRoom},
      ];
      
      // Sample users
      final users = [
        {'id': 'user1', 'email': 'john.smith@example.com'},
        {'id': 'user2', 'email': 'jane.doe@example.com'},
        {'id': 'user3', 'email': 'mike.wilson@example.com'},
      ];
      
      // Get sample bookings
      final sampleBookings = _getMockBookings();
      
      // Add to Firestore
      final batch = _firestore.batch();
      
      for (int i = 0; i < sampleBookings.length; i++) {
        final booking = sampleBookings[i];
        final docRef = _firestore.collection(_collectionName).doc('sample-booking-${i+1}');
        
        // Create Firestore data
        final Map<String, dynamic> bookingData = {
          'userId': booking.userId,
          'location': booking.location,
          'roomType': booking.roomType == RoomType.quietRoom 
              ? 'quietRoom' 
              : booking.roomType == RoomType.conferenceRoom 
                  ? 'conferenceRoom' 
                  : 'studyRoom',
          'dateTime': Timestamp.fromDate(booking.dateTime),
          'duration': booking.duration,
          'notes': booking.notes,
          'status': booking.status.name,
          'createdAt': FieldValue.serverTimestamp(),
        };
        
        batch.set(docRef, bookingData);
      }
      
      await batch.commit();
      _logger.info('Sample bookings created successfully');
    } catch (e) {
      _logger.warning('Error creating sample bookings: $e');
    }
  }
  
  // Get mock bookings for development
  List<Booking> _getMockBookings() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return [
      Booking(
        id: '1',
        userId: 'john.smith@example.com',
        location: 'Taunton',
        roomType: RoomType.quietRoom,
        dateTime: today.add(const Duration(days: 1, hours: 10)),
        duration: 60,
        notes: 'Quiet study session',
      ),
      Booking(
        id: '2',
        userId: 'jane.doe@example.com',
        location: 'Bridgwater',
        roomType: RoomType.conferenceRoom,
        dateTime: today.add(const Duration(days: 2, hours: 14)),
        duration: 120,
        notes: 'Team meeting',
        status: BookingStatus.confirmed,
      ),
      Booking(
        id: '3',
        userId: 'mike.wilson@example.com',
        location: 'Cannington',
        roomType: RoomType.studyRoom,
        dateTime: today.subtract(const Duration(days: 1, hours: 9)),
        duration: 90,
        status: BookingStatus.completed,
      ),
      Booking(
        id: '4',
        userId: 'sarah.johnson@example.com',
        location: 'Bridgwater',
        roomType: RoomType.quietRoom,
        dateTime: today.add(const Duration(days: 3, hours: 15, minutes: 30)),
        duration: 60,
        status: BookingStatus.pending,
      ),
      Booking(
        id: '5',
        userId: 'david.brown@example.com',
        location: 'Taunton',
        roomType: RoomType.conferenceRoom,
        dateTime: today.add(const Duration(days: 1, hours: 13)),
        duration: 180,
        notes: 'Presentation preparation',
        status: BookingStatus.cancelled,
      ),
    ];
  }
}

class BookingsManagementScreen extends StatefulWidget {
  const BookingsManagementScreen({super.key});

  @override
  State<BookingsManagementScreen> createState() => _BookingsManagementScreenState();
}

class _BookingsManagementScreenState extends State<BookingsManagementScreen> {
  final BookingService _bookingService = BookingService();
  final Logger _logger = Logger('BookingsManagementScreen');
  List<Booking> _bookings = [];
  List<Booking> _filteredBookings = [];
  String _searchQuery = '';
  String _filterLocation = 'All Locations';
  RoomType? _filterRoomType;
  BookingStatus? _filterStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      _logger.info('Loading bookings...');
      final allBookings = await _bookingService.getAllBookings();
      _logger.info('Loaded ${allBookings.length} bookings');
      
      if (!mounted) return;
      
      setState(() {
        _bookings = allBookings;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      _logger.warning('Error loading bookings: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading bookings: $e')),
      );
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredBookings = _bookings.where((booking) {
        // Apply location filter
        if (_filterLocation != 'All Locations' &&
            booking.location != _filterLocation) {
          return false;
        }

        // Apply room type filter
        if (_filterRoomType != null && booking.roomType != _filterRoomType) {
          return false;
        }
        
        // Apply status filter
        if (_filterStatus != null && booking.status != _filterStatus) {
          return false;
        }

        // Apply search query (check if query exists in location, room type, or user ID)
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          return booking.location.toLowerCase().contains(query) ||
              booking.roomType.displayName.toLowerCase().contains(query) ||
              booking.userId.toLowerCase().contains(query);
        }

        return true;
      }).toList();
    });
  }

  Future<void> _deleteBooking(Booking booking) async {
    final bool isConfirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
    
    if (!isConfirmed || !mounted) return;
              
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await _bookingService.deleteBooking(booking.id);
      
      if (!mounted) return;
      
      if (success) {
        await _loadBookings();  // Reload bookings after deletion
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking deleted successfully')),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete booking')),
        );
      }
    } catch (e) {
      _logger.warning('Error deleting booking: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting booking: $e')),
      );
    }
  }
  
  Future<void> _updateBookingStatus(Booking booking, BookingStatus newStatus) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await _bookingService.updateBookingStatus(booking.id, newStatus);
      
      if (!mounted) return;
      
      if (success) {
        await _loadBookings();  // Reload bookings after update
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking status updated to ${newStatus.displayName}')),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update booking status')),
        );
      }
    } catch (e) {
      _logger.warning('Error updating booking status: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating booking status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
          const SizedBox(height: 24),

          // Filters and controls
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.start,
            children: [
              // Search field
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by location, room, or user...',
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
              
              // Location filter
              DropdownButton<String>(
                value: _filterLocation,
                items: [
                  'All Locations',
                  'Taunton',
                  'Bridgwater',
                  'Cannington',
                ].map((location) {
                  return DropdownMenuItem<String>(
                    value: location,
                    child: Text(location),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _filterLocation = value!;
                  });
                  _applyFilters();
                },
              ),
              
              // Room type filter
              DropdownButton<RoomType?>(
                value: _filterRoomType,
                hint: const Text('Room Type'),
                items: [
                  const DropdownMenuItem<RoomType?>(
                    value: null,
                    child: Text('All Room Types'),
                  ),
                  ...RoomType.values.map((type) {
                    return DropdownMenuItem<RoomType?>(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _filterRoomType = value;
                  });
                  _applyFilters();
                },
              ),
              
              // Status filter
              DropdownButton<BookingStatus?>(
                value: _filterStatus,
                hint: const Text('Status'),
                items: [
                  const DropdownMenuItem<BookingStatus?>(
                    value: null,
                    child: Text('All Statuses'),
                  ),
                  ...BookingStatus.values.map((status) {
                    return DropdownMenuItem<BookingStatus?>(
                      value: status,
                      child: Text(status.displayName),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _filterStatus = value;
                  });
                  _applyFilters();
                },
              ),
              
              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: _loadBookings,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Bookings table
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: primaryColor))
              : _filteredBookings.isEmpty
                ? const Center(child: Text('No bookings found'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Location')),
                        DataColumn(label: Text('Room Type')),
                        DataColumn(label: Text('Date & Time')),
                        DataColumn(label: Text('User')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: _filteredBookings.map((booking) {
                        final isUpcoming = booking.dateTime.isAfter(DateTime.now());
                        return DataRow(
                          cells: [
                            DataCell(Text(booking.id.length > 8 
                                ? booking.id.substring(0, 8) + '...' 
                                : booking.id)),
                            DataCell(Text(booking.location)),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(booking.roomType.icon, size: 16),
                                  const SizedBox(width: 4),
                                  Text(booking.roomType.displayName),
                                ],
                              ),
                            ),
                            DataCell(Text(DateFormat('MMM d, y HH:mm')
                                .format(booking.dateTime))),
                            DataCell(Text(booking.userId)),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: booking.status.color.withAlpha(50),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  booking.status.displayName,
                                  style: TextStyle(
                                    color: booking.status.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  // View details button
                                  IconButton(
                                    icon: const Icon(Icons.visibility,
                                        color: primaryColor),
                                    onPressed: () => _showBookingDetails(booking),
                                    tooltip: 'View Details',
                                  ),
                                  
                                  // Status update menu
                                  if (isUpcoming)
                                    PopupMenuButton<BookingStatus>(
                                      tooltip: 'Update Status',
                                      icon: const Icon(Icons.edit_note, color: Colors.amber),
                                      onSelected: (BookingStatus status) {
                                        _updateBookingStatus(booking, status);
                                      },
                                      itemBuilder: (BuildContext context) {
                                        return [
                                          const PopupMenuItem<BookingStatus>(
                                            value: BookingStatus.confirmed,
                                            child: Text('Confirm'),
                                          ),
                                          const PopupMenuItem<BookingStatus>(
                                            value: BookingStatus.cancelled,
                                            child: Text('Cancel'),
                                          ),
                                          const PopupMenuItem<BookingStatus>(
                                            value: BookingStatus.pending,
                                            child: Text('Set to Pending'),
                                          ),
                                        ];
                                      },
                                    ),
                                  
                                  // Delete button
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteBooking(booking),
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
  
  void _showBookingDetails(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Booking ID', booking.id),
              _buildDetailRow('Location', booking.location),
              _buildDetailRow('Room Type', booking.roomType.displayName),
              _buildDetailRow('Date & Time', DateFormat('MMMM d, y HH:mm').format(booking.dateTime)),
              _buildDetailRow('Duration', '${booking.duration} minutes'),
              _buildDetailRow('End Time', DateFormat('MMMM d, y HH:mm').format(booking.endTime)),
              _buildDetailRow('Status', booking.status.displayName),
              _buildDetailRow('User ID', booking.userId),
              if (booking.notes != null && booking.notes!.isNotEmpty)
                _buildDetailRow('Notes', booking.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
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
}