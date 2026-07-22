import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../widgets/smart_search_bar.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  Map<String, dynamic>? _dashboardData;

  bool _isLoading = true;
  String _error = '';
  Timer? _refreshTimer;

  final List<String> _categories = ['Hospital', 'Bank', 'GovtOffice', 'College', 'Other'];

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _fetchDashboard(isRefresh: true));
  }

  Future<void> _fetchDashboard({bool isRefresh = false}) async {
    try {
      final data = await ApiService.getSuperAdminDashboard();
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !isRefresh) {
        setState(() {
          _error = 'Failed to load dashboard: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _showOnboardingDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => const ProviderOnboardingDialog(),
    );
    
    if (result == true) {
      _fetchDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _dashboardData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    if (_error.isNotEmpty && _dashboardData == null) {
      return Scaffold(body: Center(child: Text(_error)));
    }

    final data = _dashboardData!;
    
    final bankCount = data['bankCount'] ?? 0;
    final collegeCount = data['collegeCount'] ?? 0;
    final hospitalCount = data['hospitalCount'] ?? 0;
    final restaurantCount = data['restaurantCount'] ?? 0;
    
    final providers = data['providers'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SaaS Provider Panel'),
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Icon(Icons.cloud_sync, color: AppTheme.aiAccent),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() { _isLoading = true; _error = ''; });
              _fetchDashboard();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
              if (mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Platform Overview ──
            const Text(
              'Global Platform Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDarkColor),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage SaaS clients, onboarding, and platform users. Total Users: ${data['totalUsers']}',
              style: const TextStyle(fontSize: 13, color: AppTheme.textMutedColor),
            ),
            const SizedBox(height: 20),

            // ── Stats Summary Row ──
            Row(
              children: [
                Expanded(child: _buildPlatformStat('Banks', '$bankCount', AppTheme.bankColor)),
                const SizedBox(width: 8),
                Expanded(child: _buildPlatformStat('Colleges', '$collegeCount', AppTheme.collegeColor)),
                const SizedBox(width: 8),
                Expanded(child: _buildPlatformStat('Hospitals', '$hospitalCount', AppTheme.hospitalColor)),
                const SizedBox(width: 8),
                Expanded(child: _buildPlatformStat('Restaurants', '$restaurantCount', AppTheme.restaurantColor)),
              ],
            ),
            const SizedBox(height: 24),

            // ── Onboard Button ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _showOnboardingDialog,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add New Service Provider & Admins', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.aiAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Active Service Providers ──
            const Text(
              'Active Platform Clients',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textDarkColor),
            ),
            const SizedBox(height: 12),
            if (providers.isEmpty)
              const Center(child: Text('No providers found', style: TextStyle(color: AppTheme.textMutedColor)))
            else
              ...providers.map((p) => _buildClientTile(p)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMutedColor)),
        ],
      ),
    );
  }

  Future<void> _handleDeleteProvider(String providerId, String providerName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Provider'),
        content: Text('Are you sure you want to completely remove $providerName and their Admin user?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        setState(() => _isLoading = true);
        await ApiService.deleteProvider(providerId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Provider removed.'), backgroundColor: AppTheme.successColor));
          _fetchDashboard();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.errorColor));
        }
      }
    }
  }

  Widget _buildClientTile(Map<String, dynamic> p) {
    final categoryRaw = p['category'];
    int categoryInt = 0;
    if (categoryRaw is int) {
      categoryInt = categoryRaw;
    } else if (categoryRaw is String) {
      switch (categoryRaw.toLowerCase()) {
        case 'bank': categoryInt = 1; break;
        case 'govtoffice': categoryInt = 2; break;
        case 'college': categoryInt = 3; break;
        case 'restaurant': categoryInt = 4; break;
        case 'hotel': categoryInt = 5; break;
        case 'other': categoryInt = 6; break;
        case 'hospital':
        default: categoryInt = 0; break;
      }
    }
    
    Color badgeColor;
    IconData icon;
    String categoryName;

    switch (categoryInt) {
      case 1:
        badgeColor = AppTheme.bankColor;
        icon = Icons.account_balance;
        categoryName = 'Bank';
        break;
      case 2:
        badgeColor = AppTheme.govtColor;
        icon = Icons.account_balance_outlined;
        categoryName = 'Govt Office';
        break;
      case 3:
        badgeColor = AppTheme.collegeColor;
        icon = Icons.school;
        categoryName = 'College';
        break;
      case 4:
        badgeColor = AppTheme.restaurantColor;
        icon = Icons.restaurant;
        categoryName = 'Restaurant';
        break;
      case 0:
      default:
        badgeColor = AppTheme.hospitalColor;
        icon = Icons.local_hospital;
        categoryName = 'Hospital';
        break;
    }

    final adminEmail = p['adminEmail'] ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: badgeColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['name'] ?? 'Unknown', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textDarkColor)),
                const SizedBox(height: 4),
                SelectableText('Email: $adminEmail', style: const TextStyle(fontSize: 12, color: AppTheme.textMutedColor)),
                const SizedBox(height: 2),
                SelectableText('Password: ${(p['name'] ?? '').toString().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase()}@123', style: const TextStyle(fontSize: 12, color: AppTheme.textMutedColor)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              categoryName.toUpperCase(),
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: badgeColor),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.copy, color: AppTheme.primaryColor, size: 20),
            tooltip: 'Copy Credentials',
            onPressed: () {
              final pwd = '${(p['name'] ?? '').toString().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase()}@123';
              Clipboard.setData(ClipboardData(text: 'Email: $adminEmail\nPassword: $pwd'));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Credentials copied to clipboard')));
            },
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 20),
            onPressed: () => _handleDeleteProvider(p['id'], p['name']),
          ),
        ],
      ),
    );
  }
}

