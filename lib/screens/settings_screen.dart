import 'package:flutter/material.dart';
import 'package:expense_tracker/screens/login_screen.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/services/user_service.dart';
import 'package:expense_tracker/models/user_model.dart';
import 'package:expense_tracker/screens/edit_profile_screen.dart';
import 'package:expense_tracker/screens/recurring_payments_screen.dart';
import 'package:expense_tracker/screens/pending_settlements_screen.dart';

import 'package:expense_tracker/widgets/fade_in_slide.dart';
import 'package:expense_tracker/widgets/scale_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      final userModel = await _userService.getUser(user.uid);
      if (mounted) {
        setState(() {
          _currentUser = userModel;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _logout(BuildContext context) async {
    await AuthService().signOut();
    if (!context.mounted) return;
    
    // Clear navigation stack and go to Login
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60), // Top padding for safe area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FadeInSlide(
              child: Center(
                child: Text(
                  'Settings',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          
          // Profile Card
          FadeInSlide(
            delay: 0.1,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: isDark 
                        ? theme.colorScheme.primary.withOpacity(0.2)
                        : Colors.black.withOpacity(0.05),
                    backgroundImage: _currentUser?.photoUrl != null
                        ? NetworkImage(_currentUser!.photoUrl!)
                        : null,
                    child: _currentUser?.photoUrl == null 
                      ? Icon(
                        Icons.person,
                        size: 30,
                        color: isDark ? theme.colorScheme.primary : Colors.black,
                      ) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentUser?.displayName ?? 'User Name',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentUser?.email ?? 'user@example.com',
                          style: theme.textTheme.bodyMedium?.copyWith(
                             color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  ScaleButton(
                    child: IconButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                        );
                        if (result == true) {
                          _loadUserData();
                        }
                      },
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Settings Options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                FadeInSlide(
                  delay: 0.2,
                  child: _buildSettingsTile(
                    context,
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    onTap: () {},
                  ),
                ),
                const SizedBox(height: 12),
                FadeInSlide(
                  delay: 0.25,
                  child: _buildSettingsTile(
                    context,
                    icon: Icons.repeat,
                    title: 'Recurring Payments',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RecurringPaymentsScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                FadeInSlide(
                  delay: 0.28,
                  child: _buildSettingsTile(
                    context,
                    icon: Icons.handshake_outlined,
                    title: 'Pending Settlements',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PendingSettlementsScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                FadeInSlide(
                  delay: 0.3,
                  child: _buildSettingsTile(
                    context,
                    icon: Icons.security_outlined,
                    title: 'Security',
                    onTap: () {},
                  ),
                ),
                const SizedBox(height: 12),
                FadeInSlide(
                  delay: 0.35,
                  child: _buildSettingsTile(
                    context,
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {},
                  ),
                ),
                const SizedBox(height: 40),
                
                // Logout Button
                FadeInSlide(
                  delay: 0.4,
                  child: ScaleButton(
                    onTap: () => _logout(context),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      tileColor: Colors.red.withOpacity(0.1),
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return ScaleButton(
      onTap: onTap,
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        tileColor: theme.cardColor,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.light 
                ? Colors.black.withOpacity(0.05) 
                : theme.colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon, 
            color: theme.brightness == Brightness.light 
                ? Colors.black 
                : theme.colorScheme.primary, 
            size: 20
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }
}
