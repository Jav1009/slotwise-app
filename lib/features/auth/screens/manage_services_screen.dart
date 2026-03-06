// features/admin/screens/manage_services_screen.dart
// Full CRUD interface for services.
// Admins can: view all services (including inactive), add new,
// toggle active/inactive, and soft-delete.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slot_wise_booking/models/service_model.dart';
import 'package:slot_wise_booking/services/api_service.dart';
import '../../../core/constants/api_constants.dart';

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});
  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  final _api     = ApiService();
  List<ServiceModel> _services = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      // Fetch all including inactive for admin view
      final res = await _api.get('${ApiConstants.services}?include_inactive=true');
      setState(() {
        _services   = (res.data as List).map((j) => ServiceModel.fromJson(j)).toList();
        _isLoading  = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddEditDialog([ServiceModel? existing]) {
    final nameCtrl  = TextEditingController(text: existing?.name);
    final descCtrl  = TextEditingController(text: existing?.description);
    final durCtrl   = TextEditingController(text: existing?.durationMinutes.toString());
    final priceCtrl = TextEditingController(text: existing?.price.toString());
    final form      = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Service' : 'Edit Service'),
        content: Form(
          key: form,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Service Name', border: OutlineInputBorder()),
                validator: (v) => v?.isEmpty == true ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: descCtrl, maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextFormField(controller: durCtrl, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Duration (minutes)', border: OutlineInputBorder()),
                validator: (v) => v?.isEmpty == true ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: priceCtrl, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (JMD)', border: OutlineInputBorder()),
                validator: (v) => v?.isEmpty == true ? 'Required' : null),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!form.currentState!.validate()) return;
              final body = {
                'name':             nameCtrl.text.trim(),
                'description':      descCtrl.text.trim(),
                'duration_minutes': int.parse(durCtrl.text),
                'price':            double.parse(priceCtrl.text),
              };
              if (existing == null) {
                await _api.post(ApiConstants.services, body);
              } else {
                await _api.put('${ApiConstants.services}/${existing.id}', body);
              }
              if (ctx.mounted) Navigator.pop(ctx);
              _load();
            },
            child: Text(existing == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(ServiceModel s) async {
    await _api.put('${ApiConstants.services}/${s.id}', {'is_active': !s.isActive});
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Services')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _services.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final s = _services[i];
                  return Card(
                    // opacity: s.isActive ? 1.0 : 0.5,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFD6EAF8),
                        child: Text(s.name[0], style: const TextStyle(color: Color(0xFF1A5276)))),
                      title: Text(s.name),
                      subtitle: Text('${s.formattedDuration}  •  ${s.formattedPrice}'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Switch(value: s.isActive, onChanged: (_) => _toggleActive(s)),
                        IconButton(icon: const Icon(Icons.edit), onPressed: () => _showAddEditDialog(s)),
                      ]),
                    ),
                  );
                },
              ),
            ),
    );
  }
}