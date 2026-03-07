import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/service_provider.dart';
import '../../providers/slot_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';

class ManageSlotsScreen extends StatefulWidget {
  const ManageSlotsScreen({Key? key}) : super(key: key);

  @override
  State<ManageSlotsScreen> createState() => _ManageSlotsScreenState();
}

class _ManageSlotsScreenState extends State<ManageSlotsScreen> {
  Service? _selectedService;
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ServiceProvider>(context, listen: false).fetchServices();
    });
  }

  void _loadSlots() {
    if (_selectedService != null) {
      Provider.of<SlotProvider>(context, listen: false).fetchSlots(
        _selectedService!.id,
        Formatters.formatApiDate(_selectedDay),
      );
    }
  }

  void _showAddSlotDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddSlotForm(
        service: _selectedService!,
        selectedDate: _selectedDay,
        onSlotAdded: _loadSlots,
      ),
    );
  }

  void _showEditSlotDialog(Slot slot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => EditSlotForm(
        slot: slot,
        onSlotUpdated: _loadSlots,
      ),
    );
  }

  Future<void> _deleteSlot(Slot slot) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Slot'),
        content: Text(
          'Are you sure you want to delete the slot at ${slot.displayTime}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      final slotProvider = Provider.of<SlotProvider>(context, listen: false);
      // TODO: Implement delete slot API
      await Future.delayed(const Duration(seconds: 1));
      
      _loadSlots();
      
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Slot deleted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ServiceProvider, SlotProvider>(
      builder: (context, serviceProvider, slotProvider, child) {
        return Column(
          children: [
            // Service selector
            Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<Service>(
                value: _selectedService,
                decoration: InputDecoration(
                  labelText: 'Select Service',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.spa),
                ),
                items: serviceProvider.services.map((service) {
                  return DropdownMenuItem(
                    value: service,
                    child: Text(service.name),
                  );
                }).toList(),
                onChanged: (service) {
                  setState(() {
                    _selectedService = service;
                  });
                  if (service != null) {
                    _loadSlots();
                  }
                },
              ),
            ),

            if (_selectedService != null) ...[
              // Calendar
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: TableCalendar(
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(const Duration(days: 60)),
                  focusedDay: _selectedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                    });
                    _loadSlots();
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Slots header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Slots for ${Formatters.formatDate(_selectedDay)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddSlotDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Slot'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Slots list
              Expanded(
                child: _isLoading || slotProvider.isLoading
                    ? const LoadingIndicator()
                    : slotProvider.availableSlots.isEmpty
                        ? EmptyState(
                            icon: Icons.schedule,
                            message: 'No slots available',
                            subtitle: 'Add slots for this date',
                            buttonText: 'Add Slot',
                            onButtonPressed: _showAddSlotDialog,
                          )
                        : RefreshIndicator(
                            onRefresh: _loadSlots,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: slotProvider.availableSlots.length,
                              itemBuilder: (context, index) {
                                final slot = slotProvider.availableSlots[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: slot.isAvailable
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        slot.isAvailable
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: slot.isAvailable
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    title: Text(slot.displayTime),
                                    subtitle: Text(
                                      slot.isAvailable ? 'Available' : 'Booked',
                                      style: TextStyle(
                                        color: slot.isAvailable
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (slot.isAvailable) ...[
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () => _showEditSlotDialog(slot),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _deleteSlot(slot),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ] else ...[
              Expanded(
                child: EmptyState(
                  icon: Icons.schedule,
                  message: 'Select a service',
                  subtitle: 'Choose a service to manage its slots',
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class AddSlotForm extends StatefulWidget {
  final Service service;
  final DateTime selectedDate;
  final VoidCallback onSlotAdded;

  const AddSlotForm({
    Key? key,
    required this.service,
    required this.selectedDate,
    required this.onSlotAdded,
  }) : super(key: key);

  @override
  State<AddSlotForm> createState() => _AddSlotFormState();
}

class _AddSlotFormState extends State<AddSlotForm> {
  final _formKey = GlobalKey<FormState>();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _saveSlot() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // TODO: Implement create slot API
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      widget.onSlotAdded();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Slot added successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add Time Slot',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Service: ${widget.service.name}',
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              'Date: ${Formatters.formatDate(widget.selectedDate)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _startTimeController,
                    label: 'Start Time',
                    prefixIcon: Icons.access_time,
                    hintText: '09:00',
                    validator: Validators.validateTime,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: _endTimeController,
                    label: 'End Time',
                    prefixIcon: Icons.access_time,
                    hintText: '10:00',
                    validator: Validators.validateTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Add Slot',
                    onPressed: _saveSlot,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class EditSlotForm extends StatefulWidget {
  final Slot slot;
  final VoidCallback onSlotUpdated;

  const EditSlotForm({
    Key? key,
    required this.slot,
    required this.onSlotUpdated,
  }) : super(key: key);

  @override
  State<EditSlotForm> createState() => _EditSlotFormState();
}

class _EditSlotFormState extends State<EditSlotForm> {
  final _formKey = GlobalKey<FormState>();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimeController.text = widget.slot.startTime;
    _endTimeController.text = widget.slot.endTime;
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _updateSlot() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // TODO: Implement update slot API
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      widget.onSlotUpdated();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Slot updated successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Edit Time Slot',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _startTimeController,
                    label: 'Start Time',
                    prefixIcon: Icons.access_time,
                    validator: Validators.validateTime,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: _endTimeController,
                    label: 'End Time',
                    prefixIcon: Icons.access_time,
                    validator: Validators.validateTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Update Slot',
                    onPressed: _updateSlot,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}