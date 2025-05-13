// lib/booking_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_ucs_app/models/room_model.dart';
import 'package:logging/logging.dart';

/// Represents a room booking in the system
class Booking {
  final String id;
  final String location;
  final DateTime dateTime;
  final String userId;
  final String userEmail; // Add this field
  final String userName;  // Add this field
  final RoomType roomType;
  final List<RoomFeature> features;
  final String? roomId;
  final int duration; // Duration in minutes
  final String? notes;
  final String status; // "pending", "confirmed", "cancelled", "completed"

  Booking({
    String? id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.location,
    required this.dateTime,
    required this.roomType,
    required this.features,
    this.roomId,
    this.duration = 60, // Default 60 minutes
    this.notes,
    String? status,
  }) : 
    id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    status = status ?? 'pending';

  // Get the end time of the booking
  DateTime get endTime => dateTime.add(Duration(minutes: duration));
  
  // Check if the booking is in the future
  bool get isUpcoming => dateTime.isAfter(DateTime.now());
  
  // Check if the booking is active (not cancelled)
  bool get isActive => status != 'cancelled';

  // Convert to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'location': location,
      'dateTime': dateTime,
      'roomType': _roomTypeToString(roomType),
      'features': features.map((f) => _featureToString(f)).toList(),
      'roomId': roomId,
      'duration': duration,
      'notes': notes,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Create from a map from Firestore
  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'],
      userId: map['userId'],
      userEmail: map['userEmail'] ?? 'No Email',
      userName: map['userName'] ?? 'Unknown User',
      location: map['location'],
      dateTime: map['dateTime'] is Timestamp 
          ? (map['dateTime'] as Timestamp).toDate() 
          : DateTime.parse(map['dateTime'].toString()),
      roomType: _stringToRoomType(map['roomType']),
      features:
          (map['features'] as List?)?.map((f) => _stringToFeature(f)).toList() ??
              [],
      roomId: map['roomId'],
      duration: map['duration'] ?? 60,
      notes: map['notes'],
      status: map['status'] ?? 'pending',
    );
  }

  // Helper methods for conversion between string and enum types
  static String _roomTypeToString(RoomType type) {
    switch (type) {
      case RoomType.quietRoom:
        return 'quiet';
      case RoomType.conferenceRoom:
        return 'conference';
      case RoomType.studyRoom:
        return 'study';
    }
  }

  static RoomType _stringToRoomType(String type) {
    switch (type) {
      case 'quiet':
        return RoomType.quietRoom;
      case 'conference':
        return RoomType.conferenceRoom;
      case 'study':
        return RoomType.studyRoom;
      default:
        return RoomType.studyRoom;
    }
  }

  static String _featureToString(RoomFeature feature) {
    switch (feature) {
      case RoomFeature.projector:
        return 'projector';
      case RoomFeature.whiteboard:
        return 'whiteboard';
      case RoomFeature.computer:
        return 'computer';
      case RoomFeature.printer:
        return 'printer';
      case RoomFeature.wifi:
        return 'wifi';
      case RoomFeature.accessible:
        return 'accessible';
    }
  }

  static RoomFeature _stringToFeature(String feature) {
    switch (feature) {
      case 'projector':
        return RoomFeature.projector;
      case 'whiteboard':
        return RoomFeature.whiteboard;
      case 'computer':
        return RoomFeature.computer;
      case 'printer':
        return RoomFeature.printer;
      case 'wifi':
        return RoomFeature.wifi;
      case 'accessible':
        return RoomFeature.accessible;
      default:
        return RoomFeature.whiteboard;
    }
  }
}

/// Service for managing bookings in the Firebase backend
class BookingService {
  // Singleton pattern
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  // Logger for debugging
  final _logger = Logger('BookingService');
  
  // Firebase Firestore reference
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'bookings';

  // Add a new booking to Firestore
  Future<bool> addBooking(Booking booking) async {
    try {
      await _firestore.collection(_collection).doc(booking.id).set(booking.toMap());
      
      _logger.info('Added booking: ${booking.id} in ${booking.location}');
      return true;
    } catch (e) {
      _logger.severe('Error adding booking: $e');
      return false;
    }
  }

