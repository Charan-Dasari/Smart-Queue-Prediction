import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String _error = '';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchDashboard(isRefresh: true));
  }

  Future<void> _fetchDashboard({bool isRefresh = false}) async {
    try {
      final data = await ApiService.getStaffDashboard();
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

  Future<void> _callNext() async {
    try {
      final token = await ApiService.callNext();
      if (mounted) {
        if (token == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No customers waiting in the queue.'), behavior: SnackBarBehavior.floating),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Called Token ${token['tokenNumber']}'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating),
          );
          _fetchDashboard();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to call next: $e'), backgroundColor: AppTheme.errorColor, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _markCompleted() async {
    try {
      final activeToken = _dashboardData?['currentlyServing'];
      if (activeToken == null) return;
      
      final queue = await ApiService.getProviderQueue();
      final tokenObj = queue.firstWhere(
        (t) => t['tokenNumber'] == activeToken, 
        orElse: () => null
      );

      if (tokenObj != null) {
        await ApiService.completeToken(tokenObj['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service marked as completed.'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating),
          );
          _fetchDashboard();
        }
      } else {
        throw Exception("Could not find active token ID");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _skipAbsent() async {
    final activeToken = _dashboardData?['currentlyServing'];
    if (activeToken == null) return;

    // Show skip reason dialog
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        const reasons = [
          'Absent — Customer not present',
          'Late arrival — Not available when called',
          'Incorrect documents — Missing required paperwork',
          'Wrong service counter — Redirected to correct counter',
          'Customer requested reschedule',
          'Unresponsive — No response after multiple calls',
        ];
        return AlertDialog(
          title: const Text('Skip Customer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Why do you want to skip this customer?',
                style: TextStyle(fontSize: 14, color: AppTheme.textMutedColor),
              ),
              const SizedBox(height: 16),
              ...reasons.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => Navigator.pop(ctx, r),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.getBorderColor(ctx)),
                    ),
                    child: Text(r, style: const TextStyle(fontSize: 13)),
                  ),
                ),
              )),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ],
        );
      },
    );

    if (reason == null || !mounted) return;

    try {
      final queue = await ApiService.getProviderQueue();
      final tokenObj = queue.firstWhere(
        (t) => t['tokenNumber'] == activeToken, 
        orElse: () => null
      );

      if (tokenObj != null) {
        await ApiService.skipToken(tokenObj['id'], reason);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Token skipped.'), backgroundColor: AppTheme.warningColor, behavior: SnackBarBehavior.floating),
          );
          _fetchDashboard();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _togglePauseResume() async {
    final assignedCounter = _dashboardData?['assignedCounter'];
    if (assignedCounter == null) return;

    final statusStr = assignedCounter['status']?.toString().toLowerCase() ?? 'offline';
    final newStatus = statusStr == 'active' ? 1 : 0;
    
    try {
      await ApiService.updateCounterStatus(assignedCounter['id'], newStatus);
      _fetchDashboard();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: AppTheme.errorColor, behavior: SnackBarBehavior.floating),
        );
      }
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
          appBar: AppBar(title: const Text('Staff Station')),
          body: Center(child: Text(_error)),
        ),
      );
    }

    final data = _dashboardData!;
    final user = Provider.of<AuthProvider>(context).user;

    String providerName = data['providerName'] ?? 'Provider';
    String counterDetails = data['assignedCounter'] != null 
        ? 'Counter #${data['assignedCounter']['number']} • ${data['assignedCounter']['serviceName'] ?? "General"}' 
        : 'No Counter Assigned';
    
    final categoryStr = (data['providerCategory']?.toString() ?? '0');
    Color themeColor = AppTheme.staffColor;
    LinearGradient headerGradient = AppTheme.staffGradient;

    if (categoryStr == '1') {
      themeColor = AppTheme.bankColor;
      headerGradient = AppTheme.successGradient;
    } else if (categoryStr == '2') {
      themeColor = AppTheme.govtColor;
      headerGradient = const LinearGradient(
        colors: [AppTheme.govtColor, Color(0xFFD97706)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    final String counterStatusStr = data['assignedCounter']?['status']?.toString().toLowerCase() ?? 'offline';
    Color statusColor = counterStatusStr == 'active' ? AppTheme.successColor : AppTheme.warningColor;
    String statusLabel = counterStatusStr == 'active' ? 'Active' : counterStatusStr == 'onbreak' ? 'On Break' : 'Offline';

    final servingToken = data['currentlyServing'];

    return UserThemeWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: Text('$providerName Counter Station'),
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
              onPressed: () => _fetchDashboard(),
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
              // ── Staff Profile Banner ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: headerGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['staffName'] ?? user?.name ?? 'Staff Operator',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            counterDetails,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: data['assignedCounter'] != null ? _togglePauseResume : null,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 4,
                              backgroundColor: counterStatusStr == 'active' ? Colors.white : Colors.amberAccent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Currently Serving Token Card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.token_rounded, size: 18, color: themeColor),
                        const SizedBox(width: 6),
                        Text(
                          'CURRENTLY SERVING TOKEN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: theme.textTheme.bodyMedium?.color,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      servingToken ?? 'NONE',
                      style: TextStyle(
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        color: servingToken != null ? themeColor : theme.disabledColor,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      servingToken != null
                          ? 'Estimated service duration: ~5 min'
                          : 'Counter idle • Tap "Call Next Customer" to begin',
                      style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color),
                    ),
                    const SizedBox(height: 28),

                    // ── Uniform 2x2 Action Suite ──
                    Column(
                      children: [
                        // Row 1: Call Next Customer & Complete
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: counterStatusStr == 'active' ? _callNext : null,
                                  icon: const Icon(Icons.campaign_rounded, size: 18),
                                  label: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('Call Next Customer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: themeColor,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: servingToken != null ? _markCompleted : null,
                                  icon: const Icon(Icons.check_circle_outline, size: 18),
                                  label: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('Complete', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.successColor,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Row 2: Pause/Resume Counter & Skip/Absent
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: data['assignedCounter'] != null ? _togglePauseResume : null,
                                  icon: Icon(
                                    counterStatusStr == 'active' ? Icons.pause_circle_outline : Icons.play_circle_outline,
                                    size: 18,
                                    color: statusColor,
                                  ),
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      counterStatusStr == 'active' ? 'Pause Counter' : 'Resume Counter',
                                      style: TextStyle(fontSize: 13, color: statusColor, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: statusColor.withOpacity(0.08),
                                    side: BorderSide(color: statusColor.withOpacity(0.5), width: 1.2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: servingToken != null ? _skipAbsent : null,
                                  icon: Icon(
                                    Icons.person_off_outlined,
                                    size: 18,
                                    color: servingToken != null ? AppTheme.errorColor : theme.disabledColor,
                                  ),
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Skip / Absent',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: servingToken != null ? AppTheme.errorColor : theme.disabledColor,
                                      ),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: (servingToken != null ? AppTheme.errorColor : theme.disabledColor).withOpacity(0.08),
                                    side: BorderSide(
                                      color: (servingToken != null ? AppTheme.errorColor : theme.dividerColor).withOpacity(0.5),
                                      width: 1.2,
                                    ),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Queue Status Summary Metrics ──
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryTile(
                      context,
                      'Waiting in Queue',
                      '${data['waitingCount']} tokens',
                      'Next: ${data['nextWaitingToken'] ?? "None"}',
                      AppTheme.infoColor,
                      Icons.hourglass_top_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryTile(
                      context,
                      'Served Today',
                      '${data['servedToday']} visits',
                      'Avg: ${data['avgServiceMinutes']}m / visit',
                      AppTheme.successColor,
                      Icons.task_alt_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Recent Activity Section ──
              Row(
                children: [
                  Text(
                    'Counter Activity Log',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push('/staff/queue'),
                    child: Text(
                      'View Queue List',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: themeColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (data['recentActivity'] != null && (data['recentActivity'] as List).isNotEmpty)
                ...(data['recentActivity'] as List<dynamic>).map((log) => _buildActivityItem(context, log['time'], log['action']))
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Center(
                    child: Text(
                      'No recent actions logged today',
                      style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                    ),
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTile(BuildContext context, String label, String value, String subtitle, Color color, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, String time, String action) {
    final theme = Theme.of(context);
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.staffColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              time,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.staffColor),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              action,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color),
            ),
          ),
        ],
      ),
    );
  }
}

