// features/admin/screens/manage_bookings_screen.dart
import 'package:flutter/material.dart';
import 'package:slot_wise_booking/models/booking_model.dart';
import 'package:slot_wise_booking/services/api_service.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/app_colors.dart';

class ManageBookingsScreen extends StatefulWidget {
  const ManageBookingsScreen({super.key});
  @override
  State<ManageBookingsScreen> createState() => _ManageBookingsScreenState();
}

class _ManageBookingsScreenState extends State<ManageBookingsScreen> {
  final _api     = ApiService();
  List<BookingModel> _bookings = [];
  String?       _filterStatus;
  bool          _loading      = true;

  final _statuses = ['pending', 'confirmed', 'completed', 'cancelled'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final params = _filterStatus != null ? {'status': _filterStatus} : null;
      final res    = await _api.get(ApiConstants.bookings, params: params);
      setState(() {
        _bookings = (res.data as List).map((j) => BookingModel.fromJson(j)).toList();
        _loading  = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(BookingModel b, String newStatus) async {
    await _api.put('${ApiConstants.bookings}/${b.id}/status', {'status': newStatus});
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking updated to $newStatus'), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Bookings')),
      body: Column(children: [
        // Filter chips
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _filterStatus == null,
                onSelected: (_) { setState(() => _filterStatus = null); _load(); },
              ),
              const SizedBox(width: 6),
              ..._statuses.map((s) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(s),
                  selected: _filterStatus == s,
                  selectedColor: AppColors.statusColor(s).withOpacity(0.3),
                  onSelected: (_) { setState(() => _filterStatus = s); _load(); },
                ),
              )),
            ],
          ),
        ),

        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _bookings.isEmpty
              ? const Center(child: Text('No bookings found', style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _bookings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final b     = _bookings[i];
                      final color = AppColors.statusColor(b.status);
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(b.serviceName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                              Chip(
                                label: Text(b.status, style: TextStyle(color: color, fontSize: 11)),
                                backgroundColor: color.withOpacity(0.1),
                                side: BorderSide(color: color), padding: EdgeInsets.zero),
                            ]),
                            const SizedBox(height: 4),
                            Text('${b.slotDate}  ${b.startTime.substring(0,5)} – ${b.endTime.substring(0,5)}',
                              style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text('JMD \$${b.price.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                            if (b.notes != null && b.notes!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('Note: ${b.notes}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                            const SizedBox(height: 10),
                            // Status update dropdown
                            Row(children: [
                              const Text('Update status: ', style: TextStyle(fontSize: 13)),
                              const SizedBox(width: 8),
                              DropdownButton<String>(
                                value: b.status,
                                underline: const SizedBox(),
                                items: _statuses.map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s, style: TextStyle(color: AppColors.statusColor(s))),
                                )).toList(),
                                onChanged: (newStatus) {
                                  if (newStatus != null && newStatus != b.status) {
                                    _updateStatus(b, newStatus);
                                  }
                                },
                              ),
                            ]),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ]),
    );
  }
}