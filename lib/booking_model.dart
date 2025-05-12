// lib/booking_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ucs_app/models/room_model.dart';
import 'package:logging/logging.dart';

class Booking {
  final String id; // Added ID field
  final String location;
  final DateTime dateTime;
  final String userId;
  final RoomType roomType;
  final List<RoomFeature> features;
  final String? roomId;
  final int duration; // Duration in minutes

  Booking({
    String? id, // Made ID optional for backward compatibility
    required this.location,
    required this.dateTime,
    required this.userId,
    required this.roomType,
    required this.features,
    this.roomId,
    this.duration = 60, // Default 60 minutes
  }) : this.id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  // Convert to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'location': location,
      'dateTime': dateTime,
      'userId': userId,
      'roomType': _roomTypeToString(roomType),
      'features': features.map((f) => _featureToString(f)).toList(),
      'roomId': roomId,
      'duration': duration,
    };
  }

  // Create from a map from Firestore
  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'],
      location: map['location'],
      dateTime: map['dateTime'] is Timestamp 
          ? (map['dateTime'] as Timestamp).toDate() 
          : DateTime.parse(map['dateTime'].toString()),
      userId: map['userId'],
      roomType: _stringToRoomType(map['roomType']),
      features:
          (map['features'] as List?)?.map((f) => _stringToFeature(f)).toList() ??
              [],
      roomId: map['roomId'],
      duration: map['duration'] ?? 60,
    );
  }

  // Helper methods for conversion
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
        return RoomType.quietRoom;
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
      await _firestore.collection(_collection).doc(booking.id).set({
        'id': booking.id,
        'location': booking.location,
        'dateTime': booking.dateTime,
        'userId': booking.userId,
        'roomType': Booking._roomTypeToString(booking.roomType),
        'features': booking.features.map((f) => Booking._featureToString(f)).toList(),
        'roomId': booking.roomId,
        'duration': booking.duration,
      });
      
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
        return Booking.fromMap(data);
      }).toList();
    } catch (e) {
      _logger.warning('Error getting user bookings: $e');
      return [];
    }
  }

  // Delete a booking by matching criteria
  Future<bool> deleteBooking(String location, DateTime dateTime, RoomType roomType) async {
    try {
      // Convert the room type to string for querying
      String roomTypeStr = Booking._roomTypeToString(roomType);
      
      // Query bookings matching the criteria
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('location', isEqualTo: location)
          .where('roomType', isEqualTo: roomTypeStr)
          .get();
      
      // Find the booking with matching date
      String? docIdToDelete;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final DateTime bookingDate = (data['dateTime'] as Timestamp).toDate();
        
        // Check if the dates are the same (ignore time)
        if (bookingDate.year == dateTime.year && 
            bookingDate.month == dateTime.month && 
            bookingDate.day == dateTime.day) {
          docIdToDelete = doc.id;
          break;
        }
      }
      
      // Delete the booking if found
      if (docIdToDelete != null) {
        await _firestore.collection(_collection).doc(docIdToDelete).delete();
        _logger.info('Deleted booking: $docIdToDelete');
        return true;
      } else {
        _logger.warning('No matching booking found for deletion');
        return false;
      }
    } catch (e) {
      _logger.severe('Error deleting booking: $e');
      return false;
    }
  }

  // Get room bookings by room ID
  Future<List<Booking>> getRoomBookings(String roomId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('roomId', isEqualTo: roomId)
          .get();
      
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Booking.fromMap(data);
      }).toList();
    } catch (e) {
      _logger.warning('Error getting room bookings: $e');
      return [];
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
          .where('dateTime', isGreaterThanOrEqualTo: start)
          .where('dateTime', isLessThan: end)
          .get();
      
      // Check if any booking overlaps with the requested time
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final DateTime bookingTime = (data['dateTime'] as Timestamp).toDate();
        final int bookingDuration = (data['duration'] as int?) ?? 60;
        
        // Calculate booking end time
        final DateTime bookingEndTime = bookingTime.add(Duration(minutes: bookingDuration));
        
        // Check for overlap
        final DateTime requestEndTime = dateTime.add(const Duration(hours: 1));
        
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
  
  // Delete booking by ID
  Future<bool> deleteBookingById(String bookingId) async {
    try {
      await _firestore.collection(_collection).doc(bookingId).delete();
      _logger.info('Deleted booking with ID: $bookingId');
      return true;
    } catch (e) {
      _logger.severe('Error deleting booking by ID: $e');
      return false;
    }
  }
  
  // Get bookings for a specific location
  Future<List<Booking>> getLocationBookings(String location) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('location', isEqualTo: location)
          .get();
      
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Booking.fromMap(data);
      }).toList();
    } catch (e) {
      _logger.warning('Error getting location bookings: $e');
      return [];
    }
  }
  
  // Get bookings for a specific date range
  Future<List<Booking>> getBookingsInDateRange(DateTime start, DateTime end) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('dateTime', isGreaterThanOrEqualTo: start)
          .where('dateTime', isLessThan: end)
          .get();
      
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Booking.fromMap(data);
      }).toList();
    } catch (e) {
      _logger.warning('Error getting bookings in date range: $e');
      return [];
    }
  }
}

// Current user utility class
class CurrentUser {
  static String? userId =
      'user123'; // Replace with actual user ID in production
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