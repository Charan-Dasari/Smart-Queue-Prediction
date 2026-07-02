import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import 'dart:async';

class QueueManagementScreen extends StatefulWidget {
  const QueueManagementScreen({super.key});

  @override
  State<QueueManagementScreen> createState() => _QueueManagementScreenState();
}

class _QueueManagementScreenState extends State<QueueManagementScreen> {
  List<QueueToken> _queue = [];
  bool _isLoading = true;
  String _error = '';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchQueue();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchQueue(isRefresh: true));
  }

  Future<void> _fetchQueue({bool isRefresh = false}) async {
    try {
      final data = await ApiService.getProviderQueue();
      if (mounted) {
        setState(() {
          _queue = data.map((json) => QueueToken.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !isRefresh) {
        setState(() {
          _error = 'Failed to load queue';
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

  @override
  Widget build(BuildContext context) {
    int inQueueCount = _queue.where((t) => t.status == AppointmentStatus.inQueue).length;
    int servingCount = _queue.where((t) => t.status == AppointmentStatus.serving).length;
    int completedCount = _queue.where((t) => t.status == AppointmentStatus.completed).length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Queue Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() { _isLoading = true; _error = ''; });
              _fetchQueue();
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Stats Row ──
                      Row(
                        children: [
                          Expanded(child: _buildMiniStat('In Queue', '$inQueueCount', AppTheme.infoColor)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildMiniStat('Serving', '$servingCount', AppTheme.successColor)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildMiniStat('Completed', '$completedCount', AppTheme.accentColor)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Current Queue',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDarkColor),
                      ),
                      const SizedBox(height: 14),

                      if (_queue.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('No active queue tokens right now.', style: TextStyle(color: AppTheme.textMutedColor)),
                          ),
                        ),

                      ..._queue.where((q) => q.status == AppointmentStatus.inQueue || q.status == AppointmentStatus.serving).map((item) {
                        final isServing = item.status == AppointmentStatus.serving;
                        final statusColor = isServing ? AppTheme.successColor : AppTheme.warningColor;
                        final statusLabel = isServing ? 'Serving' : 'Waiting';
                        final statusIcon = isServing ? Icons.play_circle_filled : Icons.hourglass_empty;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isServing ? AppTheme.successColor.withOpacity(0.05) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isServing ? AppTheme.successColor.withOpacity(0.2) : AppTheme.borderColor,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        item.tokenNumber,
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.providerName, // Assuming user's name is not in QueueToken easily, using generic or service
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textDarkColor),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${item.serviceName} • Wait: ~${item.estimatedWaitMinutes}m',
                                          style: const TextStyle(fontSize: 12, color: AppTheme.textMutedColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(statusIcon, size: 12, color: statusColor),
                                        const SizedBox(width: 4),
                                        Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              // Note: We removed the action buttons here since Admins don't have permission to modify tokens directly.
                              // Staff handles it from the Staff Queue Screen.
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMutedColor)),
        ],
      ),
    );
  }
}
