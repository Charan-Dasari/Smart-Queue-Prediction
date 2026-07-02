import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../models/models.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  DashboardStats? _stats;
  QueueToken? _activeToken;
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final statsData = await ApiService.getUserDashboard();
      final tokenData = await ApiService.getMyToken();
      final notifData = await ApiService.getNotifications();

      if (mounted) {
        setState(() {
          _stats = DashboardStats.fromJson(statsData);
          if (tokenData != null) {
            _activeToken = QueueToken.fromJson(tokenData);
          }
          _notifications = notifData
              .map((n) => AppNotification.fromJson(n))
              .toList()
              .cast<AppNotification>();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // ── Greeting Header ──
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getGreeting(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textMutedColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.name ?? 'User',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.push('/notifications'),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Theme.of(context).dividerColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Icon(Icons.notifications_outlined, color: Theme.of(context).textTheme.bodyLarge?.color, size: 22),
                                  ),
                                  if (_notifications.any((n) => !n.isRead))
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppTheme.errorColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Search Bar ──
                      GestureDetector(
                        onTap: () => context.push('/services'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                          child: const Row(
                            children: [
                              Icon(Icons.search, color: AppTheme.textMutedColor, size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Search Hospital, Bank, Government Office...',
                                  style: TextStyle(fontSize: 14, color: AppTheme.textLightColor),
                                ),
                              ),
                              Icon(Icons.tune, color: AppTheme.textLightColor, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Current Queue Status Card ──
                      if (_activeToken != null)
                        GestureDetector(
                          onTap: () => context.push('/tracking/${_activeToken!.id}'),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.successColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: AppTheme.successColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Text(
                                            'Active Queue',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.successColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white.withOpacity(0.6)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Token: ${_activeToken!.tokenNumber}',
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _activeToken!.providerName,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white.withOpacity(0.7),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // ── Queue Status Indicator ──
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.people_outline, color: Colors.white, size: 12),
                                              SizedBox(width: 6),
                                              Text(
                                                'Position',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_activeToken!.queuePosition}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Progress bar (simulated logic for demo)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: _activeToken!.queuePosition > 0 ? (1.0 / _activeToken!.queuePosition).clamp(0.1, 1.0) : 1.0,
                                    backgroundColor: Colors.white.withOpacity(0.15),
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentLight),
                                    minHeight: 4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Estimated wait: ~${_activeToken!.estimatedWaitMinutes} min',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_activeToken != null) const SizedBox(height: 24),

                      // ── Quick Actions ──
                      Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: _buildQuickAction(context, Icons.calendar_today_outlined, 'Book\nAppointment', AppTheme.primaryColor, () => context.push('/services'))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildQuickAction(context, Icons.confirmation_number_outlined, 'My\nTokens', AppTheme.accentColor, () => context.push('/token/${_activeToken?.id ?? "none"}'))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildQuickAction(context, Icons.history, 'History', AppTheme.warningColor, () => context.push('/history'))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildQuickAction(context, Icons.location_on_outlined, 'Nearby\nCenters', AppTheme.hospitalColor, () => context.push('/services'))),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ── Available Services ──
                      Row(
                        children: [
                          Text(
                            'Services',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => context.push('/services'),
                            child: const Text(
                              'View All',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 110,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildServiceCard(context, Icons.local_hospital, 'Hospital', AppTheme.hospitalColor, () => context.push('/services')),
                            _buildServiceCard(context, Icons.account_balance, 'Bank', AppTheme.bankColor, () => context.push('/services')),
                            _buildServiceCard(context, Icons.account_balance_outlined, 'Govt Office', AppTheme.govtColor, () => context.push('/services')),
                            _buildServiceCard(context, Icons.school_outlined, 'College', AppTheme.collegeColor, () => context.push('/services')),
                            _buildServiceCard(context, Icons.more_horiz, 'Other', AppTheme.otherColor, () => context.push('/services')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── User Statistics ──
                      Text(
                        'Your Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: _buildStatCard('${_stats?.totalAppointments ?? 0}', 'Total\nAppointments', AppTheme.infoColor)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildStatCard('${_stats?.completedVisits ?? 0}', 'Completed\nVisits', AppTheme.successColor)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildStatCard(_formatTimeSaved(_stats?.timeSavedMinutes ?? 0), 'Time\nSaved', AppTheme.accentColor)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildStatCard('${_stats?.avgWaitMinutes ?? 0}m', 'Avg Wait\nTime', AppTheme.warningColor)),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ── Recent Notifications ──
                      Row(
                        children: [
                          Text(
                            'Notifications',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => context.push('/notifications'),
                            child: const Text(
                              'See All',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._notifications.take(3).map((notif) => _buildNotificationTile(
                            context,
                            _getNotifIcon(notif.type),
                            _getNotifColor(notif.type),
                            notif.title,
                            notif.body,
                            '${notif.timestamp.hour}:${notif.timestamp.minute.toString().padLeft(2, '0')}',
                          )),
                      if (_notifications.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text('No new notifications.', style: TextStyle(color: AppTheme.textMutedColor)),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              context.push('/history');
              break;
            case 2:
              context.push('/notifications');
              break;
            case 3:
              context.push('/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), activeIcon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  IconData _getNotifIcon(NotificationType type) {
    switch (type) {
      case NotificationType.booking: return Icons.check_circle_outline;
      case NotificationType.queue: return Icons.access_time;
      case NotificationType.ai: return Icons.auto_awesome;
      default: return Icons.notifications_none;
    }
  }

  Color _getNotifColor(NotificationType type) {
    switch (type) {
      case NotificationType.booking: return AppTheme.successColor;
      case NotificationType.queue: return AppTheme.warningColor;
      case NotificationType.ai: return AppTheme.aiAccent;
      default: return AppTheme.primaryColor;
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌅';
    if (hour < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌙';
  }

  String _formatTimeSaved(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
    return '${minutes}m';
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.9) : color,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, color: AppTheme.textMutedColor, height: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.9) : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, IconData icon, Color color, String title, String subtitle, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMutedColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: const TextStyle(fontSize: 11, color: AppTheme.textLightColor),
          ),
        ],
      ),
    );
  }
}
