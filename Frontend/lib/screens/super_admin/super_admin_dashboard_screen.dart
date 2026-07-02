import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';

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

  void _registerProviderDialog() {
    // In a real app, this would use a dedicated endpoint to create a provider and its admin user.
    // For now, since we only have endpoints for viewing dashboard, we'll just show an informative dialog.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Provider API Not Implemented'),
        content: const Text('The backend does not have an endpoint to onboard a new provider yet.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      ),
    );
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
    final govtCount = data['govtOfficeCount'] ?? 0;
    
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
                Expanded(child: _buildPlatformStat('Govt Offices', '$govtCount', AppTheme.govtColor)),
              ],
            ),
            const SizedBox(height: 24),

            // ── Onboard Button ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _registerProviderDialog,
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

  Widget _buildClientTile(Map<String, dynamic> p) {
    // Enum values: 0=Hospital, 1=Bank, 2=GovtOffice, 3=College, 4=Other
    final categoryInt = p['category'] ?? 0;
    
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
                const SizedBox(height: 2),
                Text('Admin: $adminEmail', style: const TextStyle(fontSize: 12, color: AppTheme.textMutedColor)),
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
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Delete not implemented in API'), behavior: SnackBarBehavior.floating),
              );
            },
          ),
        ],
      ),
    );
  }
}
