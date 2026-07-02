import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../services/auth_provider.dart';
import 'package:provider/provider.dart';

class StaffCounterScreen extends StatefulWidget {
  const StaffCounterScreen({super.key});

  @override
  State<StaffCounterScreen> createState() => _StaffCounterScreenState();
}

class _StaffCounterScreenState extends State<StaffCounterScreen> {
  List<ServiceCounter> _counters = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchCounters();
  }

  Future<void> _fetchCounters() async {
    try {
      final data = await ApiService.getProviderCounters();
      if (mounted) {
        setState(() {
          _counters = data.map((json) => ServiceCounter.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load counters: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int activeCount = _counters.where((c) => c.status == CounterStatus.active).length;
    final int breakCount = _counters.where((c) => c.status == CounterStatus.onBreak).length;
    final int offlineCount = _counters.where((c) => c.status == CounterStatus.offline).length;

    final user = Provider.of<AuthProvider>(context).user;
    final categoryStr = (user?.role.name ?? 'hospital').toLowerCase();
    
    final Color categoryColor = categoryStr == 'bank'
        ? AppTheme.bankColor
        : categoryStr == 'govtoffice'
            ? AppTheme.govtColor
            : AppTheme.primaryColor;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Staff & Counters'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() { _isLoading = true; _error = ''; });
              _fetchCounters();
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
                      // ── Summary ──
                      Row(
                        children: [
                          Expanded(child: _buildMiniStat('Active', '$activeCount', AppTheme.successColor)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildMiniStat('On Break', '$breakCount', AppTheme.warningColor)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildMiniStat('Offline', '$offlineCount', AppTheme.textLightColor)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Counters Management',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDarkColor),
                      ),
                      const SizedBox(height: 14),
                      
                      if (_counters.isEmpty)
                        const Center(child: Text('No counters found.', style: TextStyle(color: AppTheme.textMutedColor))),

                      ..._counters.asMap().entries.map((entry) {
                        final index = entry.key;
                        final c = entry.value;
                        final status = c.status;
                        
                        Color statusColor;
                        String statusLabel;
                        IconData statusIcon;

                        switch (status) {
                          case CounterStatus.active:
                            statusColor = AppTheme.successColor;
                            statusLabel = 'Active';
                            statusIcon = Icons.circle;
                            break;
                          case CounterStatus.onBreak:
                            statusColor = AppTheme.warningColor;
                            statusLabel = 'On Break';
                            statusIcon = Icons.pause_circle;
                            break;
                          case CounterStatus.offline:
                          default:
                            statusColor = AppTheme.textLightColor;
                            statusLabel = 'Offline';
                            statusIcon = Icons.circle_outlined;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '#${c.number}',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: statusColor),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.staffName,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textDarkColor),
                                    ),
                                    const SizedBox(height: 4),
                                    if (c.activeTokenNumber != null)
                                      Text(
                                        'Serving: ${c.activeTokenNumber}',
                                        style: const TextStyle(fontSize: 13, color: AppTheme.textMutedColor),
                                      )
                                    else
                                      Text(
                                        status == CounterStatus.onBreak ? 'Currently on break' : status == CounterStatus.offline ? 'No staff assigned' : 'Ready to serve',
                                        style: const TextStyle(fontSize: 13, color: AppTheme.textMutedColor),
                                      ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          'Served: ${c.todayCustomers}',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textMutedColor),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Avg: ${c.avgServiceMinutes}m',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textMutedColor),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(statusIcon, size: 10, color: statusColor),
                                        const SizedBox(width: 4),
                                        Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Update actions are omitted in this basic API integration
                                  // Can implement Assign, Toggle Status later via API
                                ],
                              ),
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
