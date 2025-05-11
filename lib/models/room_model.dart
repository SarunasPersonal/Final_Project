// lib/models/room_model.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

enum RoomType {
  quietRoom,
  conferenceRoom,
  studyRoom;

  String get displayName {
    switch (this) {
      case RoomType.quietRoom:
        return 'Quiet Room';
      case RoomType.conferenceRoom:
        return 'Conference Room';
      case RoomType.studyRoom:
        return 'Study Room';
    }
  }

  IconData get icon {
    switch (this) {
      case RoomType.quietRoom:
        return Icons.meeting_room;
      case RoomType.conferenceRoom:
        return Icons.groups;
      case RoomType.studyRoom:
        return Icons.school;
    }
  }
}

enum RoomFeature {
  projector,
  whiteboard,
  computer,
  printer,
  wifi,
  accessible;

  String get displayName {
    switch (this) {
      case RoomFeature.projector:
        return 'Projector';
      case RoomFeature.whiteboard:
        return 'Whiteboard';
      case RoomFeature.computer:
        return 'Computer';
      case RoomFeature.printer:
        return 'Printer';
      case RoomFeature.wifi:
        return 'WiFi';
      case RoomFeature.accessible:
        return 'Accessible';
    }
  }

  IconData get icon {
    switch (this) {
      case RoomFeature.projector:
        return Icons.videocam;
      case RoomFeature.whiteboard:
        return Icons.edit;
      case RoomFeature.computer:
        return Icons.computer;
      case RoomFeature.printer:
        return Icons.print;
      case RoomFeature.wifi:
        return Icons.wifi;
      case RoomFeature.accessible:
        return Icons.accessible;
    }
  }
}

class Room {
  final String id;
  final String name;
  final RoomType type;
  final int capacity;
  final String campus;
  final String? location;
  final String? notes;
  final List<RoomFeature> features;
  final bool isAvailable;

