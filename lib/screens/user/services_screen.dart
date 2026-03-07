import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/service_provider.dart';
import '../../widgets/service_card.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';
import '../../core/constants/routes.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({Key? key}) : super(key: key);

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ServiceProvider>(context, listen: false).fetchServices();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServiceProvider>(
      builder: (context, serviceProvider, child) {
        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
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

            // Services grid
            Expanded(
              child: serviceProvider.isLoading
                  ? const LoadingIndicator()
                  : serviceProvider.filteredServices.isEmpty
                      ? EmptyState(
                          icon: Icons.search_off,
                          message: 'No services found',
                          subtitle: serviceProvider.searchQuery.isNotEmpty
                              ? 'Try a different search term'
                              : 'Check back later for new services',
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: serviceProvider.filteredServices.length,
                          itemBuilder: (context, index) {
                            final service = serviceProvider.filteredServices[index];
                            return ServiceCard(
                              service: service,
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                  AppRoutes.serviceDetail,
                                  arguments: service.id,
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}