import 'package:flutter/material.dart';
import 'package:flutter_ucs_app/constants.dart';
import 'package:flutter_ucs_app/booking_model.dart';
import 'package:intl/intl.dart';

class BookingPage extends StatefulWidget {
  final String location;
  const BookingPage(this.location, {super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? selectedDateTime;
  String? formattedDateTime;
  final BookingService _bookingService = BookingService();
  bool _isLoading = false;
  
  // Room selection
  RoomType _selectedRoomType = RoomType.quietRoom;
  final Map<RoomFeature, bool> _selectedFeatures = {
    for (var feature in RoomFeature.values) feature: false
  };

  // Focus nodes for improved keyboard navigation
  final FocusNode _roomTypeFocusNode = FocusNode();
  final FocusNode _featuresFocusNode = FocusNode();
  final FocusNode _dateTimeFocusNode = FocusNode();
  final FocusNode _confirmButtonFocusNode = FocusNode();

  @override
  void dispose() {
   final nodes = [
      _roomTypeFocusNode, 
      _featuresFocusNode, 
      _dateTimeFocusNode, 
      _confirmButtonFocusNode
    ];
    
    for (final node in nodes) {
      node.dispose();
    }
    
    super.dispose();
  }

  void _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026),
      builder: (context, child) => _buildDateTimePickerTheme(context, child, 'Date picker for booking'),
    );

    if (!context.mounted || pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => _buildDateTimePickerTheme(context, child, 'Time picker for booking'),
    );

    if (!context.mounted || pickedTime == null) return;

    final newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    
    setState(() {
      selectedDateTime = newDateTime;
      formattedDateTime = _formatDateTime(newDateTime);
    });
    
