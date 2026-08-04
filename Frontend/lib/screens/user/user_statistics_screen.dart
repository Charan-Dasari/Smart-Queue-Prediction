import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';

class UserStatisticsScreen extends StatefulWidget {
  const UserStatisticsScreen({super.key});

  @override
  State<UserStatisticsScreen> createState() => _UserStatisticsScreenState();
}

class _UserStatisticsScreenState extends State<UserStatisticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final dashData = await ApiService.getUserDashboard();
      List<dynamic> historyData = [];
      try {
        historyData = await ApiService.getMyAppointments();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _stats = dashData;
          _history = historyData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return UserThemeWrapper(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => context.pop(),
          ),
          title: const Text('My Statistics'),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart_rounded, size: 14, color: AppTheme.successColor),
                  const SizedBox(width: 6),
                  Text('Live Stats', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.successColor)),
                ],
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Overview Cards ──
                      _buildOverviewSection(context),
                      const SizedBox(height: 28),

                      // ── Visit Completion Rate ──
                      _buildCompletionRateCard(context),
                      const SizedBox(height: 28),

                      // ── Time Saved Impact ──
                      _buildTimeSavedCard(context),
                      const SizedBox(height: 28),

                      // ── Appointment Breakdown ──
                      Text(
                        'Appointment Breakdown',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color),
                      ),
                      const SizedBox(height: 14),
                      _buildBreakdownCard(context),
                      const SizedBox(height: 28),

                      // ── Recent Activity Timeline ──
                      Text(
                        'Recent Activity',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color),
                      ),
                      const SizedBox(height: 14),
                      _buildRecentActivityList(context),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildOverviewSection(BuildContext context) {
    final total = _stats?['totalAppointments'] ?? 0;
    final completed = _stats?['completedVisits'] ?? 0;
    final timeSaved = _stats?['timeSavedMinutes'] ?? 0;
    final upcoming = (_stats?['upcomingAppointments'] as List?)?.length ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard(context, 'Total Visits', '$total', Icons.calendar_month_rounded, AppTheme.primaryColor)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(context, 'Completed', '$completed', Icons.check_circle_rounded, AppTheme.successColor)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard(context, 'Upcoming', '$upcoming', Icons.schedule_rounded, AppTheme.warningColor)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(context, 'Time Saved', _formatMinutes(timeSaved), Icons.timer_rounded, AppTheme.accentColor)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5),
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

  Widget _buildCompletionRateCard(BuildContext context) {
    final theme = Theme.of(context);
    final total = _stats?['totalAppointments'] ?? 0;
    final completed = _stats?['completedVisits'] ?? 0;
    final rate = total > 0 ? (completed / total) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Visit Completion Rate',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70, letterSpacing: 0.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 130,
            height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: CircularProgressIndicator(
                    value: rate,
                    strokeWidth: 12,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(rate * 100).toInt()}%',
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    Text(
                      '$completed / $total',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.7)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              rate >= 0.8 ? '🌟 Excellent attendance!' : rate >= 0.5 ? '👍 Good track record' : '📊 Keep booking!',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSavedCard(BuildContext context) {
    final theme = Theme.of(context);
    final timeSaved = _stats?['timeSavedMinutes'] ?? 0;
    final completed = _stats?['completedVisits'] ?? 0;
    final avgPerVisit = completed > 0 ? (timeSaved / completed).round() : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.speed_rounded, color: AppTheme.accentColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Time Saved with IntelliQ',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'vs. traditional queueing',
                      style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTimeStat('Total Saved', _formatMinutes(timeSaved), AppTheme.accentColor),
              Container(width: 1, height: 40, color: theme.dividerColor),
              _buildTimeStat('Per Visit', '~${avgPerVisit}m', AppTheme.successColor),
              Container(width: 1, height: 40, color: theme.dividerColor),
              _buildTimeStat('Visits', '$completed', AppTheme.primaryColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textMutedColor)),
      ],
    );
  }

  Widget _buildBreakdownCard(BuildContext context) {
    final theme = Theme.of(context);
    final total = _stats?['totalAppointments'] ?? 0;
    final completed = _stats?['completedVisits'] ?? 0;
    final upcoming = (_stats?['upcomingAppointments'] as List?)?.length ?? 0;
    final cancelled = total - completed - upcoming;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          _buildBreakdownRow(context, 'Completed', completed, total, AppTheme.successColor),
          const SizedBox(height: 12),
          _buildBreakdownRow(context, 'Upcoming', upcoming, total, AppTheme.warningColor),
          const SizedBox(height: 12),
          _buildBreakdownRow(context, 'Cancelled / Other', cancelled > 0 ? cancelled : 0, total, AppTheme.errorColor),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(BuildContext context, String label, int count, int total, Color color) {
    final theme = Theme.of(context);
    final fraction = total > 0 ? count / total : 0.0;

    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
        ),
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 40,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivityList(BuildContext context) {
    final theme = Theme.of(context);
    if (_history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            Icon(Icons.history_rounded, size: 40, color: theme.hintColor),
            const SizedBox(height: 8),
            Text('No appointment history yet', style: TextStyle(fontSize: 13, color: theme.hintColor)),
          ],
        ),
      );
    }

    return Column(
      children: _history.take(5).map((apt) {
        final status = apt['status']?.toString() ?? 'Unknown';
        final providerName = apt['providerName']?.toString() ?? 'Service';
        final serviceName = apt['serviceName']?.toString() ?? '';
        final date = apt['date']?.toString().split('T').first ?? '';
        final statusColor = status == 'Completed'
            ? AppTheme.successColor
            : status == 'Upcoming'
                ? AppTheme.warningColor
                : status == 'Cancelled'
                    ? AppTheme.errorColor
                    : AppTheme.infoColor;
        final statusIcon = status == 'Completed'
            ? Icons.check_circle_rounded
            : status == 'Upcoming'
                ? Icons.schedule_rounded
                : status == 'Cancelled'
                    ? Icons.cancel_rounded
                    : Icons.info_rounded;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(providerName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color)),
                    if (serviceName.isNotEmpty)
                      Text(serviceName, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                  ),
                  const SizedBox(height: 4),
                  Text(date, style: TextStyle(fontSize: 10, color: theme.hintColor)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
    return '${minutes}m';
  }
}
