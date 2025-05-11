// lib/admin/models/room_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_ucs_app/booking_model.dart'; // For RoomType and RoomFeature enums
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
            roomFeatures.add(RoomFeature.videoConferencing);
            break;
          case 'computer_equipment':
            roomFeatures.add(RoomFeature.computerEquipment);
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
        case RoomFeature.videoConferencing:
          return 'video_conferencing';
        case RoomFeature.computerEquipment:
          return 'computer_equipment';
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
  
  /// Get room counts by campus
  Future<Map<String, Map<String, int>>> getRoomCountsByCampus() async {
    Map<String, Map<String, int>> counts = {
      'Taunton': {'quiet': 0, 'conference': 0, 'study': 0, 'total': 0},
      'Bridgwater': {'quiet': 0, 'conference': 0, 'study': 0, 'total': 0},
      'Cannington': {'quiet': 0, 'conference': 0, 'study': 0, 'total': 0},
    };
    
    try {
      QuerySnapshot snapshot = await _firestore.collection(_collection).get();
      
      for (var doc in snapshot.docs) {
        var room = Room.fromFirestore(doc);
        
        if (counts.containsKey(room.campus)) {
          String typeKey;
          switch (room.type) {
            case RoomType.quietRoom:
              typeKey = 'quiet';
              break;
            case RoomType.conferenceRoom:
              typeKey = 'conference';
              break;
            case RoomType.studyRoom:
              typeKey = 'study';
              break;
          }
          
          counts[room.campus]![typeKey] = (counts[room.campus]![typeKey] ?? 0) + 1;
          counts[room.campus]!['total'] = (counts[room.campus]!['total'] ?? 0) + 1;
        }
      }
      
      return counts;
    } catch (e) {
      _logger.warning('Error getting room counts: $e');
      return counts;
    }
  }
  
  /// Get the total capacity by campus
  Future<Map<String, int>> getTotalCapacityByCampus() async {
    Map<String, int> capacity = {
      'Taunton': 0,
      'Bridgwater': 0,
      'Cannington': 0,
    };
    
    try {
      QuerySnapshot snapshot = await _firestore.collection(_collection).get();
      
      for (var doc in snapshot.docs) {
        var room = Room.fromFirestore(doc);
        
        if (capacity.containsKey(room.campus)) {
          capacity[room.campus] = (capacity[room.campus] ?? 0) + room.capacity;
        }
      }
      
      return capacity;
    } catch (e) {
      _logger.warning('Error getting room capacity: $e');
      return capacity;
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
      
      // Default rooms for each campus
      List<Room> defaultRooms = [
        // Taunton campus
        Room(
          id: 'taunton-quiet-1',
          name: 'Quiet Study Room 1',
          campus: 'Taunton',
          type: RoomType.quietRoom,
          capacity: 1,
          features: [RoomFeature.computerEquipment],
          location: 'Library, Ground Floor',
        ),
        Room(
          id: 'taunton-quiet-2',
          name: 'Quiet Study Room 2',
          campus: 'Taunton',
          type: RoomType.quietRoom,
          capacity: 1,
          features: [RoomFeature.computerEquipment],
          location: 'Library, Ground Floor',
        ),
        Room(
          id: 'taunton-quiet-3',
          name: 'Quiet Study Room 3',
          campus: 'Taunton',
          type: RoomType.quietRoom,
          capacity: 1,
          features: [RoomFeature.computerEquipment],
          location: 'Library, First Floor',
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
            RoomFeature.videoConferencing,
            RoomFeature.computerEquipment,
          ],
          location: 'Main Building, Room M102',
        ),
        Room(
          id: 'taunton-conference-2',
          name: 'Conference Room B',
          campus: 'Taunton',
          type: RoomType.conferenceRoom,
          capacity: 15,
          features: [
            RoomFeature.projector,
            RoomFeature.whiteboard,
            RoomFeature.videoConferencing,
          ],
          location: 'Main Building, Room M103',
        ),
        Room(
          id: 'taunton-conference-3',
          name: 'Conference Room C',
          campus: 'Taunton',
          type: RoomType.conferenceRoom,
          capacity: 10,
          features: [
            RoomFeature.projector,
            RoomFeature.whiteboard,
          ],
          location: 'Main Building, Room M104',
        ),
        Room(
          id: 'taunton-study-1',
          name: 'Study Room 1',
          campus: 'Taunton',
          type: RoomType.studyRoom,
          capacity: 6,
          features: [
            RoomFeature.whiteboard,
            RoomFeature.computerEquipment,
          ],
          location: 'Library, Second Floor',
        ),
        Room(
          id: 'taunton-study-2',
          name: 'Study Room 2',
          campus: 'Taunton',
          type: RoomType.studyRoom,
          capacity: 4,
          features: [
            RoomFeature.whiteboard,
          ],
          location: 'Library, Second Floor',
        ),
        Room(
          id: 'taunton-study-3',
          name: 'Study Room 3',
          campus: 'Taunton',
          type: RoomType.studyRoom,
          capacity: 8,
          features: [
            RoomFeature.whiteboard,
            RoomFeature.computerEquipment,
          ],
          location: 'Library, Third Floor',
        ),
        
        // Bridgwater campus
        Room(
          id: 'bridgwater-quiet-1',
          name: 'Quiet Study Pod 1',
          campus: 'Bridgwater',
          type: RoomType.quietRoom,
          capacity: 1,
          features: [],
          location: 'Learning Resource Center',
        ),
        Room(
          id: 'bridgwater-quiet-2',
          name: 'Quiet Study Pod 2',
          campus: 'Bridgwater',
          type: RoomType.quietRoom,
          capacity: 1,
          features: [],
          location: 'Learning Resource Center',
        ),
        Room(
          id: 'bridgwater-quiet-3',
          name: 'Quiet Study Room',
          campus: 'Bridgwater',
          type: RoomType.quietRoom,
          capacity: 2,
          features: [RoomFeature.computerEquipment],
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
            RoomFeature.videoConferencing,
            RoomFeature.computerEquipment,
          ],
          location: 'Bath Building, Ground Floor',
        ),
        Room(
          id: 'bridgwater-conference-2',
          name: 'Conference Room A',
          campus: 'Bridgwater',
          type: RoomType.conferenceRoom,
          capacity: 12,
          features: [
            RoomFeature.projector,
            RoomFeature.whiteboard,
          ],
          location: 'Bath Building, First Floor',
        ),
        Room(
          id: 'bridgwater-conference-3',
          name: 'Conference Room B',
          campus: 'Bridgwater',
          type: RoomType.conferenceRoom,
          capacity: 12,
          features: [
            RoomFeature.projector,
            RoomFeature.whiteboard,
          ],
          location: 'Bath Building, First Floor',
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
        Room(
          id: 'bridgwater-study-2',
          name: 'Group Study Room 2',
          campus: 'Bridgwater',
          type: RoomType.studyRoom,
          capacity: 6,
          features: [
            RoomFeature.whiteboard,
          ],
          location: 'Learning Resource Center',
        ),
        Room(
          id: 'bridgwater-study-3',
          name: 'Group Study Room 3',
          campus: 'Bridgwater',
          type: RoomType.studyRoom,
          capacity: 10,
          features: [
            RoomFeature.whiteboard,
            RoomFeature.projector,
          ],
          location: 'Learning Resource Center',
        ),
        
        // Cannington campus
        Room(
          id: 'cannington-quiet-1',
          name: 'Quiet Study Room 1',
          campus: 'Cannington',
          type: RoomType.quietRoom,
          capacity: 1,
          features: [],
          location: 'Library Building',
        ),
        Room(
          id: 'cannington-quiet-2',
          name: 'Quiet Study Room 2',
          campus: 'Cannington',
          type: RoomType.quietRoom,
          capacity: 1,
          features: [],
          location: 'Library Building',
        ),
        Room(
          id: 'cannington-quiet-3',
          name: 'Quiet Study Room 3',
          campus: 'Cannington',
          type: RoomType.quietRoom,
          capacity: 1,
          features: [],
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
            RoomFeature.videoConferencing,
          ],
          location: 'Rodway Building, Room R101',
        ),
        Room(
          id: 'cannington-conference-2',
          name: 'Small Conference Room',
          campus: 'Cannington',
          type: RoomType.conferenceRoom,
          capacity: 8,
          features: [
            RoomFeature.projector,
            RoomFeature.whiteboard,
          ],
          location: 'Rodway Building, Room R102',
        ),
        Room(
          id: 'cannington-conference-3',
          name: 'Rural Business Conference Room',
          campus: 'Cannington',
          type: RoomType.conferenceRoom,
          capacity: 15,
          features: [
            RoomFeature.projector,
            RoomFeature.whiteboard,
            RoomFeature.videoConferencing,
          ],
          location: 'Rural Business Center',
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
        Room(
          id: 'cannington-study-2',
          name: 'Study Group Room 2',
          campus: 'Cannington',
          type: RoomType.studyRoom,
          capacity: 4,
          features: [
            RoomFeature.whiteboard,
          ],
          location: 'Library Building',
        ),
        Room(
          id: 'cannington-study-3',
          name: 'Study Group Room 3',
          campus: 'Cannington',
          type: RoomType.studyRoom,
          capacity: 6,
          features: [
            RoomFeature.whiteboard,
          ],
          location: 'Rodway Building',
        ),
      ];
      
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
}