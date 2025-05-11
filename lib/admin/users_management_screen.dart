import 'package:flutter/material.dart';
import 'package:flutter_ucs_app/constants.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage Users',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'This feature is coming soon. You will be able to add, edit, and manage user accounts here.',
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