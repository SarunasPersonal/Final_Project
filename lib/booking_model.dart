import 'package:flutter/material.dart';
// Importing the Flutter Material package for UI components and icons.
import 'package:flutter_ucs_app/models/room_model.dart';

class Booking {
  final String location;
  // The location of the booking.
  final DateTime dateTime;
  // The date and time of the booking.
  final String userId;
  // The ID of the user who made the booking.
  final RoomType roomType;
  // The type of room being booked.
  final List<RoomFeature> features;
  // A list of additional features requested for the room.
  final String? roomId;
  // The specific room ID for this booking (optional for backward compatibility)

  Booking({
    required this.location,
    // Constructor parameter for location (required).
    required this.dateTime,
    // Constructor parameter for dateTime (required).
    required this.userId,
    // Constructor parameter for userId (required).
    required this.roomType,
    // Constructor parameter for roomType (required).
    required this.features,
    // Constructor parameter for features (required).
    this.roomId,
    // Constructor parameter for roomId (optional).
  });

  // Convert to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'location': location,
      'dateTime': dateTime,
      'userId': userId,
      'roomType': roomTypeToString(roomType),
      'features': features.map((f) => featureToString(f)).toList(),
      'roomId': roomId,
    };
  }

  // Create from a map from Firestore
  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      location: map['location'],
      dateTime: map['dateTime'].toDate(),
      userId: map['userId'],
      roomType: stringToRoomType(map['roomType']),
      features:
          (map['features'] as List?)?.map((f) => stringToFeature(f)).toList() ??
              [],
      roomId: map['roomId'],
    );
  }

  // Helper methods for conversion
  static String roomTypeToString(RoomType type) {
    switch (type) {
      case RoomType.quietRoom:
        return 'quiet';
      case RoomType.conferenceRoom:
        return 'conference';
      case RoomType.studyRoom:
        return 'study';
    }
  }

  static RoomType stringToRoomType(String type) {
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

  static String featureToString(RoomFeature feature) {
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

  static RoomFeature stringToFeature(String feature) {
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

// Simple in-memory storage for bookings
class BookingService {
  // Singleton pattern
  static final BookingService _instance = BookingService._internal();
  // A private static instance of the BookingService class.
  factory BookingService() => _instance;
  // Factory constructor to return the singleton instance.
  BookingService._internal();
  // Private named constructor for internal use.

  final List<Booking> _bookings = [];
  // A private list to store all bookings.

  // Add a new booking
  void addBooking(Booking booking) {
    _bookings.add(booking);
    // Adds a new booking to the list.
  }

  // Get all bookings
  List<Booking> getAllBookings() {
    return List.from(_bookings);
    // Returns a copy of the list of all bookings.
  }

  // Get bookings for a specific user
  List<Booking> getUserBookings(String userId) {
    return _bookings.where((booking) => booking.userId == userId).toList();
    // Filters and returns bookings that match the given userId.
  }

  // Delete a booking by matching date and location
  void deleteBooking(String location, DateTime dateTime, RoomType roomType) {
    _bookings.removeWhere((booking) =>
        booking.location == location &&
        booking.dateTime == dateTime &&
        booking.roomType == roomType);
    // Removes a booking from the list if it matches the given location, dateTime, and roomType.
  }

  // Get room bookings by room ID
  List<Booking> getRoomBookings(String roomId) {
    return _bookings.where((booking) => booking.roomId == roomId).toList();
    // Filters and returns bookings that match the given roomId.
  }

  // Check if a room is available at a specific time
  bool isRoomAvailable(String roomId, DateTime dateTime) {
    return !_bookings.any((booking) =>
        booking.roomId == roomId &&
        booking.dateTime.year == dateTime.year &&
        booking.dateTime.month == dateTime.month &&
        booking.dateTime.day == dateTime.day &&
        booking.dateTime.hour == dateTime.hour);
  }
}

// Mock current user for development
class CurrentUser {
  static String? userId =
      'user123'; // Replace with actual user ID in production
}
