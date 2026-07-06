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
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_error.isNotEmpty || _dashboardData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Dashboard')),
        body: Center(child: Text(_error.isNotEmpty ? _error : 'No data found')),
      );
    }

    final providerName = _dashboardData!['providerName'] ?? 'Unknown Provider';
    final categoryStr = (_dashboardData!['providerCategory'] ?? 'other').toString().toLowerCase();
    
    Color categoryColor = AppTheme.hospitalColor;
    if (categoryStr == 'bank') categoryColor = AppTheme.bankColor;
    else if (categoryStr == 'restaurant') categoryColor = Colors.orange;
    else if (categoryStr == 'college') categoryColor = Colors.purple;
    else if (categoryStr == 'govtoffice') categoryColor = AppTheme.govtColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Icon(Icons.admin_panel_settings, color: categoryColor),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = '';
              });
              _fetchDashboard();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            onPressed: () async {
              await auth.logout();
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
            // ── Welcome ──
            Text(
              'Welcome, ${user.name}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDarkColor),
            ),
            const SizedBox(height: 4),
            Text(
              'Overview for $providerName today',
              style: const TextStyle(fontSize: 14, color: AppTheme.textMutedColor),
            ),
            const SizedBox(height: 20),

            // ── Queue Health Widget ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.monitor_heart_outlined, size: 20, color: AppTheme.successColor),
                      const SizedBox(width: 8),
                      const Text('Queue Health', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textDarkColor)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.successColor, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            const Text('Live', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.successColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _dashboardData!['activeQueues'] > 0 ? 0.7 : 0.0,
                      backgroundColor: AppTheme.borderColor,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.successColor),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_dashboardData!['activeQueues']} Active Queues', style: const TextStyle(fontSize: 12, color: AppTheme.textMutedColor)),
                      const Text('Monitoring', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.successColor)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Today's Performance Summary ──
            const Text(
              'Today\'s Performance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textDarkColor),
            ),
            const SizedBox(height: 12),
            Row(
               children: [
                 Expanded(child: _buildPerfCard('Served', '${_dashboardData!['servedToday']}', Icons.check_circle_outline, AppTheme.successColor, null)),
                 const SizedBox(width: 10),
                 Expanded(child: _buildPerfCard('In Queue', '${_dashboardData!['activeQueues']}', Icons.people_outline, AppTheme.infoColor, null)),
               ],
             ),
             const SizedBox(height: 10),
             Row(
               children: [
                 Expanded(child: _buildPerfCard('Avg Wait', '${_dashboardData!['avgWaitMinutes']}m', Icons.access_time, AppTheme.warningColor, null)),
                 const SizedBox(width: 10),
                 Expanded(child: _buildPerfCard('Satisfaction', '${_dashboardData!['satisfactionScore']}', Icons.star_outline, AppTheme.accentColor, null)),
               ],
             ),
             const SizedBox(height: 24),

            // ── Summary Cards ──
            Row(
              children: [
                Expanded(child: _buildSummaryCard('Total\nAppointments', '${_dashboardData!['totalAppointmentsToday']}', Icons.calendar_today, AppTheme.infoColor)),
                const SizedBox(width: 12),
                Expanded(child: _buildSummaryCard('Today\'s\nVisitors', '${_dashboardData!['todayVisitors']}', Icons.trending_up, AppTheme.accentColor)),
              ],
            ),
            const SizedBox(height: 28),

            // ── Quick Actions ──
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDarkColor),
            ),
            const SizedBox(height: 14),
            _buildActionTile(context, Icons.queue, 'Queue Management', 'Manage current queues & tokens', AppTheme.infoColor, '/admin/queue'),
            _buildActionTile(context, Icons.event_note, 'Appointments', 'View & manage bookings', AppTheme.successColor, '/admin/appointments'),
            _buildActionTile(context, Icons.miscellaneous_services, 'Services', 'Add/edit/delete services', AppTheme.warningColor, '/admin/services'),
            _buildActionTile(context, Icons.group, 'Staff & Counters', 'Manage counters & staff', AppTheme.accentColor, '/admin/staff'),
            _buildActionTile(context, Icons.bar_chart, 'Analytics', 'View reports & trends', AppTheme.hospitalColor, '/admin/analytics'),
            _buildActionTile(context, Icons.auto_awesome, 'AI Predictions', 'Crowd & wait predictions', AppTheme.aiAccent, '/admin/predictions'),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildPerfCard(String label, String value, IconData icon, Color color, String? trend) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
                  if (trend != null) ...[
                    const SizedBox(width: 4),
                    Text(trend, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.successColor)),
                  ],
                ],
              ),
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMutedColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 14),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMutedColor, height: 1.3)),
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, IconData icon, String title, String subtitle, Color color, String route) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.borderColor)),
        child: Row(
          children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textDarkColor)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textMutedColor)),
            ])),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textLightColor),
          ],
        ),
      ),
    );
  }
}
