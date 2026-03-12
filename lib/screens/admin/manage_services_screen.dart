// lib/screens/admin/manage_services_screen.dart
//
// FIXES APPLIED:
//   BUG — Toggle inactive hides service: the screen only showed active services
//     because the backend's GET /services filtered is_active=true by default.
//     Fix: always send include_inactive=true for staff/admin view.
//
// ADDED:
//   • Filter bar: All | Active | Inactive
//   • Inactive services shown with subtle dimmed style (not hidden)
//   • Status badge on each card
//   • Notification icon in AppBar
//   • Theme-aware colours

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_colors.dart';
import '../../models/service_model.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../widgets/notification_dialog.dart';

enum _ServiceFilter { all, active, inactive }

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});
  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  final _api             = ApiService();
  List<ServiceModel>     _services = [];
  bool                   _isLoading = true;
  _ServiceFilter         _filter    = _ServiceFilter.all;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      // FIX: always request inactive services too so toggling doesn't hide them
      final res  = await _api.get(
        ApiConstants.services,
        params: {'include_inactive': 'true'},
      );
      final list = (res.data is Map ? res.data['data'] ?? res.data : res.data) as List;
      setState(() {
        _services  = list.map((j) => ServiceModel.fromJson(j)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<ServiceModel> get _filtered {
    switch (_filter) {
      case _ServiceFilter.active:   return _services.where((s) =>  s.isActive).toList();
      case _ServiceFilter.inactive: return _services.where((s) => !s.isActive).toList();
      case _ServiceFilter.all:      return _services;
    }
  }

  void _showAddEditDialog([ServiceModel? existing]) {
    final nameCtrl     = TextEditingController(text: existing?.name);
    final descCtrl     = TextEditingController(text: existing?.description);
    final durCtrl      = TextEditingController(
        text: existing != null ? existing.durationMinutes.toString() : '');
    final priceCtrl    = TextEditingController(
        text: existing != null ? existing.price.toString() : '');
    final categoryCtrl = TextEditingController(text: existing?.category);
    final form         = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Service' : 'Edit Service'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Form(
          key: form,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Service Name',
                    prefixIcon: Icon(Icons.design_services_outlined)),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description_outlined)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: categoryCtrl,
                decoration: const InputDecoration(
                    labelText: 'Category',
                    hintText: 'Hair, Nails, Skin …',
                    prefixIcon: Icon(Icons.category_outlined)),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: durCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Duration (minutes)',
                    prefixIcon: Icon(Icons.timer_outlined)),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Price (JMD)',
                    prefixIcon: Icon(Icons.attach_money)),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!form.currentState!.validate()) return;
              final body = {
                'name':             nameCtrl.text.trim(),
                'description':      descCtrl.text.trim(),
                'category':         categoryCtrl.text.trim(),
                'duration_minutes': int.parse(durCtrl.text.trim()),
                'price':            double.parse(priceCtrl.text.trim()),
              };
              if (existing == null) {
                await _api.post(ApiConstants.services, body);
              } else {
                await _api.put('${ApiConstants.services}/${existing.id}', body);
              }
              if (ctx.mounted) Navigator.pop(ctx);
              _load();
              if (existing == null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Service created! Slots auto-generated for the next 30 days.'),
                    backgroundColor: AppColors.success,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            child: Text(existing == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(ServiceModel s) async {
    try {
      await _api.put(
          '${ApiConstants.services}/${s.id}', {'is_active': !s.isActive});
      await _load();  // reload so updated state reflects immediately
    } catch (_) {}
  }

  Future<void> _deleteService(ServiceModel s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text(
          'Delete "${s.name}"? This cannot be undone.\n'
          'Future slots for this service will also be removed.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.delete('${ApiConstants.services}/${s.id}');
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final c        = Theme.of(context).extension<SlotWiseColors>()!;
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Services'),
        actions: [
          const NotificationIconButton(iconColor: Colors.white),
          const SizedBox(width: 4),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEditDialog,
        backgroundColor: c.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add', style: TextStyle(color: Colors.white)),
      ),

      body: Column(
        children: [
          // ── Filter bar ──────────────────────────────────────
          Container(
            color: c.cardBg,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Counts row
                Row(
                  children: [
                    Text(
                      '${_services.length} total',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${_services.where((s) => s.isActive).length} active',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.success),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${_services.where((s) => !s.isActive).length} inactive',
                      style: TextStyle(fontSize: 12, color: Colors.orange[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Filter chips
                Row(
                  children: _ServiceFilter.values.map((f) {
                    final label = switch (f) {
                      _ServiceFilter.all      => 'All',
                      _ServiceFilter.active   => 'Active',
                      _ServiceFilter.inactive => 'Inactive',
                    };
                    final selected = _filter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: selected ? c.primaryColor : c.accentSoft,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? c.primaryColor
                                  : c.primaryColor.withOpacity(0.15),
                            ),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : c.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: c.primaryColor.withOpacity(0.08)),

          // ── Service list ─────────────────────────────────────
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: c.primaryColor))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.design_services_outlined,
                                size: 56,
                                color: c.primaryColor.withOpacity(0.3)),
                            const SizedBox(height: 12),
                            Text(
                              _filter == _ServiceFilter.inactive
                                  ? 'No inactive services'
                                  : _filter == _ServiceFilter.active
                                      ? 'No active services'
                                      : 'No services yet. Tap + to add one.',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: c.primaryColor,
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) => _ServiceCard(
                            service: filtered[i],
                            primaryColor: c.primaryColor,
                            accentSoft: c.accentSoft,
                            onEdit:   () => _showAddEditDialog(filtered[i]),
                            onToggle: () => _toggleActive(filtered[i]),
                            onDelete: () => _deleteService(filtered[i]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Service card ──────────────────────────────────────────────────────────────
class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final Color        primaryColor;
  final Color        accentSoft;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ServiceCard({
    required this.service,
    required this.primaryColor,
    required this.accentSoft,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = service.isActive;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isActive ? 1.0 : 0.65,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar / initial
              CircleAvatar(
                radius: 22,
                backgroundColor: isActive
                    ? accentSoft
                    : Colors.grey.withOpacity(0.15),
                child: Text(
                  service.name[0].toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isActive ? primaryColor : Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name + category + meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            service.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        // Active/inactive badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.success.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isActive ? AppColors.success : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Category chip
                    if (service.category != null && service.category!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          service.category!,
                          style: TextStyle(
                              fontSize: 10, color: primaryColor),
                        ),
                      ),

                    Text(
                      '${service.formattedDuration}  ·  ${service.formattedPrice}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),

              // Actions column
              Column(
                children: [
                  Switch(
                    value: service.isActive,
                    onChanged: (_) => onToggle(),
                    activeColor: primaryColor,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit_outlined,
                            size: 18, color: primaryColor),
                        tooltip: 'Edit',
                        onPressed: onEdit,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Colors.red),
                        tooltip: 'Delete',
                        onPressed: onDelete,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}