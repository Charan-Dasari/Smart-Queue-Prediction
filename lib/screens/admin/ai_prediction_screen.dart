import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';

class AIPredictionScreen extends StatelessWidget {
  const AIPredictionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('AI Predictions'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: AppTheme.aiGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text('AI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
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
            // ── Crowd Level Gauge ──
            const Text(
              'Predicted Crowd Level',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDarkColor),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.aiGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.aiAccent.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Gauge ring
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 160,
                          height: 160,
                          child: CircularProgressIndicator(
                            value: 0.65,
                            strokeWidth: 12,
                            backgroundColor: Colors.white.withOpacity(0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '65%',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Moderate',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildGaugeLegend('Low', '0-40%', Colors.white.withOpacity(0.5)),
                      _buildGaugeLegend('Moderate', '40-70%', Colors.white.withOpacity(0.8)),
                      _buildGaugeLegend('High', '70-100%', Colors.white),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Future Waiting Time ──
            const Text(
              'Future Waiting Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDarkColor),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: [
                  _buildFutureTimeRow('12:00 PM', 25, 0.8),
                  const Divider(color: AppTheme.dividerColor, height: 16),
                  _buildFutureTimeRow('01:00 PM', 15, 0.5),
                  const Divider(color: AppTheme.dividerColor, height: 16),
                  _buildFutureTimeRow('02:00 PM', 10, 0.3),
                  const Divider(color: AppTheme.dividerColor, height: 16),
                  _buildFutureTimeRow('03:00 PM', 18, 0.6),
                  const Divider(color: AppTheme.dividerColor, height: 16),
                  _buildFutureTimeRow('04:00 PM', 22, 0.75),
                  const Divider(color: AppTheme.dividerColor, height: 16),
                  _buildFutureTimeRow('05:00 PM', 30, 0.9),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Resource Requirement Prediction ──
            const Text(
              'Resource Requirement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDarkColor),
            ),
            const SizedBox(height: 14),
            _buildResourceCard(
              Icons.countertops_outlined,
              'Recommended Counters',
              '5 counters',
              'Open 2 more counters to reduce wait time by ~40%',
              AppTheme.infoColor,
            ),
            _buildResourceCard(
              Icons.group_outlined,
              'Staff Requirement',
              '8 staff members',
              'Current: 4 active. Consider calling in backup staff for peak.',
              AppTheme.warningColor,
            ),
            _buildResourceCard(
              Icons.schedule,
              'Peak Window',
              '11:00 AM - 1:00 PM',
              'Highest crowd expected. Plan maximum resources.',
              AppTheme.errorColor,
            ),
            _buildResourceCard(
              Icons.trending_down,
              'Low Activity Window',
              '2:00 PM - 3:00 PM',
              'Good window for staff breaks and maintenance.',
              AppTheme.successColor,
            ),
            const SizedBox(height: 28),

            // ── Confidence ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.aiAccentLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.aiAccent.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.aiAccent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Prediction Confidence: 87%',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDarkColor),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Based on last 30 days of historical data and current trends',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMutedColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Counter Recommendation ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentColor.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.countertops_outlined, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Open Counter 5',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Reduce average wait time by ~40%',
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
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

  Widget _buildGaugeLegend(String label, String range, Color color) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.9))),
        Text(range, style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.5))),
      ],
    );
  }

  Widget _buildFutureTimeRow(String time, int waitMinutes, double level) {
    final barColor = level < 0.4 ? AppTheme.queueLow : level < 0.7 ? AppTheme.queueMedium : AppTheme.queueHigh;
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(time, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDarkColor)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: level,
              backgroundColor: barColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 50,
          child: Text(
            '~$waitMinutes min',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: barColor),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildResourceCard(IconData icon, String title, String value, String description, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                Row(
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDarkColor)),
                    const Spacer(),
                    Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 12, color: AppTheme.textMutedColor, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
