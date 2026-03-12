// features/services/screens/services_screen.dart
//
// Changes:
//   • Added: category filter chips row below AppBar
//   • initState: also fetches categories
//   • Admin shortcut now also shows for isStaffOrAdmin
//   • All card UI unchanged

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:slot_wise_booking/core/constants/app_colors.dart';
import 'package:slot_wise_booking/screens/admin/admin_dashboard_screen.dart';
import 'package:slot_wise_booking/screens/customer/profile_screen.dart';
import 'package:slot_wise_booking/screens/customer/slot_picker_screen.dart';
import 'package:slot_wise_booking/models/service_model.dart';
import '../../providers/service_provider.dart';
import '../../providers/auth_provider.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});
  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<ServiceProvider>();
      prov.fetchServices();
      prov.fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SlotWise'),
        actions: [
          // Show dashboard shortcut for staff and admin
          if (auth.isStaffOrAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Dashboard',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.person_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<ServiceProvider>(
          builder: (context, prov, _) {
            return Column(
              children: [
                // ── Category filter chips ──────────────────────
                if (prov.categories.isNotEmpty)
                  SizedBox(
                    height: 52,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      children: [
                        // "All" chip
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: const Text('All'),
                            selected: prov.selectedCategory == null,
                            selectedColor: AppColors.lightBlue,
                            onSelected: (_) => prov.clearFilters(),
                          ),
                        ),
                        ...prov.categories.map(
                          (cat) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(cat),
                              selected: prov.selectedCategory == cat,
                              selectedColor: AppColors.lightBlue,
                              onSelected: (_) => prov.setCategory(
                                prov.selectedCategory == cat ? null : cat,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
        
                // ── Services grid ──────────────────────────────
                Expanded(child: _buildBody(prov)),
              ],
            );
          },
        ),
      ),
    );
  }
}

Widget _buildBody(ServiceProvider prov) {
  if (prov.isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  if (prov.error != null) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(prov.error!),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: prov.fetchServices,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  if (prov.services.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.design_services, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            prov.selectedCategory != null
                ? 'No services in "${prov.selectedCategory}"'
                : 'No services available',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          if (prov.selectedCategory != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: prov.clearFilters,
              child: const Text('Show all services'),
            ),
          ],
        ],
      ),
    );
  }

  return RefreshIndicator(
    onRefresh: prov.fetchServices,
    child: GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: prov.services.length,
      itemBuilder: (ctx, i) => _ServiceCard(service: prov.services[i]),
    ),
  );
}

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SlotPickerScreen(service: service)),
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Service image
            Expanded(
              child: service.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: service.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: const Color(0xFFD6EAF8)),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFFD6EAF8),
                        child: const Icon(
                          Icons.image,
                          color: Color(0xFF1A5276),
                        ),
                      ),
                    )
                  : Container(
                      color: const Color(0xFFD6EAF8),
                      child: const Icon(
                        Icons.cut,
                        size: 40,
                        color: Color(0xFF1A5276),
                      ),
                    ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        service.formattedDuration,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    service.formattedPrice,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A5276),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
