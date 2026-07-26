import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../models/models.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/smart_search_bar.dart';
import '../../widgets/floating_capsule_nav_bar.dart';

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
  Timer? _liveQueueTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Auto-refresh live queue every 10 seconds
    _liveQueueTimer = Timer.periodic(const Duration(seconds: 10), (_) => _refreshLiveQueue());
  }

  @override
  void dispose() {
    _liveQueueTimer?.cancel();
    super.dispose();
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
              .map((n) => AppNotification.fromJson(n as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshLiveQueue() async {
    try {
      final tokenData = await ApiService.getMyToken();
      if (mounted) {
        setState(() {
          if (tokenData != null) {
            _activeToken = QueueToken.fromJson(tokenData);
          } else {
            _activeToken = null;
          }
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 850;

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        isNarrow ? 16 : 20,
                        isNarrow ? 12 : 16,
                        isNarrow ? 16 : 20,
                        120,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Top Header Deck ──
                          _buildHeaderDeck(context, user, isNarrow),
                          SizedBox(height: isNarrow ? 14 : 18),

                          // ── BENTO BOX 1: Hero AI Predictor & Search ──
                          _buildHeroSearchBento(context, isNarrow),
                          SizedBox(height: isNarrow ? 12 : 16),

                          // ── BENTO ROW: Live Queue & Time Impact Cards ──
                          if (isNarrow)
                            // Stack vertically on narrow screens
                            Column(
                              children: [
                                _buildActiveQueueBento(context, isNarrow),
                                const SizedBox(height: 12),
                                _buildMetricsBento(context, isNarrow),
                              ],
                            )
                          else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: _buildActiveQueueBento(context, isNarrow),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  flex: 1,
                                  child: _buildMetricsBento(context, isNarrow),
                                ),
                              ],
                            ),
                          SizedBox(height: isNarrow ? 14 : 20),

                          // ── LIVE QUEUE STATUS CARD ──
                          if (_activeToken != null)
                            _buildLiveQueueStatusCard(context, isNarrow),
                          if (_activeToken != null)
                            SizedBox(height: isNarrow ? 14 : 20),

                          // ── BENTO BOX 4: Category Avatars with Glow Rings ──
                          _buildCategoryAvatarsSection(context, isNarrow),
                          SizedBox(height: isNarrow ? 18 : 24),

                          // ── Quick Services Shortcuts Grid ──
                          _buildQuickShortcutsGrid(context, isNarrow),
                          SizedBox(height: isNarrow ? 18 : 24),

                          // ── Notifications Activity Stream ──
                          _buildNotificationsSection(context, isNarrow),
                        ],
                      ),
                    ),
                  ),

                  // ── FLOATING CAPSULE NAVIGATION BAR ──
                  Positioned(
                    left: isNarrow ? 16 : 24,
                    right: isNarrow ? 16 : 24,
                    bottom: isNarrow ? 10 : 16,
                    child: const FloatingCapsuleNavBar(currentIndex: 0),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Header Deck Widget ──
  Widget _buildHeaderDeck(BuildContext context, AppUser? user, bool isNarrow) {
    final avatarSize = isNarrow ? 42.0 : 48.0;
    return Row(
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.primaryGradient,
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).cardColor,
            ),
            child: Center(
              child: Text(
                user?.name.substring(0, 1).toUpperCase() ?? 'U',
                style: TextStyle(
                  fontSize: isNarrow ? 15 : 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: isNarrow ? 10 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: TextStyle(
                  fontSize: isNarrow ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMutedColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user?.name ?? 'User',
                style: TextStyle(
                  fontSize: isNarrow ? 17 : 20,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  letterSpacing: -0.4,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => context.push('/notifications'),
          child: Container(
            width: isNarrow ? 38 : 44,
            height: isNarrow ? 38 : 44,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(isNarrow ? 12 : 16),
              border: Border.all(color: AppTheme.getBorderColor(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(Icons.notifications_outlined, color: Theme.of(context).textTheme.bodyLarge?.color, size: isNarrow ? 20 : 22),
                ),
                if (_notifications.any((n) => !n.isRead))
                  Positioned(
                    top: isNarrow ? 8 : 10,
                    right: isNarrow ? 8 : 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Bento Box 1: Hero Search & AI Predictor ──
  Widget _buildHeroSearchBento(BuildContext context, bool isNarrow) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isNarrow ? 16 : 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(isNarrow ? 20 : 24),
        border: Border.all(color: AppTheme.getBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: isNarrow ? 8 : 10, vertical: isNarrow ? 4 : 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: isNarrow ? 12 : 14),
                    SizedBox(width: isNarrow ? 4 : 6),
                    Text(
                      'AI Queue Predictor',
                      style: TextStyle(
                        fontSize: isNarrow ? 10 : 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Live Insights',
                style: TextStyle(fontSize: isNarrow ? 10 : 11, fontWeight: FontWeight.w600, color: AppTheme.textMutedColor),
              ),
            ],
          ),
          SizedBox(height: isNarrow ? 10 : 14),
          Text(
            'Smart Check-in & Search',
            style: TextStyle(
              fontSize: isNarrow ? 18 : 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isNarrow
                ? 'Find queues with real-time AI wait estimates.'
                : 'Find hospital, bank, or college queues with real-time AI wait estimates.',
            style: TextStyle(fontSize: isNarrow ? 12 : 13, color: AppTheme.textMutedColor),
          ),
          SizedBox(height: isNarrow ? 12 : 16),
          SmartSearchBar(
            onPlaceSelected: (place) {
              final placeId = place['id'];
              if (placeId != null) context.push('/booking/$placeId');
            },
            onQuerySubmitted: (query) {
              context.push('/services');
            },
          ),
        ],
      ),
    );
  }

  // ── Bento Box 2: Active Queue Circular Status ──
  Widget _buildActiveQueueBento(BuildContext context, bool isNarrow) {
    final cardHeight = isNarrow ? 160.0 : 190.0;

    if (_activeToken == null) {
      return Container(
        width: double.infinity,
        height: cardHeight,
        padding: EdgeInsets.all(isNarrow ? 14 : 18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(isNarrow ? 18 : 22),
          border: Border.all(color: AppTheme.getBorderColor(context)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isNarrow ? 38 : 44,
              height: isNarrow ? 38 : 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.confirmation_number_outlined, color: AppTheme.primaryColor, size: isNarrow ? 20 : 22),
            ),
            SizedBox(height: isNarrow ? 8 : 10),
            Text(
              'No Active Queue',
              style: TextStyle(fontSize: isNarrow ? 13 : 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Book an appointment to track live queue',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: isNarrow ? 10 : 11, color: AppTheme.textMutedColor),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => context.push('/tracking/${_activeToken!.id}'),
      child: Container(
        width: double.infinity,
        height: cardHeight,
        padding: EdgeInsets.all(isNarrow ? 14 : 18),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(isNarrow ? 18 : 22),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.successColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'ACTIVE QUEUE',
                  style: TextStyle(
                    fontSize: isNarrow ? 9 : 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Center(
              child: Column(
                children: [
                  Text(
                    '#${_activeToken!.queuePosition}',
                    style: TextStyle(
                      fontSize: isNarrow ? 32 : 40,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'IN LINE',
                    style: TextStyle(
                      fontSize: isNarrow ? 9 : 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    _activeToken!.tokenNumber,
                    style: TextStyle(fontSize: isNarrow ? 12 : 13, fontWeight: FontWeight.w700, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '~${_activeToken!.estimatedWaitMinutes}m wait',
                  style: TextStyle(fontSize: isNarrow ? 11 : 12, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Bento Box 3: Metrics & Time Saved Impact ──
  Widget _buildMetricsBento(BuildContext context, bool isNarrow) {
    final timeSavedStr = _formatTimeSaved(_stats?.timeSavedMinutes ?? 0);
    final cardHeight = isNarrow ? 160.0 : 190.0;

    return Container(
      width: double.infinity,
      height: cardHeight,
      padding: EdgeInsets.all(isNarrow ? 14 : 18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(isNarrow ? 18 : 22),
        border: Border.all(color: AppTheme.getBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: isNarrow ? 28 : 32,
                height: isNarrow ? 28 : 32,
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(isNarrow ? 8 : 10),
                ),
                child: Icon(Icons.access_time_filled_rounded, color: AppTheme.accentColor, size: isNarrow ? 15 : 18),
              ),
              SizedBox(width: isNarrow ? 6 : 8),
              Text(
                'Impact',
                style: TextStyle(fontSize: isNarrow ? 11 : 12, fontWeight: FontWeight.w700, color: AppTheme.textMutedColor),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timeSavedStr,
                style: TextStyle(
                  fontSize: isNarrow ? 22 : 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.accentColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Time Saved',
                style: TextStyle(fontSize: isNarrow ? 10 : 11, fontWeight: FontWeight.w600, color: AppTheme.textMutedColor),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: isNarrow ? 8 : 10, vertical: isNarrow ? 5 : 6),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_up_rounded, color: AppTheme.successColor, size: isNarrow ? 12 : 14),
                SizedBox(width: isNarrow ? 3 : 4),
                Flexible(
                  child: Text(
                    '${_stats?.completedVisits ?? 0} visits done',
                    style: TextStyle(fontSize: isNarrow ? 9 : 10, fontWeight: FontWeight.w700, color: AppTheme.successColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── LIVE QUEUE STATUS CARD ──
  Widget _buildLiveQueueStatusCard(BuildContext context, bool isNarrow) {
    if (_activeToken == null) return const SizedBox.shrink();

    final token = _activeToken!;
    final priorityLabel = token.priority == 'urgent'
        ? 'URGENT'
        : token.priority == 'high'
            ? 'HIGH'
            : 'NORMAL';
    final priorityColor = token.priority == 'urgent'
        ? AppTheme.errorColor
        : token.priority == 'high'
            ? AppTheme.warningColor
            : AppTheme.successColor;
    final priorityIcon = token.priority == 'urgent'
        ? Icons.priority_high_rounded
        : token.priority == 'high'
            ? Icons.arrow_upward_rounded
            : Icons.remove_rounded;

    return GestureDetector(
      onTap: () => context.push('/tracking/${token.id}'),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isNarrow ? 14 : 18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(isNarrow ? 18 : 22),
          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: isNarrow ? 8 : 10, vertical: isNarrow ? 3 : 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
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
                      Text(
                        'LIVE QUEUE',
                        style: TextStyle(
                          fontSize: isNarrow ? 9 : 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Priority badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: isNarrow ? 8 : 10, vertical: isNarrow ? 3 : 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(priorityIcon, size: isNarrow ? 10 : 12, color: priorityColor),
                      const SizedBox(width: 4),
                      Text(
                        priorityLabel,
                        style: TextStyle(
                          fontSize: isNarrow ? 9 : 10,
                          fontWeight: FontWeight.w800,
                          color: priorityColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isNarrow ? 12 : 16),

            // Main content row: Token info + Position
            Row(
              children: [
                // Token number & Now Serving
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Token',
                        style: TextStyle(
                          fontSize: isNarrow ? 10 : 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMutedColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        token.tokenNumber,
                        style: TextStyle(
                          fontSize: isNarrow ? 20 : 24,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryColor,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: isNarrow ? 6 : 8),
                      Row(
                        children: [
                          Icon(Icons.play_circle_filled_rounded, size: isNarrow ? 12 : 14, color: AppTheme.successColor),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Now Serving: T-${token.currentServing.toString().padLeft(3, '0')}',
                              style: TextStyle(
                                fontSize: isNarrow ? 11 : 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.successColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Queue position circle
                Container(
                  width: isNarrow ? 68 : 80,
                  height: isNarrow ? 68 : 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '#${token.queuePosition}',
                        style: TextStyle(
                          fontSize: isNarrow ? 20 : 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'in line',
                        style: TextStyle(
                          fontSize: isNarrow ? 8 : 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isNarrow ? 12 : 16),

            // Bottom stats row
            Container(
              padding: EdgeInsets.symmetric(horizontal: isNarrow ? 10 : 14, vertical: isNarrow ? 8 : 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded, size: isNarrow ? 14 : 16, color: AppTheme.warningColor),
                  SizedBox(width: isNarrow ? 4 : 6),
                  Text(
                    '~${token.estimatedWaitMinutes}m wait',
                    style: TextStyle(
                      fontSize: isNarrow ? 11 : 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.warningColor,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      token.providerName,
                      style: TextStyle(
                        fontSize: isNarrow ? 10 : 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMutedColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: isNarrow ? 4 : 6),
                  Icon(Icons.arrow_forward_ios_rounded, size: isNarrow ? 10 : 12, color: AppTheme.textMutedColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bento Section 4: Circular Category Avatars with Glow Rings ──
  Widget _buildCategoryAvatarsSection(BuildContext context, bool isNarrow) {
    final categories = [
      {'label': 'Hospital', 'icon': Icons.local_hospital_rounded, 'color': AppTheme.hospitalColor, 'route': '/hospital'},
      {'label': 'Bank', 'icon': Icons.account_balance_rounded, 'color': AppTheme.bankColor, 'route': '/bank'},
      {'label': 'Restaurant', 'icon': Icons.restaurant_rounded, 'color': AppTheme.restaurantColor, 'route': '/restaurant'},
      {'label': 'College', 'icon': Icons.school_rounded, 'color': AppTheme.collegeColor, 'route': '/college'},
    ];

    final avatarSize = isNarrow ? 48.0 : 58.0;
    final iconSize = isNarrow ? 20.0 : 24.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Explore Venues',
              style: TextStyle(
                fontSize: isNarrow ? 16 : 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push('/services'),
              child: Text(
                'View All',
                style: TextStyle(
                  fontSize: isNarrow ? 12 : 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isNarrow ? 10 : 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: categories.map((cat) {
            final color = cat['color'] as Color;
            return GestureDetector(
              onTap: () => context.push(cat['route'] as String),
              child: Column(
                children: [
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.22),
                          blurRadius: isNarrow ? 6 : 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).cardColor,
                      ),
                      child: Icon(cat['icon'] as IconData, color: color, size: iconSize),
                    ),
                  ),
                  SizedBox(height: isNarrow ? 6 : 8),
                  Text(
                    cat['label'] as String,
                    style: TextStyle(
                      fontSize: isNarrow ? 11 : 12,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Quick Shortcuts Grid ──
  Widget _buildQuickShortcutsGrid(BuildContext context, bool isNarrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Services',
          style: TextStyle(
            fontSize: isNarrow ? 16 : 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: isNarrow ? 10 : 14),
        Row(
          children: [
            Expanded(child: _buildShortcutTile(context, Icons.calendar_month_rounded, 'Book Slot', 'Schedule Visit', AppTheme.primaryColor, () => context.push('/services'), isNarrow)),
            SizedBox(width: isNarrow ? 8 : 12),
            Expanded(child: _buildShortcutTile(context, Icons.qr_code_2_rounded, 'Digital Token', 'QR Pass', AppTheme.accentColor, () => context.push('/my-tokens'), isNarrow)),
          ],
        ),
      ],
    );
  }

  Widget _buildShortcutTile(BuildContext context, IconData icon, String title, String subtitle, Color color, VoidCallback onTap, bool isNarrow) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isNarrow ? 12 : 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(isNarrow ? 14 : 18),
          border: Border.all(color: AppTheme.getBorderColor(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: isNarrow ? 36 : 42,
              height: isNarrow ? 36 : 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(isNarrow ? 10 : 12),
              ),
              child: Icon(icon, color: color, size: isNarrow ? 18 : 22),
            ),
            SizedBox(width: isNarrow ? 8 : 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: isNarrow ? 12 : 13, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: isNarrow ? 10 : 11, color: AppTheme.textMutedColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Notifications Section ──
  Widget _buildNotificationsSection(BuildContext context, bool isNarrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Activity Feed',
              style: TextStyle(
                fontSize: isNarrow ? 16 : 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push('/notifications'),
              child: Text(
                'See All',
                style: TextStyle(
                  fontSize: isNarrow ? 12 : 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isNarrow ? 10 : 14),
        ..._notifications.take(3).map((notif) => Container(
              margin: EdgeInsets.only(bottom: isNarrow ? 8 : 10),
              padding: EdgeInsets.all(isNarrow ? 12 : 14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(isNarrow ? 12 : 16),
                border: Border.all(color: AppTheme.getBorderColor(context)),
              ),
              child: Row(
                children: [
                  Container(
                    width: isNarrow ? 32 : 38,
                    height: isNarrow ? 32 : 38,
                    decoration: BoxDecoration(
                      color: _getNotifColor(notif.type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(isNarrow ? 10 : 12),
                    ),
                    child: Icon(_getNotifIcon(notif.type), color: _getNotifColor(notif.type), size: isNarrow ? 15 : 18),
                  ),
                  SizedBox(width: isNarrow ? 10 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notif.title,
                          style: TextStyle(fontSize: isNarrow ? 13 : 14, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          notif.body,
                          style: TextStyle(fontSize: isNarrow ? 11 : 12, color: AppTheme.textMutedColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
        if (_notifications.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text('No recent activity.', style: TextStyle(color: AppTheme.textMutedColor)),
            ),
          ),
      ],
    );
  }



  IconData _getNotifIcon(NotificationType type) {
    switch (type) {
      case NotificationType.booking: return Icons.check_circle_outline;
      case NotificationType.queue: return Icons.access_time_rounded;
      case NotificationType.ai: return Icons.auto_awesome;
      default: return Icons.notifications_none_rounded;
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
}
