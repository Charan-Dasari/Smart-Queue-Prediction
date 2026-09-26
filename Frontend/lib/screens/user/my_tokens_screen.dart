import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';
import '../../widgets/floating_capsule_nav_bar.dart';

class MyTokensScreen extends StatefulWidget {
  const MyTokensScreen({super.key});

  @override
  State<MyTokensScreen> createState() => _MyTokensScreenState();
}

class _MyTokensScreenState extends State<MyTokensScreen> {
  bool _isLoading = true;
  List<QueueToken> _tokens = [];

  @override
  void initState() {
    super.initState();
    _fetchTokens();
  }

  Future<void> _fetchTokens() async {
    try {
      final data = await ApiService.getMyActiveTokens();
      if (mounted) {
        setState(() {
          _tokens = data.map((e) => QueueToken.fromJson(e as Map<String, dynamic>)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load tokens: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTokens = _tokens.where((t) => 
        t.status != AppointmentStatus.completed && 
        t.status != AppointmentStatus.cancelled).toList();

    return UserThemeWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Active Tokens'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 22),
              onPressed: () {
                setState(() => _isLoading = true);
                _fetchTokens();
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : activeTokens.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                        itemCount: activeTokens.length,
                        itemBuilder: (context, index) {
                          final token = activeTokens[index];
                          return _buildTokenCard(context, token);
                        },
                      ),
            const Positioned(
              left: 24,
              right: 24,
              bottom: 16,
              child: FloatingCapsuleNavBar(currentIndex: 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.confirmation_number_outlined, size: 48, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 20),
            Text(
              'No Active Tokens Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You don\'t have any active tokens or upcoming queue positions right now.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => context.push('/services'),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Book New Appointment', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenCard(BuildContext context, QueueToken token) {
    final theme = Theme.of(context);
    final isServing = token.status == AppointmentStatus.serving;
    final isWaiting = token.status == AppointmentStatus.inQueue;
    final isCancelled = token.status == AppointmentStatus.cancelled;

    final statusColor = isCancelled ? AppTheme.errorColor : isServing ? AppTheme.successColor : isWaiting ? AppTheme.warningColor : AppTheme.infoColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            await context.push('/token/${token.id}');
            _fetchTokens();
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.apartment_rounded, color: AppTheme.primaryColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        token.providerName,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        token.serviceName,
                        style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Token ${token.tokenNumber}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.accentColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              token.status.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: theme.hintColor, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

