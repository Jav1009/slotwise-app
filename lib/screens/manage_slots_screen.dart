// features/admin/screens/manage_slots_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:slot_wise_booking/models/service_model.dart';
import 'package:slot_wise_booking/services/api_service.dart';
import '../core/constants/api_constants.dart';

class ManageSlotsScreen extends StatefulWidget {
  const ManageSlotsScreen({super.key});
  @override
  State<ManageSlotsScreen> createState() => _ManageSlotsScreenState();
}

class _ManageSlotsScreenState extends State<ManageSlotsScreen> {
  final _api           = ApiService();
  List<ServiceModel>   _services        = [];
  ServiceModel?        _selectedService;
  DateTime             _selectedDate    = DateTime.now();
  List<String>         _existingSlots   = [];
  final Set<String>    _selectedTimes   = {};
  bool                 _loading         = false;

  // Available time options for batch creation (30-min intervals, 8am-6pm)
  final List<String> _timeOptions = List.generate(20, (i) {
    final hour   = 8 + (i ~/ 2);
    final minute = i.isEven ? '00' : '30';
    return '${hour.toString().padLeft(2,'0')}:$minute';
  });

  @override
  void initState() { super.initState(); _loadServices(); }

  Future<void> _loadServices() async {
    final res = await _api.get(ApiConstants.services);
    setState(() => _services = (res.data as List).map((j) => ServiceModel.fromJson(j)).toList());
  }

  Future<void> _loadExistingSlots() async {
    if (_selectedService == null) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final res = await _api.get(ApiConstants.slots, params: {
      'service_id': _selectedService!.id.toString(),
      'date': dateStr,
    });
    final all = res.data as List;
    setState(() => _existingSlots = all.map((s) => s['start_time'].toString().substring(0,5)).toList());
  }

  Future<void> _createSelectedSlots() async {
    if (_selectedService == null || _selectedTimes.isEmpty) return;
    setState(() => _loading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final dur     = _selectedService!.durationMinutes;

    final slots = _selectedTimes.map((t) {
      final parts = t.split(':');
      final start  = DateTime(0, 0, 0, int.parse(parts[0]), int.parse(parts[1]));
      final end    = start.add(Duration(minutes: dur));
      return {
        'start_time': t,
        'end_time':   DateFormat('HH:mm').format(end),
      };
    }).toList();

    await _api.post(ApiConstants.slots, {
      'service_id': _selectedService!.id,
      'slot_date':  dateStr,
      'slots':      slots,
    });

    setState(() { _selectedTimes.clear(); _loading = false; });
    await _loadExistingSlots();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slots created!'), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Slots')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Service picker
          DropdownButtonFormField<ServiceModel>(
            value: _selectedService,
            decoration: const InputDecoration(labelText: 'Select Service', border: OutlineInputBorder()),
            items: _services.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
            onChanged: (s) { setState(() { _selectedService = s; _selectedTimes.clear(); }); _loadExistingSlots(); },
          ),
          const SizedBox(height: 16),

          // Date picker
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text('Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}'),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 60)),
              );
              if (picked != null) {
                setState(() { _selectedDate = picked; _selectedTimes.clear(); });
                await _loadExistingSlots();
              }
            },
          ),
          const SizedBox(height: 16),

          if (_selectedService != null) ...[
            const Text('Select times to create slots:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _timeOptions.map((t) {
                final exists   = _existingSlots.contains(t);
                final selected = _selectedTimes.contains(t);
                return FilterChip(
                  label: Text(t),
                  selected: selected,
                  onSelected: exists ? null : (v) {
                    setState(() => v ? _selectedTimes.add(t) : _selectedTimes.remove(t));
                  },
                  backgroundColor: exists ? Colors.grey[200] : const Color(0xFFD6EAF8),
                  selectedColor: const Color(0xFF1A5276),
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: exists ? Colors.grey : (selected ? Colors.white : const Color(0xFF1A5276)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: (_selectedTimes.isEmpty || _loading) ? null : _createSelectedSlots,
              child: _loading
                ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Create ${_selectedTimes.length} Slot(s)'),
            ),
          ],
        ]),
      ),
    );
  }
}