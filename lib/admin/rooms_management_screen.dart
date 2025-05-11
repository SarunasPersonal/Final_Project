import 'package:flutter/material.dart';
import 'package:flutter_ucs_app/constants.dart';

class RoomsManagementScreen extends StatefulWidget {
  const RoomsManagementScreen({super.key});

  @override
  State<RoomsManagementScreen> createState() => _RoomsManagementScreenState();
}

class _RoomsManagementScreenState extends State<RoomsManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage Rooms',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'This feature is coming soon. You will be able to configure rooms, set availability, and manage room types here.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 32),
          Center(
            child: Image.asset(
              'assets/logo.png',
              width: 100,
              height: 100,
              color: primaryColor.withAlpha(100),
            ),
          ),
        ],
      ),
    );
  }
}