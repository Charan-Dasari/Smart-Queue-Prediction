import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    try {
      final data = await ApiService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = data
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

  Future<void> _markAllRead() async {
    try {
      await ApiService.markAllNotificationsRead();
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to mark notifications as read'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await ApiService.markNotificationRead(id);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == id);
        if (index != -1) {
          final old = _notifications[index];
          _notifications[index] = AppNotification(
            id: old.id,
            title: old.title,
            body: old.body,
            type: old.type,
            timestamp: old.timestamp,
            isRead: true,
          );
        }
      });
    } catch (_) {}
  }

  List<AppNotification> _filteredNotifications(int tabIndex) {
    if (tabIndex == 0) return _notifications;
    final types = [NotificationType.system, NotificationType.booking, NotificationType.queue, NotificationType.ai];
    return _notifications.where((n) => n.type == types[tabIndex]).toList();
  }

  IconData _getNotifIcon(NotificationType type) {
    switch (type) {
      case NotificationType.booking:
        return Icons.check_circle_outline;
      case NotificationType.queue:
        return Icons.people_outline;
      case NotificationType.reminder:
        return Icons.calendar_today_outlined;
      case NotificationType.ai:
        return Icons.auto_awesome;
      case NotificationType.system:
        return Icons.info_outline;
    }
  }

  Color _getNotifColor(NotificationType type) {
    switch (type) {
      case NotificationType.booking:
        return AppTheme.successColor;
      case NotificationType.queue:
        return AppTheme.infoColor;
      case NotificationType.reminder:
        return AppTheme.warningColor;
      case NotificationType.ai:
        return AppTheme.aiAccent;
      case NotificationType.system:
        return AppTheme.accentColor;
    }
  }

  String _formatRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((n) => !n.isRead);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notifications'),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark All Read', style: TextStyle(fontSize: 13, color: AppTheme.accentColor)),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textMutedColor,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          indicatorColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.accentColor : AppTheme.primaryColor,
          indicatorWeight: 2.5,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Appointments'),
            Tab(text: 'Queue'),
            Tab(text: 'AI'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: TabBarView(
                controller: _tabController,
                children: List.generate(4, (tabIndex) {
                  final items = _filteredNotifications(tabIndex);
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 48, color: AppTheme.textLightColor),
                          const SizedBox(height: 12),
                          const Text('No notifications', style: TextStyle(fontSize: 15, color: AppTheme.textMutedColor)),
                          const SizedBox(height: 8),
                          const Text(
                            'You\'re all caught up!',
                            style: TextStyle(fontSize: 13, color: AppTheme.textLightColor),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final n = items[index];
                      final icon = _getNotifIcon(n.type);
                      final color = _getNotifColor(n.type);

                      return Dismissible(
                        key: Key(n.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _markAsRead(n.id),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.check, color: AppTheme.successColor),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            if (!n.isRead) _markAsRead(n.id);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: n.isRead ? Theme.of(context).cardColor : AppTheme.primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(icon, color: color, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              n.title,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w600,
                                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                              ),
                                            ),
                                          ),
                                          if (!n.isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).brightness == Brightness.dark ? AppTheme.accentColor : AppTheme.primaryColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        n.body,
                                        style: const TextStyle(fontSize: 13, color: AppTheme.textMutedColor, height: 1.3),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _formatRelativeTime(n.timestamp),
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textLightColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
    );
  }
}
