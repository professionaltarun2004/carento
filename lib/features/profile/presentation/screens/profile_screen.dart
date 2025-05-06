import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carento/core/constants/app_constants.dart';
import 'package:carento/features/auth/presentation/screens/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in to view profile'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    userData['name']?[0].toUpperCase() ?? user.email?[0].toUpperCase() ?? 'U',
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  userData['name'] ?? 'User',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  user.email ?? '',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),
                _buildSection(
                  context,
                  'Personal Information',
                  [
                    _buildInfoTile(
                      context,
                      'Phone',
                      userData['phone'] ?? 'Not set',
                      Icons.phone,
                    ),
                    _buildInfoTile(
                      context,
                      'Address',
                      userData['address'] ?? 'Not set',
                      Icons.location_on,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  'Preferences',
                  [
                    _buildSwitchTile(
                      context,
                      'Email Notifications',
                      userData['emailNotifications'] ?? true,
                      (value) {
                        // TODO: Implement email notifications toggle
                      },
                    ),
                    _buildSwitchTile(
                      context,
                      'Push Notifications',
                      userData['pushNotifications'] ?? true,
                      (value) {
                        // TODO: Implement push notifications toggle
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  'Account',
                  [
                    _buildActionTile(
                      context,
                      'Edit Profile',
                      Icons.edit,
                      () {
                        // TODO: Implement edit profile
                      },
                    ),
                    _buildActionTile(
                      context,
                      'Change Password',
                      Icons.lock,
                      () {
                        // TODO: Implement change password
                      },
                    ),
                    _buildActionTile(
                      context,
                      'Delete Account',
                      Icons.delete,
                      () {
                        // TODO: Implement delete account
                      },
                      isDestructive: true,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
} 