// features/slots/providers/slot_provider.dart
import 'package:flutter/material.dart';
import 'package:slot_wise_booking/models/slot_model.dart';
import 'package:slot_wise_booking/services/api_service.dart';
import '../core/constants/api_constants.dart';

class SlotProvider extends ChangeNotifier {
  List<SlotModel> _slots       = [];
  SlotModel?      _selectedSlot;
  bool            _isLoading   = false;
  String?         _error;

  List<SlotModel> get slots        => _slots;
  SlotModel?      get selectedSlot => _selectedSlot;
  bool            get isLoading    => _isLoading;
  String?         get error        => _error;

  final _api = ApiService();

  Future<void> fetchSlots({required int serviceId, required DateTime date}) async {
    _isLoading = true;
    _selectedSlot = null;   // Clear previous selection when date changes
    notifyListeners();

    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
      final res = await _api.get(ApiConstants.slots, params: {
        'service_id': serviceId.toString(),
        'date': dateStr,
      });
      _slots = (res.data as List)
          .map((j) => SlotModel.fromJson(j as Map<String, dynamic>))
          .toList();
      _error = null;
    } catch (e) {
      _error = 'Could not load slots.';
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  void selectSlot(SlotModel slot) {
    _selectedSlot = slot;
    notifyListeners();
  }

  void clearSelection() {
    _selectedSlot = null;
    notifyListeners();
  }
}