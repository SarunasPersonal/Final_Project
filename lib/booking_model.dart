import 'package:flutter/material.dart'; 
// Importing the Flutter Material package for UI components and icons.

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

  Booking({
    required this.location, 
    // Constructor parameter for location (required).
    required this.dateTime, 
    // Constructor parameter for dateTime (required).
    required this.userId, 
    // Constructor parameter for userId (required).
    required this.roomType, 
    // Constructor parameter for roomType (required).
    this.features = const [], 
    // Constructor parameter for features (optional, defaults to an empty list).
  });
}

// Enum for room types
enum RoomType {
  quietRoom('Quiet Room', Icons.volume_off), 
  // Represents a quiet room with an associated name and icon.
  conferenceRoom('Conference Room', Icons.groups), 
  // Represents a conference room with an associated name and icon.
  studyRoom('Study Room', Icons.menu_book); 
  // Represents a study room with an associated name and icon.

  final String displayName; 
  // The display name of the room type.
  final IconData icon; 
  // The icon representing the room type.

  const RoomType(this.displayName, this.icon); 
  // Constructor for RoomType enum.
}

// Enum for room features
enum RoomFeature {
  projector('Projector', Icons.video_file), 
  // Represents a projector feature with an associated name and icon.
  whiteboard('Whiteboard', Icons.edit_square), 
  // Represents a whiteboard feature with an associated name and icon.
  videoConferencing('Video Conferencing', Icons.video_call), 
  // Represents video conferencing equipment with an associated name and icon.
  computerEquipment('Computer Equipment', Icons.computer); 
  // Represents computer equipment with an associated name and icon.

  final String displayName; 
  // The display name of the room feature.
  final IconData icon; 
  // The icon representing the room feature.

  const RoomFeature(this.displayName, this.icon); 
  // Constructor for RoomFeature enum.
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
    _bookings.removeWhere(
      (booking) => booking.location == location && 
                  booking.dateTime == dateTime &&
                  booking.roomType == roomType
    ); 
    // Removes a booking from the list if it matches the given location, dateTime, and roomType.
  }
}