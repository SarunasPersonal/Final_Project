// lib/admin/rooms_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_ucs_app/constants.dart';
import 'package:flutter_ucs_app/booking_model.dart';
import 'package:flutter_ucs_app/models/room_model.dart';
import 'package:data_table_2/data_table_2.dart';

class RoomsManagementScreen extends StatefulWidget {
  const RoomsManagementScreen({super.key});

  @override
  State<RoomsManagementScreen> createState() => _RoomsManagementScreenState();
}

class _RoomsManagementScreenState extends State<RoomsManagementScreen> with SingleTickerProviderStateMixin {
  final RoomService _roomService = RoomService();
  List<Room> _rooms = [];
  List<Room> _filteredRooms = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterCampus = 'All Campuses';
  RoomType? _filterRoomType;
  
  late TabController _tabController;
  Map<String, Map<String, int>> _roomCounts = {};
  Map<String, int> _capacityCounts = {};
  
  // Form controllers for adding/editing rooms
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  String _selectedCampus = 'Taunton';
  RoomType _selectedRoomType = RoomType.quietRoom;
  bool _isAvailable = true;
  final Map<RoomFeature, bool> _selectedFeatures = {
    for (var feature in RoomFeature.values) feature: false
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRooms();
    _loadStatistics();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _capacityController.dispose();
    super.dispose();
  }
  
  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Initialize default rooms if needed
      await _roomService.initializeDefaultRooms();
      
      // Load all rooms
      var rooms = await _roomService.getAllRooms();
      
