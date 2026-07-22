import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
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
      // Note: Backend /complete and /skip needs Guid tokenId, but staff dashboard returns only the string TokenNumber
      // We will need to find the token id. Alternatively, in the queue_management we get the list.
      // Wait, currentlyServing is a string token number. 
      // The backend expects tokenId (Guid) for Complete. 
      // Since StaffDashboardDto returns only TokenNumber, we may need to fetch the Queue details or change the endpoint.
      // For now, if we can't complete because we don't have ID, let's fetch providerQueue to find it.
      
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
    try {
      final activeToken = _dashboardData?['currentlyServing'];
      if (activeToken == null) return;
      
      final queue = await ApiService.getProviderQueue();
      final tokenObj = queue.firstWhere(
        (t) => t['tokenNumber'] == activeToken, 
        orElse: () => null
      );

      if (tokenObj != null) {
        await ApiService.skipToken(tokenObj['id']);
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
    final newStatus = statusStr == 'active' ? 1 : 0; // Toggle between OnBreak (1) and Active (0)
    
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
    if (_isLoading && _dashboardData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    if (_error.isNotEmpty && _dashboardData == null) {
      return Scaffold(body: Center(child: Text(_error)));
    }

    final data = _dashboardData!;
    final user = Provider.of<AuthProvider>(context).user;
    final providerId = user?.providerId;

    String providerName = data['providerName'] ?? 'Provider';
    String counterDetails = data['assignedCounter'] != null 
        ? 'Counter #${data['assignedCounter']['number']} (${data['assignedCounter']['serviceName']})' 
        : 'No Counter Assigned';
    
    final categoryStr = (data['providerCategory']?.toString() ?? '0');
    Color themeColor = AppTheme.staffColor;
    LinearGradient headerGradient = AppTheme.staffGradient;

    if (categoryStr == '1') { // Bank
      themeColor = AppTheme.bankColor;
      headerGradient = AppTheme.successGradient;
    } else if (categoryStr == '2') { // Govt
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

    return Scaffold(
      appBar: AppBar(
        title: Text('$providerName Staff Dashboard', style: const TextStyle(fontSize: 16)),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Icon(Icons.support_agent, color: themeColor),
        ),
        actions: [
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
            // ── Staff Profile Header ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: headerGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['staffName'] ?? 'Staff',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          counterDetails,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  InkWell(
                    onTap: data['assignedCounter'] != null ? _togglePauseResume : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: counterStatusStr == 'active'
                                ? Colors.white
                                : Colors.amberAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
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
            const SizedBox(height: 20),

            // ── Large Currently Serving Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'CURRENTLY SERVING',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMutedColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    servingToken ?? 'NONE',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: servingToken != null ? themeColor : AppTheme.textLightColor,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    servingToken != null
                        ? 'Estimated service completion: ~5 min'
                        : 'Call the next token to start serving',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMutedColor),
                  ),
                  const SizedBox(height: 24),
                  // Primary Controls
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: servingToken != null ? _skipAbsent : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                            side: BorderSide(
                              color: servingToken != null
                                  ? AppTheme.errorColor
                                  : AppTheme.borderColor,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Skip / Absent'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: servingToken != null ? _markCompleted : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Complete'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Call Next / Pause
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: data['assignedCounter'] != null ? _togglePauseResume : null,
                          icon: Icon(
                            counterStatusStr == 'active'
                                ? Icons.pause_circle_outline
                                : Icons.play_circle_outline,
                            size: 18,
                            color: statusColor,
                          ),
                          label: Text(
                            counterStatusStr == 'active' ? 'Pause Queue' : 'Resume Queue',
                            style: TextStyle(color: statusColor),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: statusColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: counterStatusStr == 'active' ? _callNext : null,
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: const Text('Call Next'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Queue Status Summary ──
            Row(
              children: [
                Expanded(
                  child: _buildQueueSummaryTile(
                    'In Queue',
                    '${data['waitingCount']} tokens',
                    'Next: ${data['nextWaitingToken'] ?? 'None'}',
                    AppTheme.infoColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQueueSummaryTile(
                    'Served Today',
                    '${data['servedToday']} visits',
                    'Avg: ${data['avgServiceMinutes']}m / visit',
                    AppTheme.successColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Recent Activity Log ──
            Row(
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDarkColor,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.push('/staff/queue'),
                  child: Text(
                    'View Full Queue',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: themeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...(data['recentActivity'] as List<dynamic>).map((log) => _buildActivityItem(log['time'], log['action'])),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueSummaryTile(String label, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMutedColor)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMutedColor)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String time, String action) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.staffColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              time,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.staffColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              action,
              style: const TextStyle(fontSize: 13, color: AppTheme.textDarkColor),
            ),
          ),
        ],
      ),
    );
  }
}
