// lib/my_bookings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_ucs_app/constants.dart';
import 'package:flutter_ucs_app/models/room_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_ucs_app/admin/models/current_user.dart' as admin;
import 'package:flutter_ucs_app/booking_model.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  final BookingService _bookingService = BookingService();
  List<Booking> userBookings = [];
  bool _isLoading = true; // Add loading state

  @override
  void initState() {
    super.initState();
    _loadUserBookings();
  }

  // Updated to use async Firebase calls
  Future<void> _loadUserBookings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (CurrentUser.userId != null) {
        // Get bookings from Firebase
        final bookings = await _bookingService.getUserBookings(CurrentUser.userId!);
        
        if (mounted) {
          setState(() {
            userBookings = bookings;
            _isLoading = false;
          });
        }
      } else {
        // Handle case where no user is logged in
        if (mounted) {
          setState(() {
            userBookings = [];
            _isLoading = false;
          });
          
          _showSnackBar('No user logged in. Please log in to view your bookings.', 
              color: Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Error loading bookings: $e', color: Colors.red);
      }
    }
  }

  // Format a DateTime object into a readable string
  String _formatDateTime(DateTime dateTime) {
    final dateFormat = DateFormat('EEE, MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    return '${dateFormat.format(dateTime)} at ${timeFormat.format(dateTime)}';
  }

  // Get an icon based on the booking location
  IconData _getIconForLocation(String location) {
    switch (location) {
      case 'Taunton':
        return Icons.school;
      case 'Bridgwater':
        return Icons.account_balance;
      case 'Cannington':
        return Icons.park;
      default:
        return Icons.location_on;
    }
  }

  // Show a confirmation dialog and delete a booking if confirmed
  void _deleteBooking(Booking booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: const Text('Are you sure you want to cancel this booking?'),
          actions: [
            // Cancel button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('NO', style: TextStyle(color: Colors.grey)),
            ),
            // Confirm button
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                setState(() => _isLoading = true);
                
                try {
                  // Updated to use async Firebase delete
                  bool success = await _bookingService.deleteBooking(
                    booking.location, 
                    booking.dateTime, 
                    booking.roomType
                  );
                  
                  if (mounted) {
                    if (success) {
                      _showSnackBar('Booking cancelled successfully', 
                          color: Colors.green);
                      // Reload bookings after deletion
                      await _loadUserBookings();
                    } else {
                      _showSnackBar('Failed to cancel booking', 
                          color: Colors.red);
                      setState(() => _isLoading = false);
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    _showSnackBar('Error: $e', color: Colors.red);
                    setState(() => _isLoading = false);
                  }
                }
              },
              child: const Text('YES', style: TextStyle(color: primaryColor)),
            ),
          ],
        );
      },
    );
  }
  
  // Show a snackbar message
  void _showSnackBar(String message, {Color color = Colors.black}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
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
          onPressed: () => Navigator.pop(context), // Navigate back
        ),
        title: const Text(
          'My Bookings',
          style: TextStyle(color: primaryColor),
        ),
        actions: [
          // Add a refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: primaryColor),
            onPressed: _loadUserBookings,
            tooltip: 'Refresh bookings',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: userBookings.isEmpty
                  ? _buildEmptyState() // Show empty state if no bookings
                  : _buildBookingsList(), // Show bookings list otherwise
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () => Navigator.pop(context), // Navigate back to booking page
        child: const Icon(Icons.add, color: secondaryColor),
        tooltip: 'Book a new room',
      ),
    );
  }

  // Build the UI for the empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.calendar_today,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text(
            'No bookings found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'You haven\'t made any bookings yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => Navigator.pop(context), // Navigate back
            child: const Text(
              'Book Now',
              style: TextStyle(color: secondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  // Build the list of bookings
  Widget _buildBookingsList() {
    // Sort bookings with upcoming first, then by date
    final now = DateTime.now();
    userBookings.sort((a, b) {
      // Sort by upcoming/past first
      bool aIsUpcoming = a.dateTime.isAfter(now);
      bool bIsUpcoming = b.dateTime.isAfter(now);
      
      if (aIsUpcoming && !bIsUpcoming) return -1;
      if (!aIsUpcoming && bIsUpcoming) return 1;
      
      // Then sort by date (most recent first for upcoming, oldest first for past)
      return aIsUpcoming 
          ? a.dateTime.compareTo(b.dateTime)  // Ascending for upcoming
          : b.dateTime.compareTo(a.dateTime); // Descending for past
    });
  
    return ListView.builder(
      itemCount: userBookings.length,
      itemBuilder: (context, index) {
        final booking = userBookings[index];
        final formattedDateTime = _formatDateTime(booking.dateTime);
        final isUpcoming = booking.dateTime.isAfter(DateTime.now());

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isUpcoming
                  ? primaryColor.withAlpha(77)
                  : Colors.grey.withAlpha(77),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildLocationIcon(
                        booking.location, isUpcoming), // Location icon
                    const SizedBox(width: 16),
                    _buildBookingDetails(booking, formattedDateTime,
                        isUpcoming), // Booking details
                    if (isUpcoming)
                      IconButton(
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () =>
                            _deleteBooking(booking), // Delete booking
                      ),
                  ],
                ),

                // Show room features if any exist
                if (booking.features.isNotEmpty)
                  _buildFeaturesList(booking.features, isUpcoming),

                const SizedBox(height: 16),
                _buildStatusBanner(isUpcoming), // Status banner
              ],
            ),
          ),
        );
      },
    );
  }

  // Build the location icon widget
  Widget _buildLocationIcon(String location, bool isUpcoming) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:
            isUpcoming ? primaryColor.withAlpha(26) : Colors.grey.withAlpha(26),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        _getIconForLocation(location),
        color: isUpcoming ? primaryColor : Colors.grey,
        size: 30,
      ),
    );
  }

  // Build the booking details widget
  Widget _buildBookingDetails(
      Booking booking, String formattedDateTime, bool isUpcoming) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${booking.location} Campus',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isUpcoming ? primaryColor : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                booking.roomType.icon,
                size: 16,
                color: isUpcoming ? primaryColor : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                booking.roomType.displayName,
                style: TextStyle(
                  fontSize: 14,
                  color: isUpcoming ? Colors.black87 : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            formattedDateTime,
            style: TextStyle(
              fontSize: 14,
              color: isUpcoming ? Colors.black87 : Colors.grey,
            ),
          ),
          // Add duration info
          if (booking.duration > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Duration: ${booking.duration} minutes',
              style: TextStyle(
                fontSize: 14,
                color: isUpcoming ? Colors.black87 : Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Build the list of room features
  Widget _buildFeaturesList(List<RoomFeature> features, bool isUpcoming) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: features.map((feature) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isUpcoming ? Colors.blue.shade50 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                feature.icon,
                size: 16,
                color: isUpcoming ? Colors.blue.shade700 : Colors.grey.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                feature.displayName,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isUpcoming ? Colors.blue.shade700 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Build the status banner widget
  Widget _buildStatusBanner(bool isUpcoming) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color:
            isUpcoming ? primaryColor.withAlpha(26) : Colors.grey.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isUpcoming ? 'Upcoming Booking' : 'Past Booking',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isUpcoming ? primaryColor : Colors.grey,
        ),
      ),
    );
  }
}