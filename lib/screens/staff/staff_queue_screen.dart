import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../services/auth_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class StaffQueueScreen extends StatefulWidget {
  const StaffQueueScreen({super.key});

  @override
  State<StaffQueueScreen> createState() => _StaffQueueScreenState();
}

class _StaffQueueScreenState extends State<StaffQueueScreen> {
  int _selectedFilterIndex = 0; // 0 = All, 1 = Waiting, 2 = Serving, 3 = Completed, 4 = Skipped
  List<QueueToken> _tokens = [];
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
          _tokens = data.map((json) => QueueToken.fromJson(json)).toList();
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

  List<QueueToken> get _filteredTokens {
    if (_selectedFilterIndex == 0) return _tokens;
    final statuses = [
      null, 
      AppointmentStatus.inQueue, 
      AppointmentStatus.serving, 
      AppointmentStatus.completed, 
      AppointmentStatus.cancelled
    ];
    return _tokens.where((t) => t.status == statuses[_selectedFilterIndex]).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final categoryStr = (user?.role.name ?? 'hospital').toLowerCase();
    
    final Color themeColor = categoryStr == 'bank'
        ? AppTheme.bankColor
        : categoryStr == 'govtoffice'
            ? AppTheme.govtColor
            : AppTheme.staffColor;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Detailed Queue'),
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
              : Column(
                  children: [
                    // ── Horizontal Filter Chips ──
                    Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
                      ),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _buildFilterChip(0, 'All', themeColor),
                          _buildFilterChip(1, 'Waiting', themeColor),
                          _buildFilterChip(2, 'Serving', themeColor),
                          _buildFilterChip(3, 'Completed', themeColor),
                          _buildFilterChip(4, 'Skipped/Cancelled', themeColor),
                        ],
                      ),
                    ),

                    // ── Queue List ──
                    if (_filteredTokens.isEmpty)
                      const Expanded(
                        child: Center(child: Text('No tokens found', style: TextStyle(color: AppTheme.textMutedColor))),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredTokens.length,
                          itemBuilder: (context, index) {
                            final token = _filteredTokens[index];
                            return _buildTokenTile(token, themeColor);
                          },
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildFilterChip(int index, String label, Color activeColor) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : AppTheme.borderColor,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppTheme.textDarkColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTokenTile(QueueToken token, Color primaryColor) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel = token.status.name.toUpperCase();

    switch (token.status) {
      case AppointmentStatus.serving:
        statusColor = primaryColor;
        statusIcon = Icons.play_circle_filled;
        break;
      case AppointmentStatus.inQueue:
        statusColor = AppTheme.infoColor;
        statusIcon = Icons.hourglass_empty;
        break;
      case AppointmentStatus.completed:
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
        break;
      case AppointmentStatus.cancelled:
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = AppTheme.textLightColor;
        statusIcon = Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          // Token Box
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  token.tokenNumber,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  statusLabel.length > 8 ? '${statusLabel.substring(0, 8)}.' : statusLabel,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  token.providerName, // Or user name if available
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDarkColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  token.serviceName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMutedColor,
                  ),
                ),
              ],
            ),
          ),
          // Time / Status Icon
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('hh:mm a').format(token.createdAt.toLocal()),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMutedColor,
                ),
              ),
              const SizedBox(height: 6),
              Icon(
                statusIcon,
                color: statusColor,
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
