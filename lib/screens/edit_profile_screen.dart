import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/services/user_service.dart';
import 'package:expense_tracker/models/user_model.dart';

import 'package:expense_tracker/widgets/gradient_background.dart';
import 'package:expense_tracker/widgets/custom_snackbar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final user = _authService.currentUser;
    if (user != null) {
      _currentUser = await _userService.getUser(user.uid);
      if (_currentUser != null) {
        _nameController.text = _currentUser!.displayName ?? '';
        if (_currentUser!.dob != null) {
          _dobController.text = DateFormat('yyyy-MM-dd').format(_currentUser!.dob!);
        }
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate() && _currentUser != null) {
      setState(() => _isLoading = true);
      try {
        String? photoUrl = _currentUser!.photoUrl;

        if (_imageFile != null) {
          photoUrl = await _userService.uploadProfilePicture(_imageFile!, _currentUser!.id);
        }

        DateTime? dob;
        if (_dobController.text.isNotEmpty) {
          dob = DateTime.tryParse(_dobController.text);
        }

        await _userService.updateUser(_currentUser!.id, {
          'displayName': _nameController.text.trim(),
          'dob': dob?.toIso8601String(),
          'photoUrl': photoUrl,
        });

        if (mounted) {
          CustomSnackBar.show(context, 'Profile Updated Successfully');
          Navigator.of(context).pop(true); // Return true to indicate update
        }
      } catch (e) {
        if (mounted) {
          CustomSnackBar.show(context, 'Update Failed: $e', isError: true);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text('Edit Profile', style: theme.appBarTheme.titleTextStyle),
        ),
        body: _isLoading && _currentUser == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Profile Picture Section
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.cardColor,
                                border: Border.all(
                                  color: theme.colorScheme.primary.withOpacity(0.2),
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                backgroundImage: _imageFile != null
                                    ? FileImage(_imageFile!)
                                    : (_currentUser?.photoUrl != null
                                        ? NetworkImage(_currentUser!.photoUrl!) as ImageProvider
                                        : null),
                                child: _imageFile == null && _currentUser?.photoUrl == null
                                    ? Icon(Icons.person, size: 60, color: theme.colorScheme.primary)
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.black, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),

                      // Name Field
                      _buildInputField(
                        controller: _nameController,
                        label: 'Display Name',
                        icon: Icons.person_outline,
                        theme: theme,
                      ),
                      
                      const SizedBox(height: 20),

                      // DOB Field
                      _buildInputField(
                        controller: _dobController,
                        label: 'Date of Birth (YYYY-MM-DD)',
                        icon: Icons.calendar_today_outlined,
                        theme: theme,
                        readOnly: true,
                        onTap: () async {
                          FocusScope.of(context).requestFocus(FocusNode());
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _currentUser?.dob ?? DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: theme.colorScheme.primary,
                                    onPrimary: Colors.black, // Header text color
                                    surface: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                    onSurface: isDark ? Colors.white : Colors.black,
                                  ),
                                  dialogBackgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
                          }
                        },
                      ),

                      const SizedBox(height: 40),

                      // Save Button
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withOpacity(0.8)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.1),
        ),
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        style: TextStyle(
          color: theme.textTheme.bodyLarge?.color,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
          icon: Icon(icon, color: theme.colorScheme.primary, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        validator: (v) => v!.isEmpty && !readOnly ? '$label required' : null,
      ),
    );
  }
}
