// lib/screens/customer/profile_screen.dart
//
// UPDATED:
//   • Settings icon in AppBar → opens SettingsDialog (includes theme toggle)
//   • Notification icon in AppBar → opens NotificationDialog
//   • Role badge for all roles (customer / staff / admin)
//   • Theme-aware colours via SlotWiseColors extension

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/notification_dialog.dart';
import '../../widgets/settings_dialog.dart';
import '../../screens/customer/edit_profile_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<NotificationProvider>().fetchNotifications(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c    = Theme.of(context).extension<SlotWiseColors>()!;
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: c.primaryColor)),
      );
    }

    final roleLabel  = user.isAdmin ? 'Admin' : user.isStaff ? 'Staff' : 'Customer';
    final roleColor  = user.isAdmin
        ? const Color(0xFF7C9BFF)
        : user.isStaff ? const Color(0xFF4ADE80) : c.accentColor;

    return Scaffold(
      // No AppBar — header is part of the scroll content
      body: CustomScrollView(
        slivers: [
          // ── Collapsible header ──────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: c.headerBg,
            foregroundColor: Colors.white,
            title: const Text('Profile'),
            actions: [
              const NotificationIconButton(iconColor: Colors.white),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                tooltip: 'Settings',
                onPressed: () => SettingsDialog.show(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(color: c.headerBg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: c.accentSoft,
                      backgroundImage: user.profilePictureUrl != null
                          ? CachedNetworkImageProvider(user.profilePictureUrl!)
                          : null,
                      child: user.profilePictureUrl == null
                          ? Text(
                              user.firstName[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: c.primaryColor,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 8),
                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: roleColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        roleLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: roleColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + email
                  Center(
                    child: Column(
                      children: [
                        Text(
                          user.fullName,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: c.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Account section ──────────────────────────
                  _SectionLabel('Account', c),
                  const SizedBox(height: 8),
                  _profileTile(
                    context,
                    icon: Icons.person_outlined,
                    title: 'Edit Profile',
                    c: c,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                  ),
                  _profileTile(
                    context,
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    trailing: Consumer<NotificationProvider>(
                      builder: (_, prov, __) => prov.unreadCount > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${prov.unreadCount}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    c: c,
                    onTap: () => NotificationDialog.show(context),
                  ),
                  _profileTile(
                    context,
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    c: c,
                    onTap: () => SettingsDialog.show(context),
                  ),

                  const SizedBox(height: 20),

                  // ── Support section ──────────────────────────
                  _SectionLabel('Support', c),
                  const SizedBox(height: 8),
                  _profileTile(
                    context,
                    icon: Icons.help_outline,
                    title: 'Help & FAQ',
                    c: c,
                    onTap: () {},
                  ),

                  const SizedBox(height: 20),

                  // ── Logout ───────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text('Sign Out',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        minimumSize: const Size(double.infinity, 52),
                      ),
                      onPressed: () => context.read<AuthProvider>().logout(),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _SectionLabel(String label, SlotWiseColors c) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Colors.grey[400],
      ),
    ),
  );

  Widget _profileTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required SlotWiseColors c,
    Widget? trailing,
    VoidCallback? onTap,
  }) =>
      Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: c.accentSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: c.primaryColor),
          ),
          title: Text(title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          trailing: trailing ??
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
}