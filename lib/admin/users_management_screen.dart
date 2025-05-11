// lib/admin/users_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_ucs_app/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final logger = Logger('UsersManagementScreen');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<UserData> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isAdmin = false;
  
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Directly create a sample list with current user
      final currentUser = _auth.currentUser;
      List<UserData> users = [];
      
      if (currentUser != null) {
        // Add current user as admin
        users.add(UserData(
          id: currentUser.uid,
          name: currentUser.displayName ?? 'Admin User',
          email: currentUser.email ?? 'No Email',
          role: 'Admin',
          isCurrentUser: true,
        ));
        
        // Ensure admin status in Firestore
        await _firestore.collection('admin_users').doc(currentUser.uid).set({
          'role': 'admin',
          'email': currentUser.email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      // Fetch any additional users from Firestore
      final QuerySnapshot userSnapshot = await _firestore.collection('users').get();
      
      // Get admin users
      final QuerySnapshot adminSnapshot = await _firestore.collection('admin_users').get();
      final Set<String> adminIds = adminSnapshot.docs.map((doc) => doc.id).toSet();
      
      // Add all users from Firestore
      for (var doc in userSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String userId = doc.id;
        
        // Skip if this is the current user (already added)
        if (userId == currentUser?.uid) continue;
        
        final bool isAdmin = adminIds.contains(userId);
        
        users.add(UserData(
          id: userId,
          name: data['name'] ?? 'User',
          email: data['email'] ?? 'No Email',
          role: isAdmin ? 'Admin' : 'Regular User',
          isCurrentUser: false,
        ));
      }
      
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
        
        // If no additional users beyond current admin, show message
        if (users.length <= 1) {
          _showSnackBar('Only admin account detected. Add test users with the + button.');
        }
      }
    } catch (e) {
      logger.warning('Error loading users: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Error: ${e.toString()}');
      }
    }
  }
  
  Future<void> _addTestUsers() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Add some test users directly to Firestore (not creating actual Auth accounts)
      final List<Map<String, dynamic>> testUsers = [
        {
          'name': 'John Smith',
          'email': 'john.smith@example.com',
          'role': 'Regular User',
        },
        {
          'name': 'Jane Doe',
          'email': 'jane.doe@example.com',
          'role': 'Regular User',
        },
        {
          'name': 'Mike Johnson',
          'email': 'mike.johnson@example.com',
          'role': 'Regular User',
        },
      ];
      
      // Add each test user to Firestore
      for (var user in testUsers) {
        final docRef = await _firestore.collection('users').add({
          'name': user['name'],
          'email': user['email'],
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Make one of them an admin
        if (user['name'] == 'Jane Doe') {
          await _firestore.collection('admin_users').doc(docRef.id).set({
            'role': 'admin',
            'email': user['email'],
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
      
      _showSnackBar('Test users added successfully');
      await _loadUsers(); // Reload users
    } catch (e) {
      logger.warning('Error adding test users: $e');
      _showSnackBar('Error adding test users: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _createUser() async {
    // Reset form
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _isAdmin = false;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add New User'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Admin User'),
                    value: _isAdmin,
                    onChanged: (value) {
                      setState(() {
                        _isAdmin = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                ),
                onPressed: () {
                  if (_validateForm()) {
                    Navigator.pop(context);
                    _addUserToFirestore();
                  }
                },
                child: const Text(
                  'Create User',
                  style: TextStyle(color: secondaryColor),
                ),
              ),
            ],
          );
        }
      ),
    );
  }
  
  bool _validateForm() {
    if (_nameController.text.isEmpty) {
      _showSnackBar('Please enter a name');
      return false;
    }
    
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _showSnackBar('Please enter a valid email');
      return false;
    }
    
    return true;
  }
  
  Future<void> _addUserToFirestore() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Add user to Firestore
      final docRef = await _firestore.collection('users').add({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // If admin, add to admin_users collection
      if (_isAdmin) {
        await _firestore.collection('admin_users').doc(docRef.id).set({
          'role': 'admin',
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      _showSnackBar('User added successfully');
      await _loadUsers();
    } catch (e) {
      logger.warning('Error adding user: $e');
      _showSnackBar('Error: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _editUser(UserData user) async {
    // Populate form
    _nameController.text = user.name;
    _emailController.text = user.email;
    _isAdmin = user.role.contains('Admin');
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit User'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    enabled: false, // Email can't be changed
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Admin User'),
                    value: _isAdmin,
                    onChanged: (value) {
                      setState(() {
                        _isAdmin = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _updateUserInFirestore(user.id);
                },
                child: const Text(
                  'Update User',
                  style: TextStyle(color: secondaryColor),
                ),
              ),
            ],
          );
        }
      ),
    );
  }
  
  Future<void> _updateUserInFirestore(String userId) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Update user in Firestore
      await _firestore.collection('users').doc(userId).update({
        'name': _nameController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Handle admin status
      final docSnapshot = await _firestore.collection('admin_users').doc(userId).get();
      final bool isCurrentlyAdmin = docSnapshot.exists;
      
      if (_isAdmin && !isCurrentlyAdmin) {
        // Add to admin_users
        await _firestore.collection('admin_users').doc(userId).set({
          'role': 'admin',
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else if (!_isAdmin && isCurrentlyAdmin) {
        // Remove from admin_users
        await _firestore.collection('admin_users').doc(userId).delete();
      }
      
      _showSnackBar('User updated successfully');
      await _loadUsers();
    } catch (e) {
      logger.warning('Error updating user: $e');
      _showSnackBar('Error: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _deleteUser(UserData user) async {
    if (user.isCurrentUser) {
      _showSnackBar("You can't delete your own account");
      return;
    }
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Delete user "${user.name}" (${user.email})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUserFromFirestore(user.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteUserFromFirestore(String userId) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Check if admin and remove if needed
      final adminDoc = await _firestore.collection('admin_users').doc(userId).get();
      if (adminDoc.exists) {
        await _firestore.collection('admin_users').doc(userId).delete();
      }
      
      // Delete user from Firestore
      await _firestore.collection('users').doc(userId).delete();
      
      _showSnackBar('User deleted successfully');
      await _loadUsers();
    } catch (e) {
      logger.warning('Error deleting user: $e');
      _showSnackBar('Error: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

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
          const SizedBox(height: 24),
          
          // Search and actions bar
          Row(
            children: [
              // Search field
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              
              // Add user button
              ElevatedButton.icon(
                icon: const Icon(Icons.add, color: secondaryColor),
                label: const Text('Add User', style: TextStyle(color: secondaryColor)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: _createUser,
              ),
              
              // Add test users button
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.group_add),
                tooltip: 'Add Test Users',
                onPressed: _addTestUsers,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Users table
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: primaryColor))
              : _buildUsersTable(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUsersTable() {
    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No users found. Add users with the + button.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
              ),
              onPressed: _addTestUsers,
              child: const Text(
                'Add Test Users',
                style: TextStyle(color: secondaryColor),
              ),
            ),
          ],
        ),
      );
    }
    
    // Filter users based on search
    final filteredUsers = _users.where((user) {
      if (_searchQuery.isEmpty) return true;
      
      final query = _searchQuery.toLowerCase();
      return user.name.toLowerCase().contains(query) ||
             user.email.toLowerCase().contains(query);
    }).toList();
    
    if (filteredUsers.isEmpty) {
      return const Center(
        child: Text(
          'No users match your search.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Role')),
          DataColumn(label: Text('Actions')),
        ],
        rows: filteredUsers.map((user) {
          return DataRow(
            cells: [
              DataCell(Text(
                user.name, 
                style: user.isCurrentUser 
                    ? const TextStyle(fontWeight: FontWeight.bold) 
                    : null,
              )),
              DataCell(Text(user.email)),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.role.contains('Admin') 
                        ? primaryColor.withAlpha(26) 
                        : Colors.blue.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.role,
                    style: TextStyle(
                      color: user.role.contains('Admin') ? primaryColor : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.amber),
                      onPressed: () => _editUser(user),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: user.isCurrentUser ? Colors.grey : Colors.red,
                      ),
                      onPressed: user.isCurrentUser 
                          ? null 
                          : () => _deleteUser(user),
                      tooltip: user.isCurrentUser 
                          ? "Can't delete your own account" 
                          : 'Delete user',
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// Simple data class for user information
class UserData {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isCurrentUser;
  
  UserData({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isCurrentUser,
  });
}