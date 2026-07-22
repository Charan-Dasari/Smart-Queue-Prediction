import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class AppointmentHistoryScreen extends StatefulWidget {
  const AppointmentHistoryScreen({super.key});

  @override
  State<AppointmentHistoryScreen> createState() => _AppointmentHistoryScreenState();
}

class _AppointmentHistoryScreenState extends State<AppointmentHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Appointment> _appointments = [];
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
          _appointments = data
              .map((a) => Appointment.fromJson(a as Map<String, dynamic>))
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

  List<Appointment> _filteredAppointments(int tabIndex) {
    if (tabIndex == 0) return _appointments;
    if (tabIndex == 1) return _appointments.where((a) => a.status == AppointmentStatus.completed).toList();
    return _appointments.where((a) => a.status == AppointmentStatus.cancelled).toList();
  }

  IconData _getCategoryIcon(String providerName) {
    // Infer category from provider name as a fallback
    final lower = providerName.toLowerCase();
    if (lower.contains('hospital') || lower.contains('clinic') || lower.contains('dental') || lower.contains('medical')) {
      return Icons.local_hospital;
    } else if (lower.contains('bank')) {
      return Icons.account_balance;
    } else if (lower.contains('college') || lower.contains('university') || lower.contains('school')) {
      return Icons.school_outlined;
    } else if (lower.contains('office') || lower.contains('collector') || lower.contains('govt') || lower.contains('government')) {
      return Icons.account_balance_outlined;
    }
    return Icons.business;
  }

  Color _getCategoryColor(String providerName) {
    final lower = providerName.toLowerCase();
    if (lower.contains('hospital') || lower.contains('clinic') || lower.contains('dental') || lower.contains('medical')) {
      return AppTheme.hospitalColor;
    } else if (lower.contains('bank')) {
      return AppTheme.bankColor;
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
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: _isLoading
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 48, color: AppTheme.textLightColor),
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
                    padding: const EdgeInsets.all(20),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final apt = items[index];
                      Color statusColor;
                      String statusLabel;
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
                          statusLabel = 'Upcoming';
                      }

                      final icon = _getCategoryIcon(apt.providerName);
                      final color = _getCategoryColor(apt.providerName);

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(icon, color: color, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        apt.providerName,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                        ),
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
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: AppTheme.dividerColor, height: 24),
                            Row(
                              children: [
                                _buildDetailChip(Icons.calendar_today, _formatDate(apt.date)),
                                const SizedBox(width: 16),
                                _buildDetailChip(Icons.access_time, _formatTime(apt.date)),
                                if (apt.tokenNumber.isNotEmpty) ...[
                                  const SizedBox(width: 16),
                                  _buildDetailChip(Icons.confirmation_number_outlined, apt.tokenNumber),
                                ],
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              break;
            case 2:
              context.push('/notifications');
              break;
            case 3:
              context.push('/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), activeIcon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
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