      setState(() {
        _rooms = rooms;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading rooms: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading rooms: $e')),
        );
      }
    }
  }
  
  Future<void> _loadStatistics() async {
    try {
      var roomCounts = await _roomService.getRoomCountsByCampus();
      var capacityCounts = await _roomService.getTotalCapacityByCampus();
      
      setState(() {
        _roomCounts = roomCounts;
        _capacityCounts = capacityCounts;
      });
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }
  
  void _applyFilters() {
    setState(() {
      _filteredRooms = _rooms.where((room) {
        // Apply campus filter
        if (_filterCampus != 'All Campuses' && room.campus != _filterCampus) {
          return false;
        }
        
        // Apply room type filter
        if (_filterRoomType != null && room.type != _filterRoomType) {
          return false;
        }
        
        // Apply search query
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          return room.name.toLowerCase().contains(query) ||
                 room.campus.toLowerCase().contains(query) ||
                 (room.location?.toLowerCase().contains(query) ?? false);
        }
        
        return true;
      }).toList();
    });
  }
  
  Future<void> _deleteRoom(Room room) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _roomService.deleteRoom(room.id);
      
      setState(() {
        _rooms.removeWhere((r) => r.id == room.id);
        _applyFilters();
        _isLoading = false;
      });
      
      await _loadStatistics();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room deleted successfully')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting room: $e')),
      );
    }
  }
  
  void _showAddRoomDialog() {
    // Reset form
    _nameController.clear();
    _locationController.clear();
    _notesController.clear();
    _capacityController.text = '1';
    _selectedCampus = 'Taunton';
    _selectedRoomType = RoomType.quietRoom;
    _isAvailable = true;
    for (var feature in RoomFeature.values) {
      _selectedFeatures[feature] = false;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Room'),
        content: SingleChildScrollView(
          child: _buildRoomForm(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
            ),
            onPressed: () {
              if (_validateForm()) {
                Navigator.pop(context);
                _addRoom();
              }
            },
            child: Text(
              'Add Room',
              style: TextStyle(color: secondaryColor),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showEditRoomDialog(Room room) {
    // Populate form with room data
    _nameController.text = room.name;
    _locationController.text = room.location ?? '';
    _notesController.text = room.notes ?? '';
    _capacityController.text = room.capacity.toString();
    _selectedCampus = room.campus;
    _selectedRoomType = room.type;
    _isAvailable = room.isAvailable;
    
    // Reset features and select the ones from the room
    for (var feature in RoomFeature.values) {
      _selectedFeatures[feature] = false;
    }
    for (var feature in room.features) {
      _selectedFeatures[feature] = true;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Room'),
        content: SingleChildScrollView(
          child: _buildRoomForm(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
            ),
            onPressed: () {
              if (_validateForm()) {
                Navigator.pop(context);
                _updateRoom(room.id);
              }
            },
            child: Text(
              'Update Room',
              style: TextStyle(color: secondaryColor),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRoomForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Room name
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Room Name',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16),
        
        // Campus dropdown
        DropdownButtonFormField<String>(
          value: _selectedCampus,
          decoration: InputDecoration(
            labelText: 'Campus',
            border: OutlineInputBorder(),
          ),
          items: ['Taunton', 'Bridgwater', 'Cannington'].map((campus) {
            return DropdownMenuItem<String>(
              value: campus,
              child: Text(campus),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCampus = value!;
            });
          },
        ),
        SizedBox(height: 16),
        
        // Room type dropdown
        DropdownButtonFormField<RoomType>(
          value: _selectedRoomType,
          decoration: InputDecoration(
            labelText: 'Room Type',
            border: OutlineInputBorder(),
          ),
          items: RoomType.values.map((type) {
            return DropdownMenuItem<RoomType>(
              value: type,
              child: Row(
                children: [
                  Icon(type.icon, size: 16),
                  SizedBox(width: 8),
                  Text(type.displayName),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedRoomType = value!;
            });
          },
        ),
        SizedBox(height: 16),
        
        // Capacity
        TextField(
          controller: _capacityController,
          decoration: InputDecoration(
            labelText: 'Capacity',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 16),
        
        // Room location
        TextField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: 'Location (e.g., Building, Floor)',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16),
        
        // Room notes
        TextField(
          controller: _notesController,
          decoration: InputDecoration(
            labelText: 'Notes (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        SizedBox(height: 16),
        
        // Availability switch
        SwitchListTile(
          title: Text('Available for Booking'),
          value: _isAvailable,
          onChanged: (value) {
            setState(() {
              _isAvailable = value;
            });
          },
        ),
        
        // Features section
        Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Room Features',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        
        // Features checkboxes
        ...RoomFeature.values.map((feature) => CheckboxListTile(
          title: Row(
            children: [
              Icon(feature.icon, size: 16, color: primaryColor),
              SizedBox(width: 8),
              Text(feature.displayName),
            ],
          ),
          value: _selectedFeatures[feature],
          onChanged: (value) {
            setState(() {
              _selectedFeatures[feature] = value!;
            });
          },
        )),
      ],
    );
  }
  
  bool _validateForm() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a room name')),
      );
      return false;
    }
    
    int? capacity = int.tryParse(_capacityController.text);
    if (capacity == null || capacity < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid capacity (minimum 1)')),
      );
      return false;
    }
    
    return true;
  }
  
  Future<void> _addRoom() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Generate a room ID
      String roomId = '${_selectedCampus.toLowerCase()}-${_selectedRoomType == RoomType.quietRoom ? 'quiet' : _selectedRoomType == RoomType.conferenceRoom ? 'conference' : 'study'}-${DateTime.now().millisecondsSinceEpoch}';
      
      // Create room object
      Room room = Room(
        id: roomId,
        name: _nameController.text,
        campus: _selectedCampus,
        type: _selectedRoomType,
        capacity: int.parse(_capacityController.text),
        isAvailable: _isAvailable,
        features: RoomFeature.values
            .where((feature) => _selectedFeatures[feature] == true)
            .toList(),
        location: _locationController.text.isNotEmpty ? _locationController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
      
      // Add room to Firestore
      await _roomService.addRoom(room);
      
      // Reload rooms
      await _loadRooms();
      await _loadStatistics();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding room: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _updateRoom(String roomId) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Create updated room object
      Room room = Room(
        id: roomId,
        name: _nameController.text,
        campus: _selectedCampus,
        type: _selectedRoomType,
        capacity: int.parse(_capacityController.text),
        isAvailable: _isAvailable,
        features: RoomFeature.values
            .where((feature) => _selectedFeatures[feature] == true)
            .toList(),
        location: _locationController.text.isNotEmpty ? _locationController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
      
      // Update room in Firestore
      await _roomService.updateRoom(room);
      
      // Reload rooms
      await _loadRooms();
      await _loadStatistics();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating room: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading && _rooms.isEmpty
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Manage Rooms',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Tab bar
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: 'Rooms List'),
                    Tab(text: 'Campus Capacity'),
                  ],
                  labelColor: primaryColor,
                  indicatorColor: primaryColor,
                ),
                
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Rooms list tab
                      _buildRoomsListTab(),
                      
                      // Campus capacity tab
                      _buildCapacityTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: Icon(Icons.add, color: secondaryColor),
        onPressed: _showAddRoomDialog,
      ),
    );
  }
  
  Widget _buildRoomsListTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filters
          Row(
            children: [
              // Search field
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search rooms...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _applyFilters();
                  },
                ),
              ),
              SizedBox(width: 16),
              
              // Campus filter
              DropdownButton<String>(
                value: _filterCampus,
                items: [
                  'All Campuses',
                  'Taunton',
                  'Bridgwater',
                  'Cannington',
                ].map((campus) {
                  return DropdownMenuItem<String>(
                    value: campus,
                    child: Text(campus),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _filterCampus = value!;
                  });
                  _applyFilters();
                },
              ),
              SizedBox(width: 16),
              
              // Room type filter
              DropdownButton<RoomType?>(
                value: _filterRoomType,
                hint: Text('Room Type'),
                items: [
                  DropdownMenuItem<RoomType?>(
                    value: null,
                    child: Text('All Types'),
                  ),
                  ...RoomType.values.map((type) {
                    return DropdownMenuItem<RoomType?>(
                      value: type,
                      child: Row(
                        children: [
                          Icon(type.icon, size: 16),
                          SizedBox(width: 4),
                          Text(type.displayName),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _filterRoomType = value;
                  });
                  _applyFilters();
                },
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Rooms table
          Expanded(
            child: _filteredRooms.isEmpty
                ? Center(child: Text('No rooms found'))
                : _buildRoomsTable(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRoomsTable() {
    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 12,
      minWidth: 800,
      columns: [
        DataColumn2(
          label: Text('Room Name'),
          size: ColumnSize.L,
        ),
        DataColumn2(
          label: Text('Campus'),
          size: ColumnSize.S,
        ),
        DataColumn2(
          label: Text('Type'),
          size: ColumnSize.S,
        ),
        DataColumn2(
          label: Text('Capacity'),
          size: ColumnSize.S,
          numeric: true,
        ),
        DataColumn2(
          label: Text('Location'),
          size: ColumnSize.L,
        ),
        DataColumn2(
          label: Text('Status'),
          size: ColumnSize.S,
        ),
        DataColumn2(
          label: Text('Actions'),
          size: ColumnSize.M,
        ),
      ],
      rows: _filteredRooms.map((room) {
        return DataRow(
          cells: [
            DataCell(Text(room.name)),
            DataCell(Text(room.campus)),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(room.type.icon, size: 16, color: primaryColor),
                  SizedBox(width: 4),
                  Text(room.type.displayName),
                ],
              ),
            ),
            DataCell(Text(room.capacity.toString())),
            DataCell(Text(room.location ?? 'N/A')),
            DataCell(
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: room.isAvailable ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  room.isAvailable ? 'Available' : 'Unavailable',
                  style: TextStyle(
                    color: room.isAvailable ? Colors.green.shade800 : Colors.red.shade800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            DataCell(
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.amber),
                    onPressed: () => _showEditRoomDialog(room),
                    tooltip: 'Edit Room',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(room),
                    tooltip: 'Delete Room',
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
  
  void _showDeleteConfirmation(Room room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete "${room.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteRoom(room);
            },
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCapacityTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Campus Capacity Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          SizedBox(height: 16),
          
          // Capacity cards
          _buildCapacityCards(),
          
          SizedBox(height: 32),
          
          // Room breakdown table
          Text(
            'Room Type Breakdown',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          SizedBox(height: 16),
          
          _buildRoomBreakdownTable(),
        ],
      ),
    );
  }
  
  Widget _buildCapacityCards() {
    return Row(
      children: [
        _buildCampusCapacityCard('Taunton'),
        SizedBox(width: 16),
        _buildCampusCapacityCard('Bridgwater'),
        SizedBox(width: 16),
        _buildCampusCapacityCard('Cannington'),
      ],
    );
  }
  
  Widget _buildCampusCapacityCard(String campus) {
    final totalRooms = _roomCounts[campus]?['total'] ?? 0;
    final totalCapacity = _capacityCounts[campus] ?? 0;
    
    return Expanded(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$campus Campus',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildCapacityInfoItem(
                      'Total Rooms',
                      totalRooms.toString(),
                      Icons.meeting_room,
                    ),
                  ),
                  Expanded(
                    child: _buildCapacityInfoItem(
                      'Total Capacity',
                      totalCapacity.toString(),
                      Icons.people,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              LinearProgressIndicator(
                value: totalRooms > 0 ? 1.0 : 0.0,
                backgroundColor: Colors.grey.shade200,
                color: primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCapacityInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 16, color: primaryColor),
            SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildRoomBreakdownTable() {
    return DataTable(
      columns: [
        DataColumn(label: Text('Campus')),
        DataColumn(
          label: Row(
            children: [
              Icon(RoomType.quietRoom.icon, size: 16),
              SizedBox(width: 4),
              Text('Quiet Rooms'),
            ],
          ),
        ),
        DataColumn(
          label: Row(
            children: [
              Icon(RoomType.conferenceRoom.icon, size: 16),
              SizedBox(width: 4),
              Text('Conference Rooms'),
            ],
          ),
        ),
        DataColumn(
          label: Row(
            children: [
              Icon(RoomType.studyRoom.icon, size: 16),
              SizedBox(width: 4),
              Text('Study Rooms'),
            ],
          ),
        ),
        DataColumn(label: Text('Total')),
      ],
      rows: [
        _buildCampusRoomBreakdownRow('Taunton'),
        _buildCampusRoomBreakdownRow('Bridgwater'),
        _buildCampusRoomBreakdownRow('Cannington'),
      ],
    );
  }
  
  DataRow _buildCampusRoomBreakdownRow(String campus) {
    final quietRooms = _roomCounts[campus]?['quiet'] ?? 0;
    final conferenceRooms = _roomCounts[campus]?['conference'] ?? 0;
    final studyRooms = _roomCounts[campus]?['study'] ?? 0;
    final totalRooms = _roomCounts[campus]?['total'] ?? 0;
    
    return DataRow(
      cells: [
        DataCell(Text(campus, style: TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(quietRooms.toString())),
        DataCell(Text(conferenceRooms.toString())),
        DataCell(Text(studyRooms.toString())),
        DataCell(
          Text(
            totalRooms.toString(),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}