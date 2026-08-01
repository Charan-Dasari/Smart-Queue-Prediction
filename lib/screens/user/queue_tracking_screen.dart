import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';

class QueueTrackingScreen extends StatefulWidget {
  final String tokenId;
  const QueueTrackingScreen({super.key, required this.tokenId});

  @override
  State<QueueTrackingScreen> createState() => _QueueTrackingScreenState();
}

class _QueueTrackingScreenState extends State<QueueTrackingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _opacityAnimation;
  Timer? _refreshTimer;

  QueueToken? _token;
  ServiceCounter? _activeCounter;
  int _estimatedWaitMinutes = 0;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadData(isRefresh: true));
  }
  
  Future<void> _loadData({bool isRefresh = false}) async {
    try {
      final data = await ApiService.getQueueTracking(widget.tokenId);
      if (mounted) {
        setState(() {
          _token = QueueToken.fromJson(data);
          _activeCounter = null; 
          _estimatedWaitMinutes = _token?.estimatedWaitMinutes ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !isRefresh) {
        setState(() {
          _error = 'Failed to load queue tracking';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  int get _currentStep {
    if (_token == null) return 0;
    switch (_token!.status) {
      case AppointmentStatus.upcoming: return 0;
      case AppointmentStatus.inQueue: return 2;
      case AppointmentStatus.serving: return 3;
      case AppointmentStatus.completed: return 5; // 5 ensures step 4 is completed (green tick)
      case AppointmentStatus.cancelled: return 5;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const UserThemeWrapper(
        child: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    
    if (_error.isNotEmpty || _token == null) {
      return UserThemeWrapper(
        child: Scaffold(
          appBar: AppBar(title: const Text('Live Queue Tracking')),
          body: Center(child: Text(_error.isNotEmpty ? _error : 'Token not found')),
        ),
      );
    }

    final String nowServing = _token!.tokenNumber;
    final int aheadCount = _token!.queuePosition > 0 ? _token!.queuePosition - 1 : 0;
    final String waitTime = '~$_estimatedWaitMinutes m';
    final String counterNumber = _token!.counterNumber != null ? '#${_token!.counterNumber}' : 'Pending';

    return UserThemeWrapper(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => context.pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Live Queue Tracker', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              Text(_token!.providerName, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.w500)),
            ],
          ),
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
                  AnimatedBuilder(
                    animation: _opacityAnimation,
                    builder: (context, child) {
                      return Opacity(opacity: _opacityAnimation.value, child: child);
                    },
                    child: const CircleAvatar(radius: 3.5, backgroundColor: AppTheme.successColor),
                  ),
                  const SizedBox(width: 6),
                  const Text('LIVE STREAM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.successColor)),
                ],
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Current Serving Hero Banner ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.stars_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _token!.status == AppointmentStatus.completed ? 'SERVICE COMPLETED' : 'YOUR TOKEN NUMBER',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withOpacity(0.85),
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(scale: _pulseAnimation.value, child: child);
                      },
                      child: Text(
                        nowServing,
                        style: const TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Service Counter $counterNumber',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.9)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Position & Wait Stats Card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Your Token: ${_token!.tokenNumber}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: theme.textTheme.bodyLarge?.color),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(context, '$aheadCount', 'Users Ahead', AppTheme.infoColor),
                        Container(width: 1, height: 36, color: theme.dividerColor),
                        _buildStatItem(context, waitTime, 'Est. Wait', AppTheme.warningColor),
                        Container(width: 1, height: 36, color: theme.dividerColor),
                        _buildStatItem(context, counterNumber, 'Counter', AppTheme.accentColor),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Queue Timeline ──
              Text(
                'Live Queue Progress',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: theme.textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 16),
              _buildTimelineStep(context, 0, 'Booked', 'Token ${_token!.tokenNumber} generated', '--', Icons.confirmation_number_outlined),
              _buildTimelineStep(context, 1, 'Checked In', 'Validated at service counter', '--', Icons.login_rounded),
              _buildTimelineStep(context, 2, 'Waiting', 'In queue — $aheadCount ahead of you', '--', Icons.hourglass_top_rounded),
              _buildTimelineStep(context, 3, 'Serving', 'Consultation at Counter $counterNumber', '--', Icons.support_agent_rounded),
              _buildTimelineStep(context, 4, 'Completed', 'Service completed', '--', Icons.check_circle_outline, isLast: true),
              const SizedBox(height: 24),

              // ── Alert Card ──
              if (_token!.status == AppointmentStatus.inQueue)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.warningColor.withOpacity(0.12) : AppTheme.warningColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppTheme.warningColor.withOpacity(0.15), shape: BoxShape.circle),
                        child: const Icon(Icons.notifications_active_rounded, color: AppTheme.warningColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Live Queue Alert Active',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'You will receive an instant alert when your token is called next.',
                              style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineStep(BuildContext context, int stepIndex, String title, String subtitle, String time, IconData icon, {bool isLast = false}) {
    final theme = Theme.of(context);
    final isCompleted = stepIndex < _currentStep;
    final isCurrent = stepIndex == _currentStep;
    final isFuture = stepIndex > _currentStep;

    Color stepColor;
    if (isCompleted) {
      stepColor = AppTheme.successColor;
    } else if (isCurrent) {
      stepColor = AppTheme.primaryColor;
    } else {
      stepColor = theme.disabledColor;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          child: Column(
            children: [
              isCurrent
                  ? AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: stepColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: stepColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, size: 12, color: Colors.white),
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCompleted ? stepColor : stepColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check_rounded : icon,
                        size: 14,
                        color: isCompleted ? Colors.white : stepColor,
                      ),
                    ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 42,
                  color: isCompleted ? AppTheme.successColor.withOpacity(0.4) : theme.dividerColor,
                ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCurrent ? stepColor.withOpacity(0.06) : theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isCurrent ? stepColor.withOpacity(0.3) : theme.dividerColor,
                width: isCurrent ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                          color: isFuture ? theme.disabledColor : theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isFuture ? theme.disabledColor : theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isCurrent ? stepColor : theme.disabledColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label, Color color) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.textTheme.bodyMedium?.color)),
      ],
    );
  }
}

