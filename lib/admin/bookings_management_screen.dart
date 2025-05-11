// lib/admin/bookings_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_ucs_app/constants.dart';
import 'package:flutter_ucs_app/models/room_model.dart';
import 'package:flutter_ucs_app/booking_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'location': location,
      'roomType': roomType.name,
      'dateTime': dateTime.toIso8601String(),
      'duration': duration,
      'notes': notes,
      'status': status.name,
    };
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      userId: json['userId'] as String,
      location: json['location'] as String,
      roomType: RoomType.values.firstWhere(
        (e) => e.name == json['roomType'],
        orElse: () => RoomType.studyRoom,
      ),
      dateTime: DateTime.parse(json['dateTime'] as String),
      duration: json['duration'] as int,
      notes: json['notes'] as String?,
      status: BookingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BookingStatus.pending,
      ),
    );
  }
}

class BookingService {
  List<Booking> getAllBookings() {
    // TODO: Implement actual API call to get bookings
    // This is a mock implementation
    return [
      Booking(
        id: '1',
        userId: 'user123',
        location: 'Taunton',
        roomType: RoomType.quietRoom,
        dateTime: DateTime.now().add(const Duration(days: 1)),
        duration: 60,
        notes: 'Quiet study session',
      ),
      Booking(
        id: '2',
        userId: 'user456',
        location: 'Bridgwater',
        roomType: RoomType.conferenceRoom,
        dateTime: DateTime.now().add(const Duration(days: 2)),
        duration: 120,
        notes: 'Team meeting',
      ),
    ];
  }

  void deleteBooking(String location, DateTime dateTime, RoomType roomType) {
    // TODO: Implement actual API call to delete booking
    // This is a mock implementation
    print('Deleting booking: $location, $dateTime, $roomType');
  }
}

class BookingsManagementScreen extends StatefulWidget {
  const BookingsManagementScreen({super.key});

  @override
  State<BookingsManagementScreen> createState() =>
      _BookingsManagementScreenState();
}

class _BookingsManagementScreenState extends State<BookingsManagementScreen> {
  final BookingService _bookingService = BookingService();
  List<Booking> _filteredBookings = [];
  String _searchQuery = '';
  String _filterLocation = 'All Locations';
  RoomType? _filterRoomType;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() {
    final allBookings = _bookingService.getAllBookings();
    setState(() {
      _filteredBookings = allBookings;
    });
  }

  void _applyFilters() {
    final allBookings = _bookingService.getAllBookings();

    setState(() {
      _filteredBookings = allBookings.where((booking) {
        // Apply location filter
        if (_filterLocation != 'All Locations' &&
            booking.location != _filterLocation) {
          return false;
        }

        // Apply room type filter
        if (_filterRoomType != null && booking.roomType != _filterRoomType) {
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

  void _deleteBooking(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _bookingService.deleteBooking(
                booking.location,
                booking.dateTime,
                booking.roomType,
              );
              Navigator.pop(context);
              _loadBookings();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking deleted successfully')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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

          // Filters
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by location, room type, or user...',
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
              const SizedBox(width: 16),
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
            ],
          ),

          const SizedBox(height: 24),

          // Bookings table
          Expanded(
            child: _filteredBookings.isEmpty
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
                        final isUpcoming =
                            booking.dateTime.isAfter(DateTime.now());
                        return DataRow(
                          cells: [
                            DataCell(Text(booking.userId.substring(0, 8))),
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
                                  color: isUpcoming
                                      ? Colors.green.shade100
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isUpcoming ? 'Upcoming' : 'Past',
                                  style: TextStyle(
                                    color: isUpcoming
                                        ? Colors.green.shade800
                                        : Colors.grey.shade800,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility,
                                        color: primaryColor),
                                    onPressed: () {
                                      // View booking details
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.amber),
                                    onPressed: () {
                                      // Edit booking
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteBooking(booking),
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
}
