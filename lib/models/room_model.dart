import 'package:flutter/material.dart';

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
      features: (json['features'] as List<dynamic>)
          .map((f) => RoomFeature.values.firstWhere(
                (e) => e.name == f,
                orElse: () => RoomFeature.wifi,
              ))
          .toList(),
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }
}

class RoomService {
  Future<List<Room>> getRoomsByCampus(String campus) async {
    // TODO: Implement actual API call to get rooms
    // This is a mock implementation
    return [
      Room(
        id: '1',
        name: 'Quiet Room 1',
        type: RoomType.quietRoom,
        capacity: 1,
        campus: 'Taunton',
        location: 'First Floor',
        notes: 'Quiet study space',
        features: [RoomFeature.wifi],
      ),
      Room(
        id: '2',
        name: 'Conference Room A',
        type: RoomType.conferenceRoom,
        capacity: 10,
        campus: 'Bridgwater',
        location: 'Second Floor',
        notes: 'For meetings',
        features: [
          RoomFeature.projector,
          RoomFeature.whiteboard,
          RoomFeature.wifi
        ],
      ),
      Room(
        id: '3',
        name: 'Study Room 1',
        type: RoomType.studyRoom,
        capacity: 4,
        campus: 'Cannington',
        location: 'Ground Floor',
        notes: 'Group study',
        features: [RoomFeature.computer, RoomFeature.printer, RoomFeature.wifi],
      ),
    ];
  }

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

  // Add missing methods
  Future<void> initializeDefaultRooms() async {
    // TODO: Implement actual initialization
    print('Initializing default rooms');
  }

  Future<List<Room>> getAllRooms() async {
    // TODO: Implement actual API call
    return [
      Room(
        id: '1',
        name: 'Quiet Room 1',
        type: RoomType.quietRoom,
        capacity: 1,
        campus: 'Taunton',
        location: 'First Floor',
        notes: 'Quiet study space',
        features: [RoomFeature.wifi],
      ),
      Room(
        id: '2',
        name: 'Conference Room A',
        type: RoomType.conferenceRoom,
        capacity: 10,
        campus: 'Bridgwater',
        location: 'Second Floor',
        notes: 'For meetings',
        features: [
          RoomFeature.projector,
          RoomFeature.whiteboard,
          RoomFeature.wifi
        ],
      ),
    ];
  }

  Future<void> deleteRoom(String roomId) async {
    // TODO: Implement actual deletion
    print('Deleting room: $roomId');
  }

  Future<void> addRoom(Room room) async {
    // TODO: Implement actual addition
    print('Adding room: ${room.name}');
  }

  Future<void> updateRoom(Room room) async {
    // TODO: Implement actual update
    print('Updating room: ${room.name}');
  }
}
