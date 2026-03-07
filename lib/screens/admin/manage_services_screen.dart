import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/service_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/formatters.dart';

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({Key? key}) : super(key: key);

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  final _searchController = TextEditingController();
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ServiceProvider>(context, listen: false)
          .fetchServices(includeInactive: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showServiceDialog({Service? service}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ServiceForm(service: service),
    ).then((_) {
      // Refresh services after modal closes
      Provider.of<ServiceProvider>(context, listen: false)
          .fetchServices(includeInactive: true);
    });
  }

  Future<void> _toggleServiceStatus(Service service) async {
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    final success = await serviceProvider.updateService(
      service.id,
      {'is_active': !service.isActive},
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            service.isActive 
                ? 'Service deactivated successfully' 
                : 'Service activated successfully',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServiceProvider>(
      builder: (context, serviceProvider, child) {
        return Column(
          children: [
            // Search and filter bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search services...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: serviceProvider.searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  serviceProvider.setSearchQuery('');
                                },
                              )
                            : null,
                      ),
                      onChanged: serviceProvider.setSearchQuery,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      _showInactive ? Icons.filter_alt : Icons.filter_alt_outlined,
                      color: _showInactive ? Theme.of(context).primaryColor : null,
                    ),
                    onPressed: () {
                      setState(() {
                        _showInactive = !_showInactive;
                      });
                    },
                    tooltip: 'Show inactive services',
                  ),
                ],
              ),
            ),

            // Services list
            Expanded(
              child: serviceProvider.isLoading
                  ? const LoadingIndicator()
                  : serviceProvider.filteredServices.isEmpty
                      ? EmptyState(
                          icon: Icons.spa,
                          message: 'No services found',
                          subtitle: _showInactive
                              ? 'Add your first service to get started'
                              : 'Try adjusting your filters',
                          buttonText: 'Add Service',
                          onButtonPressed: () => _showServiceDialog(),
                        )
                      : RefreshIndicator(
                          onRefresh: () => serviceProvider.fetchServices(
                            includeInactive: true,
                          ),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: serviceProvider.filteredServices.length,
                            itemBuilder: (context, index) {
                              final service = serviceProvider.filteredServices[index];
                              
                              // Filter by active/inactive
                              if (!_showInactive && !service.isActive) {
                                return const SizedBox.shrink();
                              }

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  children: [
                                    ListTile(
                                      leading: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: service.imageUrl != null
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  service.imageUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Icon(
                                                      Icons.spa,
                                                      color: Theme.of(context).primaryColor,
                                                    );
                                                  },
                                                ),
                                              )
                                            : Icon(
                                                Icons.spa,
                                                color: Theme.of(context).primaryColor,
                                              ),
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              service.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (!service.isActive)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Text(
                                                'Inactive',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                            service.description ?? 'No description',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size: 14,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                service.formattedDuration,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Icon(
                                                Icons.attach_money,
                                                size: 14,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                service.formattedPrice,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      isThreeLine: true,
                                      onTap: () => _showServiceDialog(service: service),
                                    ),
                                    ButtonBar(
                                      children: [
                                        TextButton(
                                          onPressed: () => _toggleServiceStatus(service),
                                          child: Text(
                                            service.isActive ? 'Deactivate' : 'Activate',
                                            style: TextStyle(
                                              color: service.isActive 
                                                  ? Colors.orange 
                                                  : Colors.green,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => _showServiceDialog(service: service),
                                          child: const Text('Edit'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),

            // FAB
            FloatingActionButton(
              onPressed: () => _showServiceDialog(),
              child: const Icon(Icons.add),
            ),
          ],
        );
      },
    );
  }
}

class ServiceForm extends StatefulWidget {
  final Service? service;

  const ServiceForm({Key? key, this.service}) : super(key: key);

  @override
  State<ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends State<ServiceForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      _nameController.text = widget.service!.name;
      _descriptionController.text = widget.service!.description ?? '';
      _durationController.text = widget.service!.durationMinutes.toString();
      _priceController.text = widget.service!.price.toString();
      _imageUrlController.text = widget.service!.imageUrl ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    final data = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.isNotEmpty 
          ? _descriptionController.text.trim() 
          : null,
      'duration_minutes': int.parse(_durationController.text),
      'price': double.parse(_priceController.text),
      'image_url': _imageUrlController.text.isNotEmpty 
          ? _imageUrlController.text.trim() 
          : null,
    };

    bool success;
    if (widget.service == null) {
      success = await serviceProvider.createService(data);
    } else {
      success = await serviceProvider.updateService(widget.service!.id, data);
    }

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.service == null 
                ? 'Service created successfully' 
                : 'Service updated successfully',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(serviceProvider.error ?? 'Failed to save service'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      serviceProvider.clearError();
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
              widget.service == null ? 'Add New Service' : 'Edit Service',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _nameController,
              label: 'Service Name',
              prefixIcon: Icons.spa,
              validator: Validators.validateName,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _descriptionController,
              label: 'Description',
              prefixIcon: Icons.description,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _durationController,
                    label: 'Duration (min)',
                    prefixIcon: Icons.timer,
                    keyboardType: TextInputType.number,
                    validator: Validators.validateDuration,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: _priceController,
                    label: 'Price',
                    prefixIcon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    validator: Validators.validatePrice,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _imageUrlController,
              label: 'Image URL (Optional)',
              prefixIcon: Icons.image,
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
                    text: widget.service == null ? 'Create' : 'Update',
                    onPressed: _saveService,
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