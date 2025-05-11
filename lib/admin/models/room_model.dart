// lib/admin/models/room_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ucs_app/models/room_model.dart'; // Import the models from the correct location
import 'package:logging/logging.dart';

/// Model class for a room in a campus
class Room {
  final String id;            // Unique ID for the room
  final String name;          // Display name for the room
  final String campus;        // Campus the room is located in
  final RoomType type;        // Type of room (Quiet, Conference, Study)
  final int capacity;         // Maximum number of people allowed
  final bool isAvailable;     // Whether the room is available for booking
  final List<RoomFeature> features; // Available features in the room
  final String? imageUrl;     // Optional URL to an image of the room
  final String? location;     // Optional description of where to find the room
  final String? notes;        // Optional additional information

  Room({
    required this.id,
    required this.name,
    required this.campus,
    required this.type,
    required this.capacity,
    this.isAvailable = true,
    this.features = const [],
    this.imageUrl,
    this.location,
    this.notes,
  });

  /// Create a Room from a Firestore document
  factory Room.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Parse the room type
    RoomType roomType;
    switch (data['type']) {
      case 'quiet':
        roomType = RoomType.quietRoom;
        break;
      case 'conference':
        roomType = RoomType.conferenceRoom;
        break;
      case 'study':
        roomType = RoomType.studyRoom;
        break;
      default:
        roomType = RoomType.quietRoom;
    }
    
    // Parse the features list
    List<RoomFeature> roomFeatures = [];
    if (data['features'] != null) {
      for (var feature in (data['features'] as List)) {
        switch (feature) {
          case 'projector':
            roomFeatures.add(RoomFeature.projector);
            break;
          case 'whiteboard':
            roomFeatures.add(RoomFeature.whiteboard);
            break;
          case 'video_conferencing':
            roomFeatures.add(RoomFeature.computer);
            break;
          case 'computer_equipment':
            roomFeatures.add(RoomFeature.computer);
            break;
        }
      }
    }
    