  // Get all bookings from Firestore
  Future<List<Booking>> getAllBookings() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection(_collection).get();
      
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (!data.containsKey('id')) {
          data['id'] = doc.id;
        }
        return Booking.fromMap(data);
      }).toList();
    } catch (e) {
      _logger.warning('Error getting bookings: $e');
      // Return empty list if there's an error
      return [];
    }
  }

  // Get bookings for a specific user
  Future<List<Booking>> getUserBookings(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();
      
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (!data.containsKey('id')) {
          data['id'] = doc.id;
        }
        return Booking.fromMap(data);
      }).toList();
    } catch (e) {
      _logger.warning('Error getting user bookings: $e');
      return [];
    }
  }

  // Get bookings for a campus location
  Future<List<Booking>> getLocationBookings(String location) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('location', isEqualTo: location)
          .get();
      
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (!data.containsKey('id')) {
          data['id'] = doc.id;
        }
        return Booking.fromMap(data);
      }).toList();
    } catch (e) {
      _logger.warning('Error getting location bookings: $e');
      return [];
    }
  }

  // Delete a booking by ID
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

  // Update booking status (confirm, cancel, complete)
  Future<bool> updateBookingStatus(String bookingId, String status) async {
    try {
      await _firestore.collection(_collection).doc(bookingId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _logger.info('Updated booking status: $bookingId to $status');
      return true;
    } catch (e) {
      _logger.warning('Error updating booking status: $e');
      return false;
    }
  }

  // Check if a room is available at a specific time
  Future<bool> isRoomAvailable(String roomId, DateTime dateTime) async {
    try {
      // Get the start and end of the day
      final start = DateTime(dateTime.year, dateTime.month, dateTime.day);
      final end = start.add(const Duration(days: 1));
      
      // Query for bookings on the same day for the same room
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('roomId', isEqualTo: roomId)
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('dateTime', isLessThan: Timestamp.fromDate(end))
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();
      
      // Check if any booking overlaps with the requested time
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final DateTime bookingTime = (data['dateTime'] as Timestamp).toDate();
        final int bookingDuration = (data['duration'] as int?) ?? 60;
        
        // Calculate booking end time
        final DateTime bookingEndTime = bookingTime.add(Duration(minutes: bookingDuration));
        
        // Default duration for the requested booking (1 hour)
        final DateTime requestEndTime = dateTime.add(const Duration(hours: 1));
        
        // Check for overlap
        if ((dateTime.isAfter(bookingTime) && dateTime.isBefore(bookingEndTime)) ||
            (requestEndTime.isAfter(bookingTime) && requestEndTime.isBefore(bookingEndTime)) ||
            (dateTime.isAtSameMomentAs(bookingTime)) ||
            (requestEndTime.isAtSameMomentAs(bookingEndTime))) {
          return false; // Overlap found
        }
      }
      
      return true; // No overlap, room is available
    } catch (e) {
      _logger.warning('Error checking room availability: $e');
      return false; // In case of error, assume room is not available
    }
  }

  // Enhanced version that considers the specific duration
  Future<bool> isRoomAvailableWithDuration(String roomId, DateTime dateTime, int durationMinutes) async {
  try {
    // Calculate the end time of the proposed booking
    final DateTime endTime = dateTime.add(Duration(minutes: durationMinutes));
    
    // Get the start and end of the day for query
    final DateTime dayStart = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final DateTime dayEnd = dayStart.add(const Duration(days: 1));
    
    _logger.info('Checking availability for room $roomId on ${dateTime.toString()}');
    
    // Get bookings for this room on the same day
    final QuerySnapshot snapshot = await _firestore
      .collection(_collection)
      .where('roomId', isEqualTo: roomId)
      .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
      .where('dateTime', isLessThan: Timestamp.fromDate(dayEnd))
      .get();
    
    _logger.info('Found ${snapshot.docs.length} existing bookings');
    
    // Check for any time conflicts with existing bookings
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      // Skip cancelled bookings
      final String status = (data['status'] as String?) ?? 'pending';
      if (status.toLowerCase() == 'cancelled') {
        continue;
      }
      
      // Parse booking times
      final DateTime bookingStart = (data['dateTime'] as Timestamp).toDate();
      final int bookingDuration = (data['duration'] as int?) ?? 60;
      final DateTime bookingEnd = bookingStart.add(Duration(minutes: bookingDuration));
      
      _logger.info('Existing booking: ${bookingStart.toString()} to ${bookingEnd.toString()}');
      _logger.info('Requested booking: ${dateTime.toString()} to ${endTime.toString()}');
      
      // Check for overlap
      if ((dateTime.isBefore(bookingEnd) && endTime.isAfter(bookingStart))) {
        _logger.info('Conflict detected');
        return false; // Conflict detected
      }
    }
    
    _logger.info('No conflicts found, room is available');
    return true; // No conflicts found
  } catch (e) {
    _logger.warning('Error checking room availability: $e');
    return true; // Default to available on error for better user experience
  }
}

  // Get available time slots for a specific day
  Future<List<DateTime>> getAvailableTimeSlots(String roomId, DateTime date, int slotDuration) async {
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
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();
      
      final List<Booking> existingBookings = snapshot.docs
          .map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            if (!data.containsKey('id')) {
              data['id'] = doc.id;
            }
            return Booking.fromMap(data);
          })
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
  
  // Get bookings for a specific date range
  Future<List<Booking>> getBookingsInDateRange(DateTime start, DateTime end) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('dateTime', isLessThan: Timestamp.fromDate(end))
          .get();
      
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (!data.containsKey('id')) {
          data['id'] = doc.id;
        }
        return Booking.fromMap(data);
      }).toList();
    } catch (e) {
      _logger.warning('Error getting bookings in date range: $e');
      return [];
    }
  }
}

// Helper class for keeping track of the current user
class CurrentUser {
  static String? userId = null;
  static String? email;
  static bool isAdmin = false;
  
  static void login(String userEmail, String userUid, {bool admin = false}) {
    email = userEmail;
    userId = userUid;
    isAdmin = admin;
  }
  
  static void logout() {
    userId = null;
    email = null;
    isAdmin = false;
  }
}