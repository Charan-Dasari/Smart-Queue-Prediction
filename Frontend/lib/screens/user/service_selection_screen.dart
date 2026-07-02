import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';

class ServiceSelectionScreen extends StatefulWidget {
  const ServiceSelectionScreen({super.key});

  @override
  State<ServiceSelectionScreen> createState() => _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState extends State<ServiceSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  List<ServiceProviderInfo> _providers = [];
  bool _isLoading = true;
  String _error = '';

  final List<String> _filters = [
    'All',
    'Rating',
    'Distance',
    'Waiting Time',
    'AI Recommended'
  ];

  @override
  void initState() {
    super.initState();
    _fetchProviders();
  }

  Future<void> _fetchProviders() async {
    try {
      final data = await ApiService.getProviders();
      if (mounted) {
        setState(() {
          _providers = data.map((e) => ServiceProviderInfo.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load providers';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select Service')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select Service')),
        body: Center(child: Text(_error)),
      );
    }

    // Dynamically filter providers based on search query
    final query = _searchController.text.toLowerCase();
    var filteredProviders = _providers.where((p) {
      final matchesQuery = p.name.toLowerCase().contains(query) ||
          p.category.name.toLowerCase().contains(query) ||
          p.address.toLowerCase().contains(query);
      return matchesQuery;
    }).toList();

    // Sort providers based on filters
    if (_selectedFilter == 'Rating') {
      filteredProviders.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_selectedFilter == 'Distance') {
      filteredProviders.sort((a, b) => a.address.compareTo(b.address)); // Lexical fallback
    } else if (_selectedFilter == 'Waiting Time') {
      filteredProviders.sort((a, b) => a.estimatedWaitMinutes.compareTo(b.estimatedWaitMinutes));
    }

    final collegeCount = _providers.where((p) => p.category == ServiceCategory.college).length;
    final bankCount = _providers.where((p) => p.category == ServiceCategory.bank).length;
    final hospitalCount = _providers.where((p) => p.category == ServiceCategory.hospital).length;
    final govtCount = _providers.where((p) => p.category == ServiceCategory.governmentOffice).length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Select Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Search Bar ──
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search services or providers...',
                  prefixIcon: Icon(Icons.search, color: AppTheme.textMutedColor, size: 20),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Filter Chips ──
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isActive = _selectedFilter == filter;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.primaryColor : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive ? AppTheme.primaryColor : AppTheme.borderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (filter == 'AI Recommended') ...[
                            Icon(Icons.auto_awesome, size: 12, color: isActive ? Colors.white : AppTheme.aiAccent),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            filter,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isActive ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // ── Category List ──
            const Text(
              'Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),

            _buildCategoryCard(context, icon: Icons.local_hospital, title: 'Hospital', subtitle: '$hospitalCount providers nearby', color: AppTheme.hospitalColor, providerId: _providers.firstWhere((p) => p.category == ServiceCategory.hospital, orElse: () => _providers.first).id),
            _buildCategoryCard(context, icon: Icons.account_balance, title: 'Bank', subtitle: '$bankCount branches nearby', color: AppTheme.bankColor, providerId: _providers.firstWhere((p) => p.category == ServiceCategory.bank, orElse: () => _providers.first).id),
            _buildCategoryCard(context, icon: Icons.account_balance_outlined, title: 'Government Office', subtitle: '$govtCount offices nearby', color: AppTheme.govtColor, providerId: _providers.firstWhere((p) => p.category == ServiceCategory.governmentOffice, orElse: () => _providers.first).id),
            if (collegeCount > 0)
              _buildCategoryCard(context, icon: Icons.school_outlined, title: 'College', subtitle: '$collegeCount institutions nearby', color: AppTheme.collegeColor, providerId: _providers.firstWhere((p) => p.category == ServiceCategory.college).id),
            const SizedBox(height: 28),

            // ── Popular Providers ──
            const Text(
              'Popular Near You',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),

            ...filteredProviders.map((p) {
              Color waitColor = AppTheme.queueLow;
              String crowdLabel = 'Low';
              if (p.activeQueueCount > 8) {
                waitColor = AppTheme.queueHigh;
                crowdLabel = 'High';
              } else if (p.activeQueueCount > 4) {
                waitColor = AppTheme.queueMedium;
                crowdLabel = 'Medium';
              }
              return _buildProviderCard(
                context,
                name: p.name,
                category: p.category.name.toUpperCase(),
                rating: p.rating,
                distance: p.address,
                waitTime: '${p.estimatedWaitMinutes} min',
                waitColor: waitColor,
                crowdLabel: crowdLabel,
                crowdColor: waitColor,
                queueCount: p.activeQueueCount,
                providerId: p.id,
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required String providerId}) {
    return GestureDetector(
      onTap: () => context.push('/booking/$providerId'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: AppTheme.textMutedColor)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textLightColor),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(BuildContext context, {required String name, required String category, required double rating, required String distance, required String waitTime, required Color waitColor, required String crowdLabel, required Color crowdColor, required int queueCount, required String providerId}) {
    return GestureDetector(
      onTap: () => context.push('/booking/$providerId'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: waitColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: waitColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  rating.toString(),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.location_on_outlined, color: AppTheme.textMutedColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  distance,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textMutedColor),
                ),
              ],
            ),
            const Divider(height: 24, color: AppTheme.borderColor),
            Row(
              children: [
                Icon(Icons.access_time, color: waitColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Wait: $waitTime',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: waitColor),
                ),
                const Spacer(),
                Icon(Icons.people_outline, color: crowdColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  '$crowdLabel Crowd ($queueCount in queue)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: crowdColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
