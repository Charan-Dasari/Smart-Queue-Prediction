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
    final theme = Theme.of(context);

    if (_isLoading && _dashboardData == null) {
      return const UserThemeWrapper(
        child: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    
    if (_error.isNotEmpty && _dashboardData == null) {
      return UserThemeWrapper(
        child: Scaffold(
          appBar: AppBar(title: const Text('Super Admin Console')),
          body: Center(child: Text(_error)),
        ),
      );
    }

    final data = _dashboardData!;
    
    final bankCount = data['bankCount'] ?? 0;
    final collegeCount = data['collegeCount'] ?? 0;
    final hospitalCount = data['hospitalCount'] ?? 0;
    final restaurantCount = data['restaurantCount'] ?? 0;
    
    final providers = data['providers'] as List<dynamic>? ?? [];

    return UserThemeWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SaaS Multi-Tenant Console'),
          actions: [
            ValueListenableBuilder<ThemeMode>(
              valueListenable: AppTheme.themeNotifier,
              builder: (context, mode, _) {
                final isDarkMode = mode == ThemeMode.dark;
                return IconButton(
                  icon: Icon(isDarkMode ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined, size: 22),
                  onPressed: () {
                    final userId = Provider.of<AuthProvider>(context, listen: false).user?.id;
                    AppTheme.setUserTheme(userId, !isDarkMode);
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 22),
              onPressed: () {
                setState(() { _isLoading = true; _error = ''; });
                _fetchDashboard();
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded, size: 22),
              onPressed: () async {
                await Provider.of<AuthProvider>(context, listen: false).logout();
                if (mounted) context.go('/login');
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Super Admin Hero Banner ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.aiGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.aiAccent.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_user_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'GLOBAL SUPER ADMIN',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.8),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.cloud_done_rounded, color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Global Platform Controller',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Multi-Tenant SaaS Providers • Total Registered Users: ${data['totalUsers']}',
                      style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Category Stats Grid ──
              Text(
                'Tenant Sector Distribution',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _buildPlatformStat(context, 'Banks', '$bankCount', AppTheme.bankColor, Icons.account_balance_rounded)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildPlatformStat(context, 'Colleges', '$collegeCount', AppTheme.collegeColor, Icons.school_rounded)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildPlatformStat(context, 'Hospitals', '$hospitalCount', AppTheme.hospitalColor, Icons.local_hospital_rounded)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildPlatformStat(context, 'Dining', '$restaurantCount', AppTheme.restaurantColor, Icons.restaurant_rounded)),
                ],
              ),
              const SizedBox(height: 24),

              // ── Onboard Button ──
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _showOnboardingDialog,
                  icon: const Icon(Icons.add_business_rounded, size: 22),
                  label: const Text('Onboard New Provider Organization', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Active Client List ──
              Row(
                children: [
                  Text(
                    'Active Tenant Providers',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${providers.length} Registered',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primaryColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (providers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(30),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Center(
                    child: Text('No active providers onboarded yet.', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                  ),
                )
              else
                ...providers.map((p) => _buildClientTile(context, p)),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformStat(BuildContext context, String label, String value, Color color, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.textTheme.bodyMedium?.color)),
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

  Widget _buildClientTile(BuildContext context, Map<String, dynamic> p) {
    final theme = Theme.of(context);
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
        icon = Icons.account_balance_rounded;
        categoryName = 'Bank';
        break;
      case 2:
        badgeColor = AppTheme.govtColor;
        icon = Icons.account_balance_outlined;
        categoryName = 'Govt Office';
        break;
      case 3:
        badgeColor = AppTheme.collegeColor;
        icon = Icons.school_rounded;
        categoryName = 'College';
        break;
      case 4:
        badgeColor = AppTheme.restaurantColor;
        icon = Icons.restaurant_rounded;
        categoryName = 'Restaurant';
        break;
      case 0:
      default:
        badgeColor = AppTheme.hospitalColor;
        icon = Icons.local_hospital_rounded;
        categoryName = 'Hospital';
        break;
    }

    final adminEmail = p['adminEmail'] ?? 'N/A';
    final rawName = (p['name'] ?? '').toString();
    final pwd = '${rawName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase()}@123';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Header Row: Icon, Name, Category Badge, Delete ──
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: badgeColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  rawName,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  categoryName.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: badgeColor),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _handleDeleteProvider(p['id'], rawName),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Credentials Box ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? AppTheme.darkBorder.withOpacity(0.4)
                  : const Color(0xFFF8F7FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.key_rounded, size: 14, color: AppTheme.primaryColor),
                    const SizedBox(width: 6),
                    const Text(
                      'Admin Credentials',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primaryColor, letterSpacing: 0.5),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: 'Email: $adminEmail\nPassword: $pwd'));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Credentials copied to clipboard')));
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy_rounded, color: AppTheme.primaryColor, size: 13),
                          SizedBox(width: 4),
                          Text('Copy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  'Email: $adminEmail',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color),
                ),
                const SizedBox(height: 3),
                SelectableText(
                  'Password: $pwd',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodyMedium?.color),
                ),
              ],
            ),
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
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 640 ? 600.0 : screenWidth * 0.92;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: dialogWidth,
        height: 620,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Onboard Organization',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: theme.textTheme.bodyLarge?.color),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              ],
            ),
            Text(
              'Search directory to grant provider platform access & credentials.',
              style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color),
            ),
            const SizedBox(height: 14),
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
                      label: Text(cat, style: const TextStyle(fontSize: 12)),
                      selected: _selectedCategory == cat,
                      onSelected: (selected) => _onCategorySelected(cat),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                      ? Center(child: Text(_error, style: const TextStyle(color: AppTheme.errorColor)))
                      : _places.isEmpty
                          ? Center(child: Text('No results found. Type to search.', style: TextStyle(color: theme.textTheme.bodyMedium?.color)))
                          : ListView.separated(
                              itemCount: _places.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final p = _places[index];
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppTheme.getBorderColor(context)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              p['name'] ?? 'Unknown',
                                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () => _onboardPlace(p),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.successColor,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            child: const Text('Grant Access', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${p['category']} • ${p['address']}',
                                        style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color),
                                      ),
                                    ],
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