    return Room(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Room',
      campus: data['campus'] ?? '',
      type: roomType,
      capacity: data['capacity'] ?? 1,
      isAvailable: data['isAvailable'] ?? true,
      features: roomFeatures,
      imageUrl: data['imageUrl'],
      location: data['location'],
      notes: data['notes'],
    );
  }
  
  /// Convert this Room to a map for Firestore
  Map<String, dynamic> toFirestore() {
    // Convert RoomType to string
    String typeStr;
    switch (type) {
      case RoomType.quietRoom:
        typeStr = 'quiet';
        break;
      case RoomType.conferenceRoom:
        typeStr = 'conference';
        break;
      case RoomType.studyRoom:
        typeStr = 'study';
        break;
    }
    
    // Convert features to list of strings
    List<String> featureStrings = features.map((feature) {
      switch (feature) {
        case RoomFeature.projector:
          return 'projector';
        case RoomFeature.whiteboard:
          return 'whiteboard';
        case RoomFeature.computer:
          return 'video_conferencing';
        case RoomFeature.printer:
          return 'printer';
        case RoomFeature.wifi:
          return 'wifi';
        case RoomFeature.accessible:
          return 'accessible';
      }
    }).toList();
    
    return {
      'name': name,
      'campus': campus,
      'type': typeStr,
      'capacity': capacity,
      'isAvailable': isAvailable,
      'features': featureStrings,
      'imageUrl': imageUrl,
      'location': location,
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

/// Service to manage rooms in the system
class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'rooms';
  final Logger _logger = Logger('RoomService');
  
  // Singleton pattern
  static final RoomService _instance = RoomService._internal();
  factory RoomService() => _instance;
  RoomService._internal();
  
  /// Get a list of all rooms
  Future<List<Room>> getAllRooms() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs.map((doc) => Room.fromFirestore(doc)).toList();
    } catch (e) {
      _logger.warning('Error getting rooms: $e');
      return [];
    }
  }
  
  /// Get rooms for a specific campus
  Future<List<Room>> getRoomsByCampus(String campus) async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(_collection)
          .where('campus', isEqualTo: campus)
          .get();
      return snapshot.docs.map((doc) => Room.fromFirestore(doc)).toList();
    } catch (e) {
      _logger.warning('Error getting rooms for campus: $e');
      return [];
    }
  }
  
  /// Get rooms of a specific type
  Future<List<Room>> getRoomsByType(RoomType type) async {
    String typeStr;
    switch (type) {
      case RoomType.quietRoom:
        typeStr = 'quiet';
        break;
      case RoomType.conferenceRoom:
        typeStr = 'conference';
        break;
      case RoomType.studyRoom:
        typeStr = 'study';
        break;
    }
    
    try {
      QuerySnapshot snapshot = await _firestore.collection(_collection)
          .where('type', isEqualTo: typeStr)
          .get();
      return snapshot.docs.map((doc) => Room.fromFirestore(doc)).toList();
    } catch (e) {
      _logger.warning('Error getting rooms by type: $e');
      return [];
    }
  }
  
  /// Get a room by ID
  Future<Room?> getRoomById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Room.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      _logger.warning('Error getting room by ID: $e');
      return null;
    }
  }
  
  /// Add a new room
  Future<bool> addRoom(Room room) async {
    try {
      await _firestore.collection(_collection).add(room.toFirestore());
      return true;
    } catch (e) {
      _logger.warning('Error adding room: $e');
      return false;
    }
  }
  
  /// Update a room
  Future<bool> updateRoom(Room room) async {
    try {
      await _firestore.collection(_collection).doc(room.id).update(room.toFirestore());
      return true;
    } catch (e) {
      _logger.warning('Error updating room: $e');
      return false;
    }
  }
  
  /// Delete a room
  Future<bool> deleteRoom(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      _logger.warning('Error deleting room: $e');
      return false;
    }
  }
  
  /// Check if a room is available at a specific time
  Future<bool> isRoomAvailable(String roomId, DateTime dateTime) async {
    try {
      // Get bookings for this room around the requested time
      final startTime = dateTime.subtract(const Duration(hours: 1));
      final endTime = dateTime.add(const Duration(hours: 1));
      
      QuerySnapshot snapshot = await _firestore.collection('bookings')
          .where('roomId', isEqualTo: roomId)
          .where('dateTime', isGreaterThanOrEqualTo: startTime)
          .where('dateTime', isLessThanOrEqualTo: endTime)
          .get();
      
      // If there are no bookings in this time range, the room is available
      return snapshot.docs.isEmpty;
    } catch (e) {
      _logger.warning('Error checking room availability: $e');
      // Default to available if there's an error checking
      return true;
    }
  }
  
  /// Get bookings for a specific room
  Future<List<Map<String, dynamic>>> getRoomBookings(String roomId) async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('bookings')
          .where('roomId', isEqualTo: roomId)
          .orderBy('dateTime')
          .get();
      
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      _logger.warning('Error getting room bookings: $e');
      return [];
    }
  }
  
  /// Initialize the system with default rooms
  Future<void> initializeDefaultRooms() async {
    try {
      // Check if rooms already exist
      QuerySnapshot snapshot = await _firestore.collection(_collection).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        return; // Rooms already exist, no need to initialize
      }
      
      // Create default rooms if none exist
      List<Room> defaultRooms = _createDefaultRooms();
      
      // Add all default rooms to Firestore
      WriteBatch batch = _firestore.batch();
      
      for (var room in defaultRooms) {
        DocumentReference docRef = _firestore.collection(_collection).doc(room.id);
        batch.set(docRef, room.toFirestore());
      }
      
      await batch.commit();
      _logger.info('Default rooms initialized successfully');
    } catch (e) {
      _logger.warning('Error initializing default rooms: $e');
    }
  }
  
  /// Create a list of default rooms for initialization
  List<Room> _createDefaultRooms() {
    return [
      // Taunton campus rooms
      Room(
        id: 'taunton-quiet-1',
        name: 'Quiet Study Room 1',
        campus: 'Taunton',
        type: RoomType.quietRoom,
        capacity: 1,
        features: [RoomFeature.computer],
        location: 'Library, Ground Floor',
      ),
      Room(
        id: 'taunton-conference-1',
        name: 'Conference Room A',
        campus: 'Taunton',
        type: RoomType.conferenceRoom,
        capacity: 20,
        features: [
          RoomFeature.projector,
          RoomFeature.whiteboard,
          RoomFeature.computer,
        ],
        location: 'Main Building, Room M102',
      ),
      Room(
        id: 'taunton-study-1',
        name: 'Study Room 1',
        campus: 'Taunton',
        type: RoomType.studyRoom,
        capacity: 6,
        features: [
          RoomFeature.whiteboard,
          RoomFeature.computer,
        ],
        location: 'Library, Second Floor',
      ),
      
      // Bridgwater campus rooms
      Room(
        id: 'bridgwater-quiet-1',
        name: 'Quiet Study Pod 1',
        campus: 'Bridgwater',
        type: RoomType.quietRoom,
        capacity: 1,
        location: 'Learning Resource Center',
      ),
      Room(
        id: 'bridgwater-conference-1',
        name: 'Main Conference Room',
        campus: 'Bridgwater',
        type: RoomType.conferenceRoom,
        capacity: 30,
        features: [
          RoomFeature.projector,
          RoomFeature.whiteboard,
          RoomFeature.computer,
        ],
        location: 'Bath Building, Ground Floor',
      ),
      Room(
        id: 'bridgwater-study-1',
        name: 'Group Study Room 1',
        campus: 'Bridgwater',
        type: RoomType.studyRoom,
        capacity: 8,
        features: [
          RoomFeature.whiteboard,
        ],
        location: 'Learning Resource Center',
      ),
      
      // Cannington campus rooms
      Room(
        id: 'cannington-quiet-1',
        name: 'Quiet Study Room 1',
        campus: 'Cannington',
        type: RoomType.quietRoom,
        capacity: 1,
        location: 'Library Building',
      ),
      Room(
        id: 'cannington-conference-1',
        name: 'Rodway Conference Room',
        campus: 'Cannington',
        type: RoomType.conferenceRoom,
        capacity: 20,
        features: [
          RoomFeature.projector,
          RoomFeature.whiteboard,
          RoomFeature.computer,
        ],
        location: 'Rodway Building, Room R101',
      ),
      Room(
        id: 'cannington-study-1',
        name: 'Study Group Room 1',
        campus: 'Cannington',
        type: RoomType.studyRoom,
        capacity: 6,
        features: [
          RoomFeature.whiteboard,
        ],
        location: 'Library Building',
      ),
    ];
  }
  
  // Additional methods needed by the code
  Future<Map<String, Map<String, int>>> getRoomCountsByCampus() async {
    // Mock implementation: returns a map of campus -> {type: count, total: count}
    return {
      'Taunton': {'quiet': 2, 'conference': 1, 'study': 1, 'total': 4},
      'Bridgwater': {'quiet': 1, 'conference': 2, 'study': 1, 'total': 4},
      'Cannington': {'quiet': 1, 'conference': 1, 'study': 2, 'total': 4},
    };
  }

  Future<Map<String, int>> getTotalCapacityByCampus() async {
    // Mock implementation: returns a map of campus -> total capacity
    return {
      'Taunton': 40,
      'Bridgwater': 30,
      'Cannington': 25,
    };
  }
}