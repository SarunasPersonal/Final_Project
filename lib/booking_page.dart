// Fixed implementation for booking_page.dart
// Focus on the room availability check logic

import 'package:flutter/material.dart';
import 'package:flutter_ucs_app/constants.dart';
import 'package:flutter_ucs_app/booking_model.dart';
import 'package:flutter_ucs_app/models/room_model.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

class RoomAvailabilityChecker {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger('RoomAvailabilityChecker');
  
  // Improved room availability check
  Future<bool> isRoomAvailable(String roomId, DateTime dateTime, int duration) async {
    try {
      // Calculate start and end times for the requested booking
      final DateTime startTime = dateTime;
      final DateTime endTime = dateTime.add(Duration(minutes: duration));
      
      // Get the start and end of the day for query
      final DateTime dayStart = DateTime(dateTime.year, dateTime.month, dateTime.day);
      final DateTime dayEnd = dayStart.add(const Duration(days: 1));
      
      _logger.info('Checking availability for room $roomId on ${dateTime.toString()}');
      
      // Get all bookings for this room on the same day
      final QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .where('roomId', isEqualTo: roomId)
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
          .where('dateTime', isLessThan: Timestamp.fromDate(dayEnd))
          .get();
      
      _logger.info('Found ${snapshot.docs.length} existing bookings for this room on this day');
      
      // If no bookings exist for this room on this day, it's available
      if (snapshot.docs.isEmpty) {
        return true;
      }
      
      // Check each booking for time conflicts
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Parse booking times
        final DateTime bookingStart = (data['dateTime'] as Timestamp).toDate();
        final int bookingDuration = (data['duration'] as int?) ?? 60;
        final DateTime bookingEnd = bookingStart.add(Duration(minutes: bookingDuration));
        
        // Check if the status is cancelled (cancelled bookings don't block new bookings)
        final String status = (data['status'] as String?) ?? 'pending';
        if (status.toLowerCase() == 'cancelled') {
          continue; // Skip cancelled bookings
        }
        
        _logger.info('Existing booking: ${bookingStart.toString()} to ${bookingEnd.toString()}');
        _logger.info('Requested booking: ${startTime.toString()} to ${endTime.toString()}');
        
        // Check for overlap
        // A conflict exists if:
        // 1. The new booking starts during an existing booking
        // 2. The new booking ends during an existing booking
        // 3. The new booking completely encompasses an existing booking
        if ((startTime.isAfter(bookingStart) && startTime.isBefore(bookingEnd)) ||
            (endTime.isAfter(bookingStart) && endTime.isBefore(bookingEnd)) ||
            (startTime.isBefore(bookingStart) && endTime.isAfter(bookingEnd)) ||
            (startTime.isAtSameMomentAs(bookingStart)) ||
            (endTime.isAtSameMomentAs(bookingEnd))) {
          
          _logger.warning('Time conflict detected with existing booking');
          return false; // Conflict detected
        }
      }
      
      // No conflicts found
      _logger.info('No conflicts found, room is available');
      return true;
    } catch (e) {
      _logger.severe('Error checking room availability: $e');
      // In case of error, assume the room is available to avoid blocking bookings
      // This can be changed to return false if you prefer to be more conservative
      return true;
    }
  }
}

// This is a partial implementation focusing on the availability check logic
// To be integrated into your existing booking_page.dart

class BookingPageFixedAvailability extends StatefulWidget {
  final String location;
  const BookingPageFixedAvailability(this.location, {super.key});

  @override
  State<BookingPageFixedAvailability> createState() => _BookingPageFixedAvailabilityState();
}

class _BookingPageFixedAvailabilityState extends State<BookingPageFixedAvailability> {
  DateTime? selectedDateTime;
  String? formattedDateTime;
  final BookingService _bookingService = BookingService();
  final RoomAvailabilityChecker _availabilityChecker = RoomAvailabilityChecker();
  bool _isLoading = false;
  bool _isLoadingRooms = true;
  bool _isRoomAvailable = true;

  // Room selection
  RoomType _selectedRoomType = RoomType.quietRoom;
  Room? _selectedRoom;
  List<Room> _availableRooms = [];

  // Booking duration
  int _duration = 60; // Default 60 minutes
  
  // Improved function to check room availability
  Future<bool> _isRoomAvailableAtSelectedTime() async {
    if (_selectedRoom == null || selectedDateTime == null) {
      return false;
    }

    // Use the improved availability checker
    return await _availabilityChecker.isRoomAvailable(
      _selectedRoom!.id, 
      selectedDateTime!,
      _duration
    );
  }
  
  // Update the date/time selection method to check room availability
  void _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: secondaryColor,
              onSurface: primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (!context.mounted || pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: secondaryColor,
              onSurface: primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (!context.mounted || pickedTime == null) return;

    final newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      selectedDateTime = newDateTime;
      formattedDateTime = _formatDateTime(newDateTime);
    });

    // Check if the room is available at the selected time
    if (_selectedRoom != null) {
      setState(() {
        _isLoading = true; // Show loading while checking availability
      });
      
      bool isAvailable = await _isRoomAvailableAtSelectedTime();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRoomAvailable = isAvailable;
        });
        
        if (!isAvailable) {
          _showSnackBar(
            'The selected room is not available at this time. Please select a different time or room.',
            color: Colors.red,
            duration: const Duration(seconds: 3),
          );
        } else {
          _showSnackBar('Selected date and time: $formattedDateTime');
        }
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    return '${dateFormat.format(dateTime)} at ${timeFormat.format(dateTime)}';
  }
  
  // Show a snackbar message
  void _showSnackBar(String message, {Color color = Colors.black, Duration? duration}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color != Colors.black ? color : null,
        duration: duration ?? const Duration(seconds: 2),
      ),
    );
  }
  
  // Debug function to display all bookings for a room
  Future<void> _debugShowAllBookings() async {
    if (_selectedRoom == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('roomId', isEqualTo: _selectedRoom!.id)
          .get();
      
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('All Bookings for ${_selectedRoom!.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Found ${snapshot.docs.length} bookings:'),
                const Divider(),
                ...snapshot.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final DateTime bookingTime = (data['dateTime'] as Timestamp).toDate();
                  final int duration = (data['duration'] as int?) ?? 60;
                  final String status = (data['status'] as String?) ?? 'pending';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Time: ${DateFormat('MM/dd/yyyy HH:mm').format(bookingTime)}\n'
                      'Duration: $duration minutes\n'
                      'Status: $status',
                      style: TextStyle(
                        color: status.toLowerCase() == 'cancelled' ? Colors.grey : null,
                      ),
                    ),
                  );
                }).toList(),
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
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error loading bookings: $e', color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    // This is just a sample build method to make the code compile
    // The actual implementation would integrate with your existing UI
    return Scaffold(
      appBar: AppBar(
        title: Text('Book at ${widget.location}'),
      ),
      body: Center(
        child: Text('Fixed room availability checker implementation'),
      ),
    );
  }
}