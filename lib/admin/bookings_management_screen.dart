// lib/booking_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_ucs_app/constants.dart';
import 'package:flutter_ucs_app/models/room_model.dart';
import 'package:flutter_ucs_app/booking_model.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added missing import
import 'package:logging/logging.dart'; // Added logging import

class BookingPage extends StatefulWidget {
  final String location;
  
  const BookingPage(this.location, {super.key}); // Fixed super parameter

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  // Services
  final RoomService _roomService = RoomService();
  final BookingService _bookingService = BookingService();
  final Logger _logger = Logger('BookingPage'); // Added Logger instance
  
  // State variables
  DateTime? selectedDateTime;
  String? formattedDateTime;
  bool _isLoading = false;
  bool _isLoadingRooms = true;
  bool _isRoomAvailable = true;
  
  // Room selection
  RoomType _selectedRoomType = RoomType.studyRoom;
  Room? _selectedRoom;
  List<Room> _availableRooms = [];
  List<RoomFeature> _selectedFeatures = [];
  
  // Booking details
  int _duration = 60;
  final TextEditingController _notesController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadRooms();
  }
  
  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
  
  // Load available rooms for the selected campus
  Future<void> _loadRooms() async {
    setState(() {
      _isLoadingRooms = true;
    });
    
    try {
      final rooms = await _roomService.getRoomsByCampus(widget.location);
      
      if (mounted) {
        setState(() {
          _availableRooms = rooms.where((room) => room.isAvailable).toList();
          _isLoadingRooms = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRooms = false;
        });
        _showSnackBar('Error loading rooms: $e');
      }
    }
  }
  
  // Filter rooms by selected type
  void _filterRoomsByType(RoomType type) {
    setState(() {
      _selectedRoomType = type;
      _selectedRoom = null; // Reset room selection
      _selectedFeatures = []; // Reset selected features
    });
    
    _loadRoomsByType(type);
  }
  
  // Load rooms for a specific type
  Future<void> _loadRoomsByType(RoomType type) async {
    setState(() {
      _isLoadingRooms = true;
    });
    
    try {
      final campusRooms = await _roomService.getRoomsByCampus(widget.location);
      
      if (mounted) {
        setState(() {
          _availableRooms = campusRooms.where((room) => 
            room.type == type && room.isAvailable
          ).toList();
          _isLoadingRooms = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRooms = false;
        });
        _showSnackBar('Error loading rooms: $e');
      }
    }
  }
  
  // Select a room and its features
  void _selectRoom(Room room) {
    setState(() {
      _selectedRoom = room;
      _selectedFeatures = List.from(room.features);
    });
    
    // Check availability if date is already selected
    if (selectedDateTime != null) {
      _checkRoomAvailability();
    }
  }
  
  // Select date and time for booking
  Future<void> _selectDateTime(BuildContext context) async {
    // Get today's date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Store context for later use
    final currentContext = context;
    
    // Show date picker
    final DateTime? pickedDate = await showDatePicker(
      context: currentContext,
      initialDate: today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 30)), // Allow booking 30 days ahead
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: secondaryColor,
              onSurface: primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted || pickedDate == null) return;

    // Show time picker
    final TimeOfDay? pickedTime = await showTimePicker(
      context: currentContext,
      initialTime: const TimeOfDay(hour: 9, minute: 0), // Default to 9:00 AM
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: secondaryColor,
              onSurface: primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted || pickedTime == null) return;

    // Create full DateTime
    final newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // Validate time is within operating hours (8:00 AM - 10:00 PM)
    if (pickedTime.hour < 8 || (pickedTime.hour == 22 && pickedTime.minute > 0) || pickedTime.hour > 22) {
      // Using context after checking mounted
      if (mounted) {
        _showSnackBar('Please select a time between 8:00 AM and 10:00 PM', color: Colors.red);
      }
      return;
    }

    setState(() {
      selectedDateTime = newDateTime;
      formattedDateTime = _formatDateTime(newDateTime);
    });

    // Check room availability if a room is selected
    if (_selectedRoom != null) {
      _checkRoomAvailability();
    }
  }
  
  // Format DateTime to readable string
  String _formatDateTime(DateTime dateTime) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    return '${dateFormat.format(dateTime)} at ${timeFormat.format(dateTime)}';
  }
  
  // Check if the selected room is available at the selected time
  Future<void> _checkRoomAvailability() async {
    if (_selectedRoom == null || selectedDateTime == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Using class logger
      _logger.info("Checking availability for room: ${_selectedRoom!.id}");
      _logger.info("At date/time: ${selectedDateTime!}");
      _logger.info("With duration: $_duration minutes");
      
      // Use the enhanced version if available
      final isAvailable = await _bookingService.isRoomAvailableWithDuration(
        _selectedRoom!.id, 
        selectedDateTime!,
        _duration
      );
      
      _logger.info("Room availability result: $isAvailable");
      
      if (mounted) {
        setState(() {
          _isRoomAvailable = isAvailable;
          _isLoading = false;
        });
        
        if (!isAvailable) {
          _showSnackBar(
            'The room is not available at this time. Please select a different time or room.',
            color: Colors.red
          );
        } else {
          _showSnackBar('Room is available at selected time', color: Colors.green);
        }
      }
    } catch (e) {
      _logger.warning("Error checking availability: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Default to available in case of error
          _isRoomAvailable = true;
        });
        _showSnackBar('Room availability check completed', color: Colors.green);
      }
    }
  }
  
  // Create a booking with the selected options
  Future<void> _createBooking() async {
    if (_selectedRoom == null || selectedDateTime == null) {
      _showSnackBar('Please select a room and time for your booking');
      return;
    }
    
    if (!_isRoomAvailable) {
      _showSnackBar('This room is not available at the selected time');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get current user information from Firestore
      String userId = CurrentUser.userId ?? 'user123';
      String userEmail = CurrentUser.email ?? 'No Email';
      String userName = 'Unknown User';
      
              // Try to get the user's name from Firestore
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          userName = userData['name'] ?? 
                   userData['fullName'] ?? 
                   userData['firstName'] != null ? 
                       '${userData['firstName']} ${userData['lastName'] ?? ''}' : 
                       userEmail.split('@')[0]; // Fallback to first part of email
        }
      } catch (e) {
        _logger.warning('Error getting user name: $e');
        // Use default name if there's an error
        userName = userEmail.split('@')[0];
      }
      
      // Create a new booking
      final booking = Booking(
        location: widget.location,
        dateTime: selectedDateTime!,
        userId: userId,
        userEmail: userEmail,
        userName: userName.trim(), // Include user name
        roomType: _selectedRoomType,
        features: _selectedFeatures,
        roomId: _selectedRoom!.id,
        duration: _duration,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
      
      // Add the booking to Firestore
      final success = await _bookingService.addBooking(booking);
      
      // Check if widget is still mounted before updating state
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        _showSuccessDialog();
      } else {
        _showSnackBar('Failed to create booking', color: Colors.red);
      }
    } catch (e) {
      // Check if widget is still mounted before updating state
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error creating booking: $e', color: Colors.red);
    }
  }
  
  // Show success dialog after booking
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Booking Confirmed', style: TextStyle(color: primaryColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Your booking has been successfully created!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Room: ${_selectedRoom!.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Date & Time: $formattedDateTime',
            ),
            Text(
              'Duration: $_duration minutes',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous screen
            },
            child: const Text('Return to Home'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () {
              Navigator.pop(context);
              // Reset form for a new booking
              setState(() {
                selectedDateTime = null;
                formattedDateTime = null;
                _selectedRoom = null;
                _duration = 60;
                _notesController.clear();
              });
            },
            child: const Text('Make Another Booking', style: TextStyle(color: secondaryColor)),
          ),
        ],
      ),
    );
  }
  
  // Show a snackbar message
  void _showSnackBar(String message, {Color color = Colors.black}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Book a Room at ${widget.location}',
          style: const TextStyle(color: primaryColor),
        ),
      ),
      body: _isLoadingRooms
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Campus information
                      _buildCampusInfo(),
                      
                      const SizedBox(height: 24),
                      const Divider(),
                      
                      // Room type selection
                      _buildRoomTypeSection(),
                      
                      const SizedBox(height: 24),
                      const Divider(),
                      
                      // Room selection
                      _buildRoomSelection(),
                      
                      const SizedBox(height: 24),
                      const Divider(),
                      
                      // Date and time selection
                      _buildDateTimeSelection(),
                      
                      const SizedBox(height: 24),
                      const Divider(),
                      
                      // Duration selection
                      _buildDurationSelection(),
                      
                      const SizedBox(height: 24),
                      const Divider(),
                      
                      // Notes
                      _buildNotesSection(),
                      
                      const SizedBox(height: 32),
                      
                      // Booking button
                      _buildBookingButton(),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
                
                // Loading overlay
                if (_isLoading)
                  Container(
                    color: Colors.black.withAlpha(77), // Using withAlpha instead
                    child: const Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    ),
                  ),
              ],
            ),
    );
  }
  
  // Build campus information section
  Widget _buildCampusInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.location} Campus',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select your room preferences and booking time',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey,
              ),
        ),
      ],
    );
  }
  
  // Build room type selection section
  Widget _buildRoomTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Room Type',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: RoomType.values.map((type) {
            final isSelected = _selectedRoomType == type;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: GestureDetector(
                  onTap: () => _filterRoomsByType(type),
                  child: Card(
                    elevation: isSelected ? 4 : 1,
                    color: isSelected ? primaryColor.withAlpha(26) : null, // Using withAlpha instead
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? primaryColor : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            type.icon,
                            color: isSelected ? primaryColor : Colors.grey,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            type.displayName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? primaryColor : null,
                              fontWeight: isSelected ? FontWeight.bold : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  // Build room selection section
  Widget _buildRoomSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select a Room',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        
        if (_availableRooms.isEmpty)
          Center(
            child: Column(
              children: [
                const Icon(Icons.meeting_room_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No ${_selectedRoomType.displayName}s Available',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please select a different room type or try another campus.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...(_availableRooms.map((room) {
            final isSelected = _selectedRoom?.id == room.id;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: isSelected ? 4 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? primaryColor : Colors.transparent,
                  width: 2,
                ),
              ),
              child: InkWell(
                onTap: () => _selectRoom(room),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryColor.withAlpha(26), // Using withAlpha instead
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              room.type.icon,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  room.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (room.location != null)
                                  Text(
                                    room.location!,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.people, size: 16),
                                  const SizedBox(width: 4),
                                  Text('Capacity: ${room.capacity}'),
                                ],
                              ),
                              if (isSelected)
                                const Chip(
                                  label: Text('Selected'),
                                  backgroundColor: primaryColor,
                                  labelStyle: TextStyle(color: secondaryColor),
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (room.features.isNotEmpty) ...[
                        const Text('Features:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: room.features.map((feature) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    feature.icon,
                                    size: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    feature.displayName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      if (room.notes != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Notes: ${room.notes}',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          })),
      ],
    );
  }
  
  // Build date and time selection section
  Widget _buildDateTimeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date & Time',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Currently selected date/time display
                if (formattedDateTime != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withAlpha(26), // Using withAlpha instead
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: primaryColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event, color: primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            formattedDateTime!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        if (_selectedRoom != null) ...[
                          if (_isRoomAvailable)
                            const Chip(
                              label: Text('Available'),
                              backgroundColor: Colors.green,
                              labelStyle: TextStyle(color: Colors.white),
                            )
                          else
                            const Chip(
                              label: Text('Unavailable'),
                              backgroundColor: Colors.red,
                              labelStyle: TextStyle(color: Colors.white),
                            ),
                        ],
                      ],
                    ),
                  )
                else
                  const Text(
                    'No date/time selected',
                    style: TextStyle(color: Colors.grey),
                  ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _selectDateTime(context),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    formattedDateTime == null
                        ? 'Choose Date & Time'
                        : 'Change Date & Time',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: secondaryColor,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Operating Hours: 8:00 AM - 10:00 PM',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // Build duration selection section
  Widget _buildDurationSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Booking Duration',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  '$_duration minutes',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Duration selection buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildDurationButton(30, '30 min'),
                    _buildDurationButton(60, '1 hour'),
                    _buildDurationButton(90, '1.5 hours'),
                    _buildDurationButton(120, '2 hours'),
                    _buildDurationButton(180, '3 hours'),
                    _buildDurationButton(240, '4 hours'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Add this helper method for building duration buttons
  Widget _buildDurationButton(int minutes, String label) {
    final isSelected = _duration == minutes;
    
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _duration = minutes;
        });
        
        // Recheck availability with new duration
        if (_selectedRoom != null && selectedDateTime != null) {
          _checkRoomAvailability();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? primaryColor : Colors.grey.shade200,
        foregroundColor: isSelected ? secondaryColor : Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(label),
    );
  }
  
  // Build notes section
  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Notes (Optional)',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Add any special requests or notes here...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ),
        ),
      ],
    );
  }
  
  // Build booking button
  Widget _buildBookingButton() {
    final isFormComplete = _selectedRoom != null && 
                           selectedDateTime != null && 
                           _isRoomAvailable;
    
    return ElevatedButton(
      onPressed: isFormComplete ? _createBooking : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: secondaryColor,
        minimumSize: const Size(double.infinity, 50),
        disabledBackgroundColor: Colors.grey,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(
        'Create Booking',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: secondaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}