// lib/features/auth/screens/edit_profile_screen.dart
//
// NEW SCREEN — allows a user to update their name and profile picture.
// Uses Supabase storage (image_upload_service) or any image upload service.
// On save → calls PUT /api/auth/me (to be added) or updates via auth provider.

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:slot_wise_booking/core/constants/app_colors.dart';
import 'package:slot_wise_booking/providers/auth_provider.dart';
import 'package:slot_wise_booking/services/api_service.dart';
import 'package:slot_wise_booking/services/image_upload_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  final _formKey      = GlobalKey<FormState>();
  final _api          = ApiService();
  final _imagePicker  = ImagePicker();

  File?  _pickedImage;
  bool   _isLoading   = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user!;
    _firstNameCtrl = TextEditingController(text: user.firstName);
    _lastNameCtrl  = TextEditingController(text: user.lastName);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (picked != null) setState(() => _pickedImage = File(picked.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      String? newImageUrl;

      // Upload new profile picture if one was picked
      if (_pickedImage != null) {
        newImageUrl = await ImageUploadService.uploadProfilePicture(_pickedImage!);
      }

      // Build update payload
      final body = <String, dynamic>{
        'firstName': _firstNameCtrl.text.trim(),
        'lastName':  _lastNameCtrl.text.trim(),
        if (newImageUrl != null) 'profilePictureUrl': newImageUrl,
      };

      // PUT /api/auth/me
      await _api.put('/auth/me', body);

      // Refresh user state in AuthProvider
      await context.read<AuthProvider>().refreshUser();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Could not update profile. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Avatar picker ──────────────────────────────
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: AppColors.lightBlue,
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!) as ImageProvider
                          : (user.profilePictureUrl != null
                              ? CachedNetworkImageProvider(user.profilePictureUrl!)
                                  as ImageProvider
                              : null),
                      child: (_pickedImage == null && user.profilePictureUrl == null)
                          ? Text(
                              user.firstName.isNotEmpty
                                  ? user.firstName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  fontSize: 40,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold))
                          : null,
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text('Tap the camera to change photo',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
              const SizedBox(height: 32),

              // ── First name ─────────────────────────────────
              TextFormField(
                controller: _firstNameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  prefixIcon: Icon(Icons.person_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'First name is required' : null,
              ),
              const SizedBox(height: 16),

              // ── Last name ──────────────────────────────────
              TextFormField(
                controller: _lastNameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  prefixIcon: Icon(Icons.person_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Last name is required' : null,
              ),

              // ── Error ──────────────────────────────────────
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ],
              const SizedBox(height: 24),

              // ── Save button ────────────────────────────────
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}