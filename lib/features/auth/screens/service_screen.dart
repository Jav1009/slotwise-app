// features/services/screens/services_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:slot_wise_booking/features/auth/screens/admin_dashboard_screen.dart';
import 'package:slot_wise_booking/features/auth/screens/profile_screen.dart';
import 'package:slot_wise_booking/features/auth/screens/slot_picker_screen.dart';
import 'package:slot_wise_booking/models/service_model.dart';
import '../providers/service_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});
  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<ServiceProvider>().fetchServices());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SlotWise'),
        actions: [
          // Admin shortcut
          if (auth.isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
            ),
          IconButton(
            icon: const Icon(Icons.person_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      body: Consumer<ServiceProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (prov.error != null) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(prov.error!),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: prov.fetchServices, child: const Text('Retry')),
              ],
            ));
          }
          if (prov.services.isEmpty) {
            return const Center(child: Text('No services available.'));
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
        },
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => SlotPickerScreen(service: service))),
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
                      placeholder: (_, __) => Container(color: const Color(0xFFD6EAF8)),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFFD6EAF8),
                        child: const Icon(Icons.image, color: Color(0xFF1A5276))),
                    )
                  : Container(
                      color: const Color(0xFFD6EAF8),
                      child: const Icon(Icons.cut, size: 40, color: Color(0xFF1A5276))),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.schedule, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(service.formattedDuration, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ]),
                  const SizedBox(height: 2),
                  Text(service.formattedPrice,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A5276))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}