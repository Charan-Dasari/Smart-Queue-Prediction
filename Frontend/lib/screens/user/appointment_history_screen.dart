import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/floating_capsule_nav_bar.dart';

class AppointmentHistoryScreen extends StatefulWidget {
  const AppointmentHistoryScreen({super.key});

  @override
  State<AppointmentHistoryScreen> createState() => _AppointmentHistoryScreenState();
}

class _AppointmentHistoryScreenState extends State<AppointmentHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Appointment> _allAppointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    try {
      final data = await ApiService.getMyAppointments();
      if (mounted) {
        setState(() {
          _allAppointments = data
              .map((a) => Appointment.fromJson(a as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Appointment> _filteredAppointments(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return _allAppointments.where((a) => a.status == AppointmentStatus.completed).toList();
      case 2:
        return _allAppointments.where((a) => a.status == AppointmentStatus.cancelled).toList();
      default:
        return _allAppointments;
    }
  }

  Color _getCategoryColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('hospital') || lower.contains('clinic') || lower.contains('medical')) {
      return AppTheme.hospitalColor;
    } else if (lower.contains('bank') || lower.contains('financial') || lower.contains('atm')) {
      return AppTheme.bankColor;
    } else if (lower.contains('restaurant') || lower.contains('cafe') || lower.contains('food')) {
      return Colors.orange;
    } else if (lower.contains('college') || lower.contains('university') || lower.contains('school')) {
      return AppTheme.collegeColor;
    } else if (lower.contains('office') || lower.contains('collector') || lower.contains('govt') || lower.contains('government')) {
      return AppTheme.govtColor;
    }
    return AppTheme.otherColor;
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Appointment History'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textMutedColor,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          indicatorColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.accentColor : AppTheme.primaryColor,
          indicatorWeight: 2.5,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadAppointments,
                  child: TabBarView(
                    controller: _tabController,
                    children: List.generate(3, (tabIndex) {
                      final items = _filteredAppointments(tabIndex);
                      if (items.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.history,
                                size: 48,
                                color: AppTheme.textLightColor,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                tabIndex == 0
                                    ? 'No appointments yet'
                                    : tabIndex == 1
                                        ? 'No completed appointments'
                                        : 'No cancelled appointments',
                                style: const TextStyle(fontSize: 15, color: AppTheme.textMutedColor),
                              ),
                              const SizedBox(height: 8),
                              if (tabIndex == 0)
                                const Text(
                                  'Book your first appointment to get started!',
                                  style: TextStyle(fontSize: 13, color: AppTheme.textLightColor),
                                ),
                            ],
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                        itemCount: items.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final apt = items[index];
                          Color statusColor;
                          String statusLabel;
                          // Determine status display
                          final bool isSkipped = apt.status == AppointmentStatus.cancelled && apt.skipReason != null;
                          if (isSkipped) {
                            statusColor = Colors.orange;
                            statusLabel = 'Skipped';
                          } else {
                            switch (apt.status) {
                              case AppointmentStatus.completed:
                                statusColor = AppTheme.successColor;
                                statusLabel = 'Completed';
                                break;
                              case AppointmentStatus.cancelled:
                                statusColor = AppTheme.errorColor;
                                statusLabel = 'Cancelled';
                                break;
                              case AppointmentStatus.serving:
                                statusColor = AppTheme.warningColor;
                                statusLabel = 'Serving';
                                break;
                              case AppointmentStatus.inQueue:
                                statusColor = AppTheme.accentColor;
                                statusLabel = 'In Queue';
                                break;
                              default:
                                statusColor = AppTheme.infoColor;
                                statusLabel = 'Booked';
                                break;
                            }
                          }

                          final catColor = _getCategoryColor(apt.serviceName);

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.getBorderColor(context)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: catColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.business, color: catColor, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            apt.providerName,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Theme.of(context).textTheme.bodyLarge?.color,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            apt.serviceName,
                                            style: const TextStyle(fontSize: 13, color: AppTheme.textMutedColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // Skip reason banner
                                if (isSkipped && apt.skipReason != null) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            apt.skipReason!,
                                            style: TextStyle(fontSize: 12, color: Colors.orange.shade800, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const Divider(color: AppTheme.dividerColor, height: 24),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    _buildDetailChip(Icons.calendar_today, _formatDate(apt.date)),
                                    _buildDetailChip(Icons.access_time, _formatTime(apt.date)),
                                    if (apt.tokenNumber.isNotEmpty)
                                      _buildDetailChip(Icons.confirmation_number_outlined, apt.tokenNumber),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),
          const Positioned(
            left: 24,
            right: 24,
            bottom: 16,
            child: FloatingCapsuleNavBar(currentIndex: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textMutedColor),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.textMutedColor)),
      ],
    );
  }
}
