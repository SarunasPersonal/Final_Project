import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ucs_app/models/room_model.dart';
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
}

class Booking {
  final String id;
  final String userId;
  final String userEmail;
  final String location;
  final String roomId;
  final String roomName;
  final RoomType roomType;
  final DateTime dateTime;
  final int duration; // in minutes
  final String? notes;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Booking({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.location,
    required this.roomId,
    required this.roomName,
    required this.roomType,
    required this.dateTime,
    required this.duration,
    this.notes,
    this.status = BookingStatus.pending,
    required this.createdAt,
    this.updatedAt,
  });

  // Create a copy of this Booking with updated fields
  Booking copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? location,
    String? roomId,
    String? roomName,
    RoomType? roomType,
    DateTime? dateTime,
    int? duration,
    String? notes,
    BookingStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      location: location ?? this.location,
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      roomType: roomType ?? this.roomType,
      dateTime: dateTime ?? this.dateTime,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get end time based on start time and duration
  DateTime get endTime => dateTime.add(Duration(minutes: duration));

  // Check if booking is in the future
  bool get isUpcoming => dateTime.isAfter(DateTime.now());

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'location': location,
      'roomId': roomId,
      'roomName': roomName,
      'roomType': roomType.name,
      'dateTime': Timestamp.fromDate(dateTime),
      'duration': duration,
      'notes': notes,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create Booking from Firestore document
  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      location: data['location'] ?? '',
      roomId: data['roomId'] ?? '',
      roomName: data['roomName'] ?? '',
      roomType: _parseRoomType(data['roomType']),
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      duration: data['duration'] ?? 60,
      notes: data['notes'],
      status: _parseBookingStatus(data['status']),
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  // Helper methods for parsing enums
  static RoomType _parseRoomType(String? typeStr) {
    if (typeStr == null) return RoomType.studyRoom;
    try {
      return RoomType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => RoomType.studyRoom,
      );
    } catch (e) {
      return RoomType.studyRoom;
    }
  }

  static BookingStatus _parseBookingStatus(String? statusStr) {
    if (statusStr == null) return BookingStatus.pending;
    try {
      return BookingStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => BookingStatus.pending,
      );
    } catch (e) {
      return BookingStatus.pending;
    }
  }
}

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger('BookingService');
  final String _collection = 'bookings';

  // Singleton pattern
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  // Create a new booking
  Future<Booking?> createBooking(Booking booking) async {
    try {
      // Check if the room is available at the requested time
      bool isAvailable = await isRoomAvailableAtTime(
        booking.roomId, 
        booking.dateTime, 
        booking.duration
      );

      if (!isAvailable) {
        _logger.warning(
          'Room ${booking.roomId} is not available at ${booking.dateTime}'
        );
        return null;
      }

      // Add booking to Firestore
      DocumentReference docRef = await _firestore.collection(_collection).add(booking.toMap());
      
      // Get the new document with ID
      DocumentSnapshot doc = await docRef.get();
      
      _logger.info('Created booking: ${doc.id}');
      return Booking.fromFirestore(doc);
    } catch (e) {
      _logger.severe('Error creating booking: $e');
      return null;
    }
  }

  // Update an existing booking
  Future<Booking?> updateBooking(Booking booking) async {
    try {
      // Check if room is available at new time (if time changed)
      final existingBooking = await getBookingById(booking.id);
      
      if (existingBooking != null && 
          (existingBooking.dateTime != booking.dateTime || 
           existingBooking.duration != booking.duration) &&
          existingBooking.roomId == booking.roomId) {
        
        bool isAvailable = await isRoomAvailableAtTime(
          booking.roomId, 
          booking.dateTime, 
          booking.duration,
          excludeBookingId: booking.id
        );

        if (!isAvailable) {
          _logger.warning(
            'Room ${booking.roomId} is not available at the new time'
          );
          return null;
        }
      }

      // Update booking in Firestore
      final updatedBooking = booking.copyWith(
        updatedAt: DateTime.now(),
      );
      
      await _firestore
          .collection(_collection)
          .doc(booking.id)
          .update(updatedBooking.toMap());
      
      _logger.info('Updated booking: ${booking.id}');
      return updatedBooking;
    } catch (e) {
      _logger.severe('Error updating booking: $e');
      return null;
    }
  }

  // Delete a booking
  Future<bool> deleteBooking(String bookingId) async {
    try {
      await _firestore.collection(_collection).doc(bookingId).delete();
      _logger.info('Deleted booking: $bookingId');
      return true;
    } catch (e) {
      _logger.severe('Error deleting booking: $e');
      return false;
    }
  }

  // Change booking status
  Future<Booking?> updateBookingStatus(String bookingId, BookingStatus status) async {
    try {
      await _firestore.collection(_collection).doc(bookingId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Get updated booking
      final updatedDoc = await _firestore.collection(_collection).doc(bookingId).get();
      _logger.info('Updated booking status: $bookingId to ${status.name}');
      
      return Booking.fromFirestore(updatedDoc);
    } catch (e) {
      _logger.severe('Error updating booking status: $e');
      return null;
    }
  }

  // Get all bookings
  Future<List<Booking>> getAllBookings() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .orderBy('dateTime', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
    } catch (e) {
      _logger.warning('Error getting all bookings: $e');
      return [];
    }
  }

  // Get bookings by user ID
  Future<List<Booking>> getBookingsByUserId(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('dateTime', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
    } catch (e) {
      _logger.warning('Error getting bookings for user $userId: $e');
      return [];
    }
  }

  // Get bookings for a specific room
  Future<List<Booking>> getBookingsByRoomId(String roomId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('roomId', isEqualTo: roomId)
          .orderBy('dateTime')
          .get();
      
      return snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
    } catch (e) {
      _logger.warning('Error getting bookings for room $roomId: $e');
      return [];
    }
  }

  // Get bookings by campus location
  Future<List<Booking>> getBookingsByLocation(String location) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('location', isEqualTo: location)
          .orderBy('dateTime', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
    } catch (e) {
      _logger.warning('Error getting bookings for location $location: $e');
      return [];
    }
  }

  // Get a specific booking by ID
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_collection)
          .doc(bookingId)
          .get();
      
      if (!doc.exists) {
        return null;
      }
      
      return Booking.fromFirestore(doc);
    } catch (e) {
      _logger.warning('Error getting booking $bookingId: $e');
      return null;
    }
  }

  // Get today's bookings
  Future<List<Booking>> getTodayBookings() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('dateTime')
          .get();
      
      return snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
    } catch (e) {
      _logger.warning('Error getting today\'s bookings: $e');
      return [];
    }
  }

  // Get bookings for a specific date range
  Future<List<Booking>> getBookingsForDateRange(DateTime start, DateTime end) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('dateTime')
          .get();
      
      return snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
    } catch (e) {
      _logger.warning('Error getting bookings for date range: $e');
      return [];
    }
  }

  // Get upcoming bookings (from now onwards)
  Future<List<Booking>> getUpcomingBookings() async {
    try {
      final now = DateTime.now();
      
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('dateTime')
          .get();
      
      return snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
    } catch (e) {
      _logger.warning('Error getting upcoming bookings: $e');
      return [];
    }
  }

  // Get past bookings (before now)
  Future<List<Booking>> getPastBookings() async {
    try {
      final now = DateTime.now();
      
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('dateTime', isLessThan: Timestamp.fromDate(now))
          .orderBy('dateTime', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
    } catch (e) {
      _logger.warning('Error getting past bookings: $e');
      return [];
    }
  }

  // Check if a room is available at a specific time
  Future<bool> isRoomAvailableAtTime(
    String roomId, 
    DateTime dateTime, 
    int duration, 
    {String? excludeBookingId}
  ) async {
    try {
      // Calculate the end time of the proposed booking
      final endTime = dateTime.add(Duration(minutes: duration));
      
      // Get all bookings for this room on the same day
      final dayStart = DateTime(dateTime.year, dateTime.month, dateTime.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('roomId', isEqualTo: roomId)
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
          .where('dateTime', isLessThan: Timestamp.fromDate(dayEnd))
          .where('status', whereIn: [
            BookingStatus.pending.name, 
            BookingStatus.confirmed.name
          ])
          .get();
      
      // Check for any conflicting bookings
      for (var doc in snapshot.docs) {
        // Skip the current booking if we're checking for an update
        if (excludeBookingId != null && doc.id == excludeBookingId) {
          continue;
        }
        
        final booking = Booking.fromFirestore(doc);
        final bookingEndTime = booking.dateTime.add(Duration(minutes: booking.duration));
        
        // Check if there's an overlap
        if (dateTime.isBefore(bookingEndTime) && endTime.isAfter(booking.dateTime)) {
          return false; // There is a conflict
        }
      }
      
      return true; // No conflicts found
    } catch (e) {
      _logger.warning('Error checking room availability: $e');
      return false; // Assume unavailable on error
    }
  }

  // Get all available time slots for a specific room on a specific day
  Future<List<DateTime>> getAvailableTimeSlots(
    String roomId, 
    DateTime date, 
    int slotDuration // in minutes
  ) async {
    try {
      // Setting operation hours (e.g., 8:00 AM to 10:00 PM)
      final startHour = 8;
      final endHour = 22;
      
      // Create day start and end timestamps
      final dayStart = DateTime(date.year, date.month, date.day, startHour);
      final dayEnd = DateTime(date.year, date.month, date.day, endHour);
      
      // Get all bookings for this room on this day
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('roomId', isEqualTo: roomId)
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
          .where('dateTime', isLessThan: Timestamp.fromDate(dayEnd))
          .where('status', whereIn: [
            BookingStatus.pending.name, 
            BookingStatus.confirmed.name
          ])
          .get();
      
      final List<Booking> existingBookings = snapshot.docs
          .map((doc) => Booking.fromFirestore(doc))
          .toList();
      
      // Generate all possible slots
      final List<DateTime> allSlots = [];
      DateTime currentSlot = dayStart;
      
      while (currentSlot.isBefore(dayEnd)) {
        allSlots.add(currentSlot);
        currentSlot = currentSlot.add(Duration(minutes: slotDuration));
      }
      
      // Filter out slots that conflict with existing bookings
      final List<DateTime> availableSlots = allSlots.where((slot) {
        final slotEnd = slot.add(Duration(minutes: slotDuration));
        
        // Check against all existing bookings
        for (var booking in existingBookings) {
          final bookingEnd = booking.dateTime.add(Duration(minutes: booking.duration));
          
          // Check if there's an overlap
          if (slot.isBefore(bookingEnd) && slotEnd.isAfter(booking.dateTime)) {
            return false; // This slot has a conflict
          }
        }
        
        return true; // No conflicts found for this slot
      }).toList();
      
      return availableSlots;
    } catch (e) {
      _logger.warning('Error getting available time slots: $e');
      return [];
    }
  }

  // Get statistics by room type
  Future<Map<RoomType, int>> getBookingStatsByRoomType() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .get();
      
      final Map<RoomType, int> stats = {};
      
      for (var doc in snapshot.docs) {
        final booking = Booking.fromFirestore(doc);
        stats[booking.roomType] = (stats[booking.roomType] ?? 0) + 1;
      }
      
      return stats;
    } catch (e) {
      _logger.warning('Error getting booking stats by room type: $e');
      return {};
    }
  }

  // Get statistics by location (campus)
  Future<Map<String, int>> getBookingStatsByLocation() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .get();
      
      final Map<String, int> stats = {};
      
      for (var doc in snapshot.docs) {
        final booking = Booking.fromFirestore(doc);
        stats[booking.location] = (stats[booking.location] ?? 0) + 1;
      }
      
      return stats;
    } catch (e) {
      _logger.warning('Error getting booking stats by location: $e');
      return {};
    }
  }

  // Get statistics by status
  Future<Map<BookingStatus, int>> getBookingStatsByStatus() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .get();
      
      final Map<BookingStatus, int> stats = {};
      
      for (var doc in snapshot.docs) {
        final booking = Booking.fromFirestore(doc);
        stats[booking.status] = (stats[booking.status] ?? 0) + 1;
      }
      
      return stats;
    } catch (e) {
      _logger.warning('Error getting booking stats by status: $e');
      return {};
    }
  }
}