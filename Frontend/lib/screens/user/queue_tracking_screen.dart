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
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _loadData();
    // Auto-refresh every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadData(isRefresh: true));
  }
  
  Future<void> _loadData({bool isRefresh = false}) async {
    try {
      final data = await ApiService.getQueueTracking(widget.tokenId);
      if (mounted) {
        setState(() {
          _token = QueueToken.fromJson(data['queueToken']);
          if (data['activeCounter'] != null) {
            _activeCounter = ServiceCounter.fromJson(data['activeCounter']);
          } else {
            _activeCounter = null;
          }
          _estimatedWaitMinutes = data['estimatedWaitMinutes'] ?? _token?.estimatedWaitMinutes ?? 0;
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

  // Current step logic based on status
  int get _currentStep {
    if (_token == null) return 0;
    switch (_token!.status) {
      case AppointmentStatus.upcoming: return 0; // Booked
      case AppointmentStatus.inQueue: return 2; // Waiting (CheckedIn skipped for simplicity)
      case AppointmentStatus.serving: return 3; // Serving
      case AppointmentStatus.completed: return 4; // Completed
      case AppointmentStatus.cancelled: return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Queue Tracking')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_error.isNotEmpty || _token == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Queue Tracking')),
        body: Center(child: Text(_error.isNotEmpty ? _error : 'Token not found')),
      );
    }

    // Use default values if no active counter is serving
    final String nowServing = _activeCounter?.activeTokenNumber ?? '...';
    final int aheadCount = _token!.queuePosition > 0 ? _token!.queuePosition - 1 : 0;
    final String waitTime = '~$_estimatedWaitMinutes min';
    final String counterNumber = _activeCounter != null ? '#${_activeCounter!.number}' : 'TBD';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Live Queue Tracking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(_token!.providerName, style: const TextStyle(fontSize: 11, color: AppTheme.textMutedColor, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Opacity(opacity: _pulseAnimation.value, child: child);
                  },
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: AppTheme.successColor, shape: BoxShape.circle),
                  ),
                ),
                const SizedBox(width: 6),
                const Text('LIVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.successColor)),
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
            // ── Current Serving Banner ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.hospitalColor, AppTheme.hospitalColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.hospitalColor.withOpacity(0.3),
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
                      Icon(Icons.local_hospital, color: Colors.white.withOpacity(0.7), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'NOW SERVING',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(scale: _pulseAnimation.value, child: child);
                    },
                    child: Text(
                      nowServing,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'at Counter $counterNumber',
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Your Position Stats ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: [
                  Text(
                    'Your Token: ${_token!.tokenNumber}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('$aheadCount', 'Users Ahead', AppTheme.infoColor),
                      Container(width: 1, height: 40, color: AppTheme.borderColor),
                      _buildStatItem(waitTime, 'Est. Wait', AppTheme.warningColor),
                      Container(width: 1, height: 40, color: AppTheme.borderColor),
                      _buildStatItem(counterNumber, 'Counter', AppTheme.accentColor),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Queue Timeline ──
            const Text(
              'Queue Timeline',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            _buildTimelineStep(0, 'Booked', 'Token ${_token!.tokenNumber} booked', '--', Icons.confirmation_number_outlined),
            _buildTimelineStep(1, 'Checked In', 'Checked in at counter', '--', Icons.login),
            _buildTimelineStep(2, 'Waiting', 'In queue — $aheadCount ahead', '--', Icons.hourglass_top),
            _buildTimelineStep(3, 'Serving', 'Consultation at Counter $counterNumber', '--', Icons.support_agent),
            _buildTimelineStep(4, 'Completed', 'Service completed', '--', Icons.check_circle_outline, isLast: true),
            const SizedBox(height: 24),

            // ── Alert Card ──
            if (_token!.status == AppointmentStatus.inQueue)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.warningColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active, color: AppTheme.warningColor, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Notification Alert',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDarkColor),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'You will be notified when your turn is next',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMutedColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep(int stepIndex, String title, String subtitle, String time, IconData icon, {bool isLast = false}) {
    final isCompleted = stepIndex < _currentStep;
    final isCurrent = stepIndex == _currentStep;
    final isFuture = stepIndex > _currentStep;

    Color stepColor;
    if (isCompleted) {
      stepColor = AppTheme.successColor;
    } else if (isCurrent) {
      stepColor = AppTheme.primaryColor;
    } else {
      stepColor = AppTheme.textLightColor;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline line + dot
        SizedBox(
          width: 40,
          child: Column(
            children: [
              // Animated dot for current step
              isCurrent
                  ? AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: stepColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 20,
                              height: 20,
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
                        isCompleted ? Icons.check : icon,
                        size: 14,
                        color: isCompleted ? Colors.white : stepColor,
                      ),
                    ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  color: isCompleted ? AppTheme.successColor.withOpacity(0.3) : AppTheme.borderColor,
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Content
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isCurrent ? stepColor.withOpacity(0.04) : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrent ? stepColor.withOpacity(0.2) : AppTheme.borderColor,
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
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                          color: isFuture ? AppTheme.textLightColor : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isFuture ? AppTheme.textLightColor : AppTheme.textMutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isCurrent ? stepColor : AppTheme.textLightColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMutedColor)),
      ],
    );
  }
}
