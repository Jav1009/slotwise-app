// lib/features/profile/profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/snackbar_utils.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtr  = TextEditingController();
  final _phoneCtr = TextEditingController();
  bool _isEditing      = false;
  bool _isSaving       = false;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    final user    = context.read<AuthProvider>().currentUser;
    _nameCtr.text  = user?.name  ?? '';
    _phoneCtr.text = user?.phone ?? '';
  }

  @override
  void dispose() {
    _nameCtr.dispose();
    _phoneCtr.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512, maxHeight: 512, imageQuality: 80,
    );
    if (picked == null || !mounted) return;
    setState(() => _uploadingImage = true);
    try {
      final userId = context.read<AuthProvider>().currentUser!.id;
      final ref    = FirebaseStorage.instance.ref().child('avatars/$userId.jpg');
      await ref.putFile(File(picked.path));
      final url     = await ref.getDownloadURL();
      final success = await context.read<AuthProvider>().updateProfile(avatarUrl: url);
      if (mounted) {
        success
            ? SnackbarUtils.showSuccess(context, 'Profile photo updated')
            : SnackbarUtils.showError(context, 'Failed to save photo');
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final success = await context.read<AuthProvider>().updateProfile(
      name:  _nameCtr.text.trim(),
      phone: _phoneCtr.text.trim().isEmpty ? '' : _phoneCtr.text.trim(),
    );
    if (!mounted) return;
    setState(() { _isSaving = false; _isEditing = false; });
    success
        ? SnackbarUtils.showSuccess(context, 'Profile updated')
        : SnackbarUtils.showError(context, 'Failed to update profile');
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user   = context.watch<AuthProvider>().currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    // Theme-aware colours
    final cardColor  = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final labelColor = isDark ? Colors.white54 : AppColors.textSecondary;
    final valueColor = isDark ? Colors.white   : AppColors.textPrimary;
    final shadowColor =
        Colors.black.withOpacity(isDark ? 0.25 : 0.04);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            TextButton(
              onPressed: () => setState(() {
                _isEditing     = false;
                _nameCtr.text  = user.name;
                _phoneCtr.text = user.phone ?? '';
              }),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // ── Header ─────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _uploadingImage
                            ? null
                            : _pickAndUploadAvatar,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: Colors.white,
                              backgroundImage: user.avatarUrl != null
                                  ? NetworkImage(user.avatarUrl!)
                                  : null,
                              child: user.avatarUrl == null
                                  ? Text(
                                      user.name.isNotEmpty
                                          ? user.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0, right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle),
                                child: _uploadingImage
                                    ? const SizedBox(
                                        width: 14, height: 14,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : const Icon(Icons.camera_alt,
                                        size: 14, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Tap to change photo',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.7))),
                      const SizedBox(height: 10),
                      if (!_isEditing) ...[
                        Text(user.name,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(user.email,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white70)),
                        const SizedBox(height: 12),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: user.isAdmin
                              ? AppColors.accent
                              : Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user.isAdmin ? 'ADMIN' : 'CUSTOMER',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Edit form ──────────────────────────────
                if (_isEditing) ...[
                  _SectionHeader(title: 'Edit Profile', isDark: isDark),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameCtr,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().length < 2)
                                  ? 'Name must be at least 2 characters'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneCtr,
                          decoration: const InputDecoration(
                            labelText: 'Phone (optional)',
                            prefixIcon: Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed:
                                _isSaving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20, width: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2))
                                : const Text('Save Changes',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Account info ───────────────────────────
                if (!_isEditing) ...[
                  _SectionHeader(
                      title: 'Account Information', isDark: isDark),
                  _InfoTile(
                    icon: Icons.person_outline,
                    label: 'Full Name',
                    value: user.name,
                    cardColor: cardColor,
                    labelColor: labelColor,
                    valueColor: valueColor,
                    shadowColor: shadowColor,
                  ),
                  _InfoTile(
                    icon: Icons.email_outlined,
                    label: 'Email Address',
                    value: user.email,
                    cardColor: cardColor,
                    labelColor: labelColor,
                    valueColor: valueColor,
                    shadowColor: shadowColor,
                  ),
                  _InfoTile(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: user.phone?.isNotEmpty == true
                        ? user.phone!
                        : 'Not provided',
                    cardColor: cardColor,
                    labelColor: labelColor,
                    valueColor: (user.phone?.isNotEmpty == true)
                        ? valueColor
                        : labelColor,
                    shadowColor: shadowColor,
                  ),
                  _InfoTile(
                    icon: Icons.badge_outlined,
                    label: 'Account ID',
                    value: '#${user.id.toString().padLeft(6, '0')}',
                    cardColor: cardColor,
                    labelColor: labelColor,
                    valueColor: valueColor,
                    shadowColor: shadowColor,
                  ),
                  if (user.createdAt != null)
                    _InfoTile(
                      icon: Icons.calendar_today_outlined,
                      label: 'Member Since',
                      value:
                          '${user.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}',
                      cardColor: cardColor,
                      labelColor: labelColor,
                      valueColor: valueColor,
                      shadowColor: shadowColor,
                    ),
                  const SizedBox(height: 24),
                ],

                // ── App section ────────────────────────────
                _SectionHeader(title: 'App', isDark: isDark),
                _ActionTile(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  cardColor: cardColor,
                  labelColor: valueColor,
                  shadowColor: shadowColor,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen())),
                ),
                _ActionTile(
                  icon: Icons.info_outline,
                  label: 'About SlotWise',
                  cardColor: cardColor,
                  labelColor: valueColor,
                  shadowColor: shadowColor,
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'SlotWise',
                    applicationVersion: '1.0.0',
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                          'A smart appointment booking platform for service businesses.'),
                    ],
                  ),
                ),
                _ActionTile(
                  icon: Icons.logout,
                  label: 'Logout',
                  cardColor: cardColor,
                  labelColor: AppColors.error,
                  iconColor: AppColors.error,
                  shadowColor: shadowColor,
                  onTap: _handleLogout,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? Colors.white54
                  : AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    cardColor;
  final Color    labelColor;
  final Color    valueColor;
  final Color    shadowColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.cardColor,
    required this.labelColor,
    required this.valueColor,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: shadowColor, blurRadius: 6)
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11, color: labelColor)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: valueColor)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ActionTile extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;
  final Color        cardColor;
  final Color        labelColor;
  final Color        shadowColor;
  final Color?       iconColor;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.cardColor,
    required this.labelColor,
    required this.shadowColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: shadowColor, blurRadius: 6)
          ],
        ),
        child: ListTile(
          leading:
              Icon(icon, color: iconColor ?? AppColors.primary),
          title: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: labelColor)),
          trailing: Icon(Icons.arrow_forward_ios,
              size: 14,
              color: labelColor.withOpacity(0.5)),
          onTap: onTap,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
}