// lib/admin/admin_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_ucs_app/constants.dart';
import 'package:flutter_ucs_app/admin/dashboard_screen.dart';
import 'package:flutter_ucs_app/admin/bookings_management_screen.dart';
import 'package:flutter_ucs_app/admin/users_management_screen.dart';
import 'package:flutter_ucs_app/admin/rooms_management_screen.dart';
import 'package:flutter_ucs_app/services/firebase_auth_service.dart';
import 'package:flutter_ucs_app/login_screen.dart';
import 'package:provider/provider.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  int _selectedIndex = 0;
  late List<Widget> _screens;
  final String _panelName = 'UCS Admin Panel';

  @override
  void initState() {
    super.initState();
    // Initialize screens - now using all the imported screens
    _screens = [
      const DashboardScreen(),
      const BookingsManagementScreen(),
      const UsersManagementScreen(),  // Using the imported screen
      const RoomsManagementScreen(),  // Using the imported screen
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1000;
    final authService = Provider.of<FirebaseAuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/logo.png', width: 30, height: 30),
            const SizedBox(width: 10),
            Text(_panelName, style: const TextStyle(color: primaryColor)),
          ],
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          // User info
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Admin: ${CurrentUser.email}'),
          ),
          
          // Help button
          IconButton(
            icon: const Icon(Icons.help_outline, color: primaryColor),
            onPressed: () {
              _showHelpDialog(context);
            },
          ),
          
          // Back to app button
          TextButton.icon(
            icon: const Icon(Icons.home, size: 18),
            label: const Text('Back to App'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout, color: primaryColor),
            onPressed: () {
              _showLogoutDialog(context, authService);
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Admin navigation sidebar for desktop
          if (isDesktop)
            NavigationRail(
              extended: true,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              minExtendedWidth: 200,
              backgroundColor: Theme.of(context).cardColor,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.book_online),
                  label: Text('Manage Bookings'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people),
                  label: Text('Manage Users'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.meeting_room),
                  label: Text('Manage Rooms'),
                ),
              ],
              selectedIconTheme: const IconThemeData(color: primaryColor),
              selectedLabelTextStyle: const TextStyle(color: primaryColor),
              unselectedIconTheme: IconThemeData(color: Colors.grey.shade600),
              unselectedLabelTextStyle: TextStyle(color: Colors.grey.shade600),
            )
          // Mobile navigation rail (collapsed)
          else
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: NavigationRailLabelType.selected,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.book_online),
                  label: Text('Bookings'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people),
                  label: Text('Users'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.meeting_room),
                  label: Text('Rooms'),
                ),
              ],
              selectedIconTheme: const IconThemeData(color: primaryColor),
              selectedLabelTextStyle: const TextStyle(color: primaryColor),
            ),
          
          // Admin content area
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
      // Bottom navigation for mobile
      bottomNavigationBar: isDesktop ? null : BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.book_online), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.meeting_room), label: 'Rooms'),
        ],
      ),
    );
  }
  
  // Show help dialog
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Admin Panel Help'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Welcome to the UCS Admin Panel',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 12),
                Text(
                  'This panel allows you to manage all aspects of the booking system:',
                ),
                SizedBox(height: 8),
                Text('• Dashboard: View booking statistics and analytics'),
                Text('• Manage Bookings: View, edit, and delete user bookings'),
                Text('• Manage Users: Add, edit, or remove user accounts'),
                Text('• Manage Rooms: Configure room types and availability'),
                SizedBox(height: 12),
                Text(
                  'For additional help or to report issues, please contact the system administrator.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  
  // Show logout confirmation dialog
  void _showLogoutDialog(BuildContext context, FirebaseAuthService authService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
              onPressed: () {
                // Logout and navigate to login screen
                authService.logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }
}