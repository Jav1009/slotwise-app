import 'package:flutter/material.dart';
import '../data/models/slot.dart';
import '../data/repositories/service_repository.dart';

class SlotProvider extends ChangeNotifier {
  List<Slot> _availableSlots = [];
  Slot? _selectedSlot;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _error;

  List<Slot> get availableSlots => _availableSlots;
  Slot? get selectedSlot => _selectedSlot;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Slot> get availableOnly {
    return _availableSlots.where((slot) => slot.isAvailable).toList();
  }

  List<Slot> get morningSlots {
    return _availableSlots.where((slot) {
      final hour = int.parse(slot.startTime.split(':')[0]);
      return hour < 12;
    }).toList();
  }

  List<Slot> get afternoonSlots {
    return _availableSlots.where((slot) {
      final hour = int.parse(slot.startTime.split(':')[0]);
      return hour >= 12 && hour < 17;
    }).toList();
  }

  List<Slot> get eveningSlots {
    return _availableSlots.where((slot) {
      final hour = int.parse(slot.startTime.split(':')[0]);
      return hour >= 17;
    }).toList();
  }

  Future<void> fetchSlots(int serviceId, String date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ServiceRepository.getServiceSlots(serviceId, date);
      
      if (response.success) {
        _availableSlots = response.data!;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectSlot(Slot slot) {
    _selectedSlot = slot;
    notifyListeners();
  }

  void clearSelectedSlot() {
    _selectedSlot = null;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void clearSlots() {
    _availableSlots = [];
    notifyListeners();
  }

  bool isSlotAvailable(int slotId) {
    return _availableSlots.any((slot) => slot.id == slotId && slot.isAvailable);
  }

  Slot? getSlotById(int id) {
    try {
      return _availableSlots.firstWhere((slot) => slot.id == id);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}