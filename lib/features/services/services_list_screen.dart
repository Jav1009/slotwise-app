// lib/features/services/services_list_screen.dart
// Browse available services

// lib/features/services/services_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/service_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/service_model.dart';
import 'service_detail_screen.dart';

// ── Sort options ──────────────────────────────────────────────
enum _SortOption { none, priceLow, priceHigh, durationLow, durationHigh }

extension _SortLabel on _SortOption {
  String get label {
    switch (this) {
      case _SortOption.none:         return 'Default';
      case _SortOption.priceLow:     return 'Price: Low → High';
      case _SortOption.priceHigh:    return 'Price: High → Low';
      case _SortOption.durationLow:  return 'Duration: Short → Long';
      case _SortOption.durationHigh: return 'Duration: Long → Short';
    }
  }
}

class ServicesListScreen extends StatefulWidget {
  const ServicesListScreen({super.key});

  @override
  State<ServicesListScreen> createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends State<ServicesListScreen> {
  final _searchCtrl = TextEditingController();

  // ── Filter state ──────────────────────────────────────────
  String       _query       = '';
  RangeValues  _priceRange  = const RangeValues(0, 1000);
  RangeValues  _durRange    = const RangeValues(0, 300);   // minutes
  _SortOption  _sort        = _SortOption.none;
  bool         _filterOpen  = false;

  // Dynamic max values computed from the actual service list
  double _maxPrice = 1000;
  double _maxDur   = 300;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceProvider>().fetchServices().then((_) {
        _initRanges();
      });
    });
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _initRanges() {
    final services = context.read<ServiceProvider>().services;
    if (services.isEmpty) return;
    final maxP = services.map((s) => s.price).reduce((a, b) => a > b ? a : b);
    final maxD = services
        .map((s) => s.durationMinutes.toDouble())
        .reduce((a, b) => a > b ? a : b);
    setState(() {
      _maxPrice    = maxP.ceilToDouble();
      _maxDur      = maxD.ceilToDouble();
      _priceRange  = RangeValues(0, _maxPrice);
      _durRange    = RangeValues(0, _maxDur);
    });
  }

  // ── Filter + sort pipeline ────────────────────────────────
  List<ServiceModel> _apply(List<ServiceModel> all) {
    var list = all.where((s) {
      final matchName  = _query.isEmpty ||
          s.name.toLowerCase().contains(_query);
      final matchPrice = s.price >= _priceRange.start &&
          s.price <= _priceRange.end;
      final matchDur   = s.durationMinutes >= _durRange.start &&
          s.durationMinutes <= _durRange.end;
      return matchName && matchPrice && matchDur;
    }).toList();

    switch (_sort) {
      case _SortOption.priceLow:
        list.sort((a, b) => a.price.compareTo(b.price));
      case _SortOption.priceHigh:
        list.sort((a, b) => b.price.compareTo(a.price));
      case _SortOption.durationLow:
        list.sort((a, b) => a.durationMinutes.compareTo(b.durationMinutes));
      case _SortOption.durationHigh:
        list.sort((a, b) => b.durationMinutes.compareTo(a.durationMinutes));
      case _SortOption.none:
        break;
    }
    return list;
  }

  bool get _filtersActive =>
      _query.isNotEmpty ||
      _priceRange.start > 0 ||
      _priceRange.end < _maxPrice ||
      _durRange.start > 0 ||
      _durRange.end < _maxDur ||
      _sort != _SortOption.none;

  void _clearFilters() {
    setState(() {
      _searchCtrl.clear();
      _query      = '';
      _priceRange = RangeValues(0, _maxPrice);
      _durRange   = RangeValues(0, _maxDur);
      _sort       = _SortOption.none;
    });
  }

  // ── Sort bottom sheet ─────────────────────────────────────
  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Sort By',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._SortOption.values.map((opt) => RadioListTile<_SortOption>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(opt.label),
                    value: opt,
                    groupValue: _sort,
                    activeColor: AppColors.primary,
                    onChanged: (v) {
                      setState(() => _sort = v!);
                      setModal(() {});
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        actions: [
          // Sort button
          IconButton(
            icon: Icon(
              Icons.sort_rounded,
              color: _sort != _SortOption.none
                  ? AppColors.accent
                  : Colors.white,
            ),
            tooltip: 'Sort',
            onPressed: _showSortSheet,
          ),
          // Filter toggle
          IconButton(
            icon: Icon(
              _filterOpen
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
              color: (_filtersActive && !_filterOpen)
                  ? AppColors.accent
                  : Colors.white,
            ),
            tooltip: 'Filter',
            onPressed: () =>
                setState(() => _filterOpen = !_filterOpen),
          ),
        ],
      ),
      body: Consumer<ServiceProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.services.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.services.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Failed to load services',
                      style: TextStyle(
                          fontSize: 18, color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: provider.fetchServices,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final filtered = _apply(provider.services);

          return Column(
            children: [
              // ── Search bar ─────────────────────────────────
              Container(
                color: isDark
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
                padding:
                    const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search services...',
                    prefixIcon:
                        const Icon(Icons.search_rounded),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF2C2C2C)
                        : AppColors.background,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),

              // ── Expandable filter panel ────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _filterOpen
                    ? _FilterPanel(
                        maxPrice:   _maxPrice,
                        maxDur:     _maxDur,
                        priceRange: _priceRange,
                        durRange:   _durRange,
                        onPriceChanged: (v) =>
                            setState(() => _priceRange = v),
                        onDurChanged: (v) =>
                            setState(() => _durRange = v),
                      )
                    : const SizedBox.shrink(),
              ),

              // ── Active filter chips + clear ────────────────
              if (_filtersActive)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  color: isDark
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                  child: Row(
                    children: [
                      Text(
                        '${filtered.length} result${filtered.length == 1 ? '' : 's'}',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: const Text('Clear filters',
                            style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                            padding: EdgeInsets.zero),
                      ),
                    ],
                  ),
                ),

              // ── List ──────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 64,
                                color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              _filtersActive
                                  ? 'No services match your filters'
                                  : 'No services available',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary),
                            ),
                            if (_filtersActive) ...[
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _clearFilters,
                                child: const Text('Clear filters'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.fetchServices(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final svc = filtered[i];
                            return _ServiceCard(
                              service: svc,
                              onTap: () {
                                provider.selectService(svc);
                                Navigator.of(ctx).push(MaterialPageRoute(
                                  builder: (_) =>
                                      const ServiceDetailScreen(),
                                ));
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Filter panel ──────────────────────────────────────────────

class _FilterPanel extends StatelessWidget {
  final double       maxPrice, maxDur;
  final RangeValues  priceRange, durRange;
  final ValueChanged<RangeValues> onPriceChanged, onDurChanged;

  const _FilterPanel({
    required this.maxPrice,
    required this.maxDur,
    required this.priceRange,
    required this.durRange,
    required this.onPriceChanged,
    required this.onDurChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price range
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Price Range',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              Text(
                '\$${priceRange.start.toStringAsFixed(0)} – \$${priceRange.end.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.primary),
              ),
            ],
          ),
          RangeSlider(
            values: priceRange,
            min: 0,
            max: maxPrice,
            divisions: maxPrice > 0 ? maxPrice.toInt() : 1,
            activeColor: AppColors.primary,
            onChanged: onPriceChanged,
          ),

          const SizedBox(height: 4),

          // Duration range
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Duration',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              Text(
                '${durRange.start.toStringAsFixed(0)} – ${durRange.end.toStringAsFixed(0)} min',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.primary),
              ),
            ],
          ),
          RangeSlider(
            values: durRange,
            min: 0,
            max: maxDur,
            divisions: maxDur > 0 ? maxDur.toInt() : 1,
            activeColor: AppColors.primary,
            onChanged: onDurChanged,
          ),
        ],
      ),
    );
  }
}

// ── Service card (unchanged visually) ─────────────────────────

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;

  const _ServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  image: service.imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(service.imageUrl!),
                          fit: BoxFit.cover)
                      : null,
                ),
                child: service.imageUrl == null
                    ? const Icon(Icons.spa,
                        size: 40, color: AppColors.primary)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.name,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    if (service.description != null)
                      Text(
                        service.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 16,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(service.formattedDuration,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                        const SizedBox(width: 16),
                        Text(service.formattedPrice,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}