  Room({
    required this.id,
    required this.name,
    required this.type,
    required this.capacity,
    required this.campus,
    this.location,
    this.notes,
    required this.features,
    this.isAvailable = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'capacity': capacity,
      'campus': campus,
      'location': location,
      'notes': notes,
      'features': features.map((f) => f.name).toList(),
      'isAvailable': isAvailable,
    };
  }

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      name: json['name'] as String,
      type: RoomType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RoomType.studyRoom,
      ),
      capacity: json['capacity'] as int,
      campus: json['campus'] as String,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      features: (json['features'] as List<dynamic>?)
              ?.map((f) => RoomFeature.values.firstWhere(
                    (e) => e.name == f,
                    orElse: () => RoomFeature.wifi,
                  ))
              .toList() ??
          [],
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }
}

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'rooms';
  final Logger _logger = Logger('RoomService');

  // Singleton pattern
  static final RoomService _instance = RoomService._internal();
  factory RoomService() => _instance;
  RoomService._internal();

  // Get all rooms from Firestore
  Future<List<Room>> getAllRooms() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection(_collection).get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is included
        return Room.fromJson(data);
      }).toList();
    } catch (e) {
      _logger.warning('Error getting rooms: $e');
      // Return mock data in case of errors
      return _createDefaultRooms();
    }
  }

  // Get rooms for a specific campus
  Future<List<Room>> getRoomsByCampus(String campus) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('campus', isEqualTo: campus)
          .get();
          
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is included
        return Room.fromJson(data);
      }).toList();
    } catch (e) {
      _logger.warning('Error getting rooms for campus $campus: $e');
      
      // Return filtered mock data for this campus
      return _createDefaultRooms()
          .where((room) => room.campus == campus)
          .toList();
    }
  }

  // Get rooms of a specific type
  Future<List<Room>> getRoomsByType(RoomType type) async {
    String typeStr;
    switch (type) {
      case RoomType.quietRoom:
        typeStr = 'quietRoom';
        break;
      case RoomType.conferenceRoom:
        typeStr = 'conferenceRoom';
        break;
      case RoomType.studyRoom:
        typeStr = 'studyRoom';
        break;
    }

    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('type', isEqualTo: typeStr)
          .get();
          
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is included
        return Room.fromJson(data);
      }).toList();
    } catch (e) {
      _logger.warning('Error getting rooms by type $type: $e');
      
      // Return filtered mock data for this type
      return _createDefaultRooms()
          .where((room) => room.type == type)
          .toList();
    }
  }

  // Get a room by ID
  Future<Room?> getRoomById(String id) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection(_collection).doc(id).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is included
        return Room.fromJson(data);
      }
      return null;
    } catch (e) {
      _logger.warning('Error getting room by ID $id: $e');
      return null;
    }
  }

  // Initialize the system with default rooms
  Future<void> initializeDefaultRooms() async {
    try {
      // Check if rooms already exist
      final QuerySnapshot snapshot = await _firestore.collection(_collection).limit(1).get();
      
      if (snapshot.docs.isNotEmpty) {
        _logger.info('Rooms already exist, skipping initialization');
        return; // Rooms already exist, no need to initialize
      }
      
      _logger.info('Initializing default rooms');
      
      // Create default rooms if none exist
      final List<Room> defaultRooms = _createDefaultRooms();
      
      // Use a batch to add all default rooms
      final WriteBatch batch = _firestore.batch();
      
      for (var room in defaultRooms) {
        final DocRef = _firestore.collection(_collection).doc(room.id);
        batch.set(DocRef, room.toJson());
      }
      
      await batch.commit();
      _logger.info('Default rooms initialized successfully (${defaultRooms.length} rooms added)');
    } catch (e) {
      _logger.warning('Error initializing default rooms: $e');
    }
  }

  // Add a new room
  Future<bool> addRoom(Room room) async {
    try {
      await _firestore.collection(_collection).doc(room.id).set(room.toJson());
      _logger.info('Added room: ${room.name}');
      return true;
    } catch (e) {
      _logger.warning('Error adding room ${room.name}: $e');
      return false;
    }
  }

  // Delete a room by ID
  Future<bool> deleteRoom(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      _logger.info('Deleted room: $id');
      return true;
    } catch (e) {
      _logger.warning('Error deleting room $id: $e');
      return false;
    }
  }

  // Update an existing room
  Future<bool> updateRoom(Room room) async {
    try {
      await _firestore.collection(_collection).doc(room.id).update(room.toJson());
      _logger.info('Updated room: ${room.name}');
      return true;
    } catch (e) {
      _logger.warning('Error updating room ${room.name}: $e');
      return false;
    }
  }

  // Create a list of default rooms
  List<Room> _createDefaultRooms() {
    return [
      // Taunton campus rooms
      Room(
        id: 'taunton-quiet-1',
        name: 'Quiet Study Room 1',
        campus: 'Taunton',
        type: RoomType.quietRoom,
        capacity: 1,
        features: [RoomFeature.computer, RoomFeature.wifi],
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
          RoomFeature.wifi,
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
          RoomFeature.wifi,
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
        features: [RoomFeature.wifi],
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
          RoomFeature.wifi,
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
          RoomFeature.wifi,
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
        features: [RoomFeature.wifi],
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
          RoomFeature.wifi,
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
          RoomFeature.wifi,
        ],
        location: 'Library Building',
      ),
    ];
  }
  
  // Get room counts by campus
  Future<Map<String, Map<String, int>>> getRoomCountsByCampus() async {
    try {
      final Map<String, Map<String, int>> result = {
        'Taunton': {'quiet': 0, 'conference': 0, 'study': 0, 'total': 0},
        'Bridgwater': {'quiet': 0, 'conference': 0, 'study': 0, 'total': 0},
        'Cannington': {'quiet': 0, 'conference': 0, 'study': 0, 'total': 0},
      };
      
      final List<Room> rooms = await getAllRooms();
      
      for (final Room room in rooms) {
        final String campus = room.campus;
        final String type = room.type == RoomType.quietRoom 
            ? 'quiet' 
            : room.type == RoomType.conferenceRoom 
                ? 'conference' 
                : 'study';
        
        if (result.containsKey(campus)) {
          result[campus]![type] = (result[campus]![type] ?? 0) + 1;
          result[campus]!['total'] = (result[campus]!['total'] ?? 0) + 1;
        }
      }
      
      return result;
    } catch (e) {
      _logger.warning('Error calculating room counts: $e');
      // Return mock data
      return {
        'Taunton': {'quiet': 2, 'conference': 1, 'study': 1, 'total': 4},
        'Bridgwater': {'quiet': 1, 'conference': 2, 'study': 1, 'total': 4},
        'Cannington': {'quiet': 1, 'conference': 1, 'study': 2, 'total': 4},
      };
    }
  }

  // Get total capacity by campus
  Future<Map<String, int>> getTotalCapacityByCampus() async {
    try {
      final Map<String, int> result = {
        'Taunton': 0,
        'Bridgwater': 0,
        'Cannington': 0,
      };
      
      final List<Room> rooms = await getAllRooms();
      
      for (final Room room in rooms) {
        final String campus = room.campus;
        
        if (result.containsKey(campus)) {
          result[campus] = (result[campus] ?? 0) + room.capacity;
        }
      }
      
      return result;
    } catch (e) {
      _logger.warning('Error calculating total capacity: $e');
      // Return mock data
      return {
        'Taunton': 40,
        'Bridgwater': 30,
        'Cannington': 25,
      };
    }
  }
}