import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import 'package:provider/provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    try {
      final data = await ApiService.getAdminDashboard();
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load dashboard data: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    if (_isLoading) {
      return const UserThemeWrapper(
        child: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    
    if (_error.isNotEmpty || _dashboardData == null) {
      return UserThemeWrapper(
        child: Scaffold(
          appBar: AppBar(title: const Text('Admin Workspace')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
                const SizedBox(height: 12),
                Text(_error.isNotEmpty ? _error : 'No data found'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() { _isLoading = true; _error = ''; });
                    _fetchDashboard();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final providerName = _dashboardData!['providerName'] ?? 'Provider Console';
    final categoryStr = (_dashboardData!['providerCategory'] ?? 'other').toString().toLowerCase();
    
    Color categoryColor = AppTheme.hospitalColor;
    if (categoryStr == 'bank') categoryColor = AppTheme.bankColor;
    else if (categoryStr == 'restaurant') categoryColor = Colors.orange;
    else if (categoryStr == 'college') categoryColor = Colors.purple;
    else if (categoryStr == 'govtoffice') categoryColor = AppTheme.govtColor;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return UserThemeWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Workspace'),
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
                await auth.logout();
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
              // ── Admin Hero Banner ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    )
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_outlined, color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                categoryStr.toUpperCase(),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.8),
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
                          child: const Icon(Icons.bolt, color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome back, ${user.name}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Provider Console • $providerName',
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Queue Health Widget ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.monitor_heart_outlined, size: 20, color: AppTheme.successColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Queue Operations Health',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(radius: 3, backgroundColor: AppTheme.successColor),
                              SizedBox(width: 4),
                              Text('Live', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.successColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _dashboardData!['activeQueues'] > 0 ? 0.75 : 0.1,
                        backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.successColor),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_dashboardData!['activeQueues']} Active Queue Streams', style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
                        const Text('Optimal Throughput', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.successColor)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Metrics Grid ──
              Text(
                'Real-time Operational Metrics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _buildMetricCard(context, 'Served Today', '${_dashboardData!['servedToday']}', Icons.check_circle, AppTheme.successColor)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildMetricCard(context, 'Waiting in Queue', '${_dashboardData!['activeQueues']}', Icons.people_alt, AppTheme.infoColor)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildMetricCard(context, 'Avg Wait Time', '${_dashboardData!['avgWaitMinutes']} mins', Icons.timer, AppTheme.warningColor)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildMetricCard(context, 'Satisfaction', '${_dashboardData!['satisfactionScore'] ?? "4.9/5"}', Icons.star_rounded, AppTheme.accentColor)),
                ],
              ),
              const SizedBox(height: 28),

              // ── Quick Actions Grid ──
              Text(
                'Management Controls',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 14),
              _buildActionTile(context, Icons.queue_play_next, 'Queue Control Center', 'Monitor live tokens & counter dispatch', AppTheme.primaryColor, '/admin/queue'),
              _buildActionTile(context, Icons.event_available, 'Appointments Manager', 'Approve, reschedule & cancel bookings', AppTheme.successColor, '/admin/appointments'),
              _buildActionTile(context, Icons.miscellaneous_services_rounded, 'Services & Categories', 'Manage services & counter allocations', AppTheme.warningColor, '/admin/services'),
              _buildActionTile(context, Icons.badge_outlined, 'Staff & Counters', 'Assign staff to counters & track status', AppTheme.accentColor, '/admin/staff'),
              _buildActionTile(context, Icons.insights_rounded, 'Analytics & Reports', 'View traffic, velocity & peak hours', AppTheme.hospitalColor, '/admin/analytics'),
              _buildActionTile(context, Icons.auto_awesome, 'AI Wait Predictions', 'AI forecasting & smart slot optimizer', AppTheme.aiAccent, '/admin/predictions'),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, IconData icon, String title, String subtitle, Color color, String route) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(route),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 20, color: theme.hintColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