    _showSnackBar('Selected date and time: $formattedDateTime');
  }

  Widget _buildDateTimePickerTheme(BuildContext context, Widget? child, String label) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: primaryColor,
          onPrimary: secondaryColor,
          onSurface: primaryColor,
        ),
      ),
      child: Semantics(
        label: label,
        hint: 'Select a ${label.contains('Date') ? 'date' : 'time'} for your booking',
        child: child!,
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    return '${dateFormat.format(dateTime)} at ${timeFormat.format(dateTime)}';
  }

  void _showConfirmationDialog() {
    if (selectedDateTime == null) {
      _showSnackBar('Please select a date and time');
      return;
    }

    final List<RoomFeature> features = _getSelectedFeatures();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Booking'),
          content: SingleChildScrollView(
            child: Semantics(
              label: 'Booking confirmation details',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                      children: [
                        const TextSpan(text: 'Are you sure you want to book a '),
                        _highlightText(_selectedRoomType.displayName),
                        const TextSpan(text: ' at '),
                        _highlightText(widget.location),
                        const TextSpan(text: ' for '),
                        _highlightText(formattedDateTime ?? ''),
                        const TextSpan(text: '?'),
                      ],
                    ),
                  ),
                  
                  if (features.isNotEmpty) ..._buildFeaturesList(features),
                ],
              ),
            ),
          ),
          actions: [
            _buildDialogButton('Cancel', () => Navigator.of(dialogContext).pop(), Colors.grey),
            _buildDialogButton('Confirm', () {
              Navigator.of(dialogContext).pop();
              _confirmBooking();
            }, primaryColor),
          ],
        );
      },
    );
  }

  TextSpan _highlightText(String text) {
    return TextSpan(
      text: text,
      style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
    );
  }

  List<Widget> _buildFeaturesList(List<RoomFeature> features) {
    return [
      const SizedBox(height: 16),
      const Text(
        'With the following features:',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      ...features.map((feature) => Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Semantics(
          label: feature.displayName,
          child: Row(
            children: [
              Icon(feature.icon, size: 16, color: primaryColor),
              const SizedBox(width: 8),
              Text(feature.displayName),
            ],
          ),
        ),
      )),
    ];
  }

  Widget _buildDialogButton(String label, VoidCallback onPressed, Color color) {
    return Semantics(
      button: true,
      label: '$label button',
      child: TextButton(
        onPressed: onPressed,
        child: Text(label, style: TextStyle(color: color)),
      ),
    );
  }

  List<RoomFeature> _getSelectedFeatures() {
    return _selectedFeatures.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  void _confirmBooking() async {
    setState(() => _isLoading = true);

    try {
      final List<RoomFeature> features = _getSelectedFeatures();
          
      // Create a new booking
      final newBooking = Booking(
        location: widget.location,
        dateTime: selectedDateTime!,
        userId: CurrentUser.userId ?? 'unknown',
        roomType: _selectedRoomType,
        features: features,
      );
      
      _bookingService.addBooking(newBooking);
      
      if (!mounted) return;
      
      _showSnackBar(
        '${_selectedRoomType.displayName} booking confirmed at ${widget.location} on $formattedDateTime',
        color: Colors.green,
        duration: const Duration(seconds: 4),
      );
      
      // Navigate back after successful booking
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        Navigator.pop(context);
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error: ${e.toString()}', color: Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {Color color = Colors.black, Duration? duration}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color != Colors.black ? color : null,
        duration: duration ?? const Duration(seconds: 2),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Semantics(
            label: 'Help dialog',
            child: const Text('Booking Help'),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                  'How to book a room:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                _buildHelpItem('1. Select a room type (Quiet Room, Conference Room, or Study Room)'),
                _buildHelpItem('2. Choose required features for your room (for Conference and Study rooms)'),
                _buildHelpItem('3. Select a date and time for your booking'),
                _buildHelpItem('4. Review and confirm your booking details'),
                const SizedBox(height: 10),
                const Text(
                  'Accessibility Features:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                _buildHelpItem('• All elements are labeled for screen readers'),
                _buildHelpItem('• Use your device\'s screen reader to navigate through the booking process'),
                _buildHelpItem('• Keyboard navigation is fully supported'),
              ],
            ),
          ),
          actions: <Widget>[
            Semantics(
              button: true,
              label: 'Close help dialog',
              child: TextButton(
                child: const Text('CLOSE'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  void _resetFeatures() {
    _selectedFeatures.forEach((key, _) => _selectedFeatures[key] = false);
  }
  
  IconData _getIconForLocation(String location) {
    switch (location) {
      case 'Taunton': return Icons.school;
      case 'Bridgwater': return Icons.account_balance;
      case 'Cannington': return Icons.park;
      default: return Icons.location_on;
    }
  }
  
  String _getAddressForLocation(String location) {
    switch (location) {
      case 'Taunton': return 'Wellington Road, Taunton, TA1 5AX';
      case 'Bridgwater': return 'Bath Road, Bridgwater, TA6 4PZ';
      case 'Cannington': return 'Rodway, Cannington, Bridgwater, TA5 2LS';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: Semantics(
          button: true,
          label: 'Back button',
          hint: 'Return to previous screen',
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: primaryColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Booking - ${widget.location}',
          style: const TextStyle(color: primaryColor),
        ),
        actions: [
          Semantics(
            button: true,
            label: 'Help button',
            hint: 'Get help with booking process',
            child: IconButton(
              icon: const Icon(Icons.help_outline, color: primaryColor),
              onPressed: _showHelpDialog,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocationHeader(),
              const SizedBox(height: 30),
              
              // Room Type Selection
              _buildSectionHeader('Select Room Type'),
              const SizedBox(height: 15),
              
              _buildRoomTypeSelector(),
              
              // Room Features (only visible for conference and study rooms)
              if (_selectedRoomType != RoomType.quietRoom) _buildRoomFeatures(),
              
              const SizedBox(height: 30),
              _buildSectionHeader('Select Date & Time'),
              const SizedBox(height: 10),
              
              const Text(
                'Please select a date and time for your appointment:',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              _buildDateTimeSelector(),
              
              if (selectedDateTime != null) _buildSelectedDateTime(),
              
              const SizedBox(height: 40),
              _buildConfirmButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campus image placeholder
        Semantics(
          label: '${widget.location} Campus image',
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: primaryColor.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: ExcludeSemantics(
                child: Icon(
                  _getIconForLocation(widget.location),
                  color: primaryColor,
                  size: 80,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Semantics(
          label: 'Location',
          child: Text(
            '${widget.location} Campus',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          label: 'Address',
          child: Text(
            _getAddressForLocation(widget.location),
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Semantics(
      header: true,
      label: '$title Section',
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }

  Widget _buildRoomTypeSelector() {
    return Focus(
      focusNode: _roomTypeFocusNode,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: RoomType.values.map((type) => _buildRoomTypeOption(type)).toList(),
        ),
      ),
    );
  }

  Widget _buildRoomTypeOption(RoomType type) {
    final String subtitle = type == RoomType.quietRoom 
        ? 'Individual space for focused work'
        : type == RoomType.conferenceRoom 
            ? 'Meeting space for groups' 
            : 'Collaborative space for study groups';
    
    return RadioListTile<RoomType>(
      title: Semantics(
        label: '${type.displayName} option',
        child: Row(
          children: [
            Icon(type.icon, color: primaryColor),
            const SizedBox(width: 10),
            Text(type.displayName),
          ],
        ),
      ),
      subtitle: Text(subtitle),
      value: type,
      groupValue: _selectedRoomType,
      activeColor: primaryColor,
      onChanged: (RoomType? value) {
        if (value != null) {
          setState(() {
            _selectedRoomType = value;
            if (value == RoomType.quietRoom) {
              _resetFeatures();
            }
          });
          
          _showSnackBar('Selected ${value.displayName}', duration: const Duration(seconds: 1));
        }
      },
    );
  }

  Widget _buildRoomFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 25),
        _buildSectionHeader('Room Features'),
        const SizedBox(height: 10),
        
        Focus(
          focusNode: _featuresFocusNode,
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: RoomFeature.values.map((feature) => _buildFeatureOption(feature)).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureOption(RoomFeature feature) {
    return CheckboxListTile(
      title: Semantics(
        label: '${feature.displayName} feature',
        child: Row(
          children: [
            Icon(feature.icon, color: primaryColor),
            const SizedBox(width: 10),
            Text(feature.displayName),
          ],
        ),
      ),
      value: _selectedFeatures[feature],
      activeColor: primaryColor,
      onChanged: (bool? value) {
        if (value != null) {
          setState(() {
            _selectedFeatures[feature] = value;
          });
          
          _showSnackBar(
            value ? 'Added ${feature.displayName}' : 'Removed ${feature.displayName}',
            duration: const Duration(seconds: 1),
          );
        }
      },
    );
  }

  Widget _buildDateTimeSelector() {
    return Focus(
      focusNode: _dateTimeFocusNode,
      child: Semantics(
        button: true,
        label: 'Select date and time button',
        hint: 'Tap to open date and time pickers',
        child: ElevatedButton.icon(
          icon: const Icon(Icons.calendar_today, color: secondaryColor),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () => _selectDateTime(context),
          label: Text(
            selectedDateTime == null ? 'Select Date & Time' : 'Change Date & Time',
            style: const TextStyle(color: secondaryColor),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDateTime() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        _buildSectionHeader('Selected Date & Time'),
        const SizedBox(height: 10),
        Semantics(
          label: 'Currently selected date and time',
          value: formattedDateTime,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withAlpha(26),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primaryColor.withAlpha(128)),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_available, color: primaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    formattedDateTime!,
                    style: const TextStyle(fontSize: 16, color: primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return Focus(
      focusNode: _confirmButtonFocusNode,
      child: Semantics(
        button: true,
        label: 'Confirm booking button',
        hint: 'Tap to review and confirm your booking details',
        enabled: !_isLoading,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.check_circle, color: secondaryColor),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: _isLoading ? null : _showConfirmationDialog,
          label: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: secondaryColor,
                    strokeWidth: 2,
                    semanticsLabel: 'Loading indicator',
                  ),
                )
              : const Text(
                  'Confirm Booking',
                  style: TextStyle(color: secondaryColor, fontSize: 16),
                ),
        ),
      ),
    );
  }
}