class ProviderOnboardingDialog extends StatefulWidget {
  const ProviderOnboardingDialog({super.key});

  @override
  State<ProviderOnboardingDialog> createState() => _ProviderOnboardingDialogState();
}

class _ProviderOnboardingDialogState extends State<ProviderOnboardingDialog> {
  List<dynamic> _places = [];
  bool _isLoading = false;
  String _error = '';
  String _selectedCategory = 'All';
  Timer? _debounce;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _searchPlaces('');
  }

  Future<void> _searchPlaces(String query, {String? category}) async {
    final catToUse = category ?? _selectedCategory;

    setState(() { _isLoading = true; _error = ''; });
    try {
      final data = await ApiService.getPlaces(
        query: query, 
        category: catToUse == 'All' ? null : catToUse, 
        pageSize: 10
      );
      if (mounted) {
        setState(() {
          _places = data['places'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to search places';
          _isLoading = false;
        });
      }
    }
  }


  void _onCategorySelected(String category) {
    setState(() => _selectedCategory = category);
    _searchPlaces(_lastQuery, category: category);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _onboardPlace(Map<String, dynamic> place) async {
    try {
      final result = await ApiService.createProvider(place['id'].toString());
      if (mounted) {
        final creds = result['credentials'];
        Navigator.pop(context, true);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Access Granted!', style: TextStyle(color: AppTheme.successColor)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${place['name']} has been onboarded.'),
                const SizedBox(height: 16),
                const Text('Share these credentials with the Org Admin:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SelectableText('Email: ${creds['email']}'),
                SelectableText('Password: ${creds['password']}'),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.errorColor)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Onboard a Business', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Text('Search the dataset to give access to an organization.', style: TextStyle(color: AppTheme.textMutedColor)),
            const SizedBox(height: 16),
            // ── Smart Search Bar ──
            SmartSearchBar(
              onPlaceSelected: (place) => _onboardPlace(place),
              onQuerySubmitted: (query) {
                _lastQuery = query;
                _searchPlaces(query);
              },
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Hospital', 'Bank', 'College', 'Restaurant'].map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: _selectedCategory == cat,
                      onSelected: (selected) => _onCategorySelected(cat),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                      ? Center(child: Text(_error, style: const TextStyle(color: AppTheme.errorColor)))
                      : _places.isEmpty
                          ? const Center(child: Text('No results. Type and press Enter.', style: TextStyle(color: AppTheme.textMutedColor)))
                          : ListView.separated(
                              itemCount: _places.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, index) {
                                final p = _places[index];
                                return ListTile(
                                  title: Text(p['name']),
                                  subtitle: Text('${p['category']} • ${p['address']}'),
                                  trailing: ElevatedButton(
                                    onPressed: () => _onboardPlace(p),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                                    child: const Text('Give Access'),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
