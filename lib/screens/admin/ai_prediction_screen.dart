import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';

class AIPredictionScreen extends StatelessWidget {
  const AIPredictionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return UserThemeWrapper(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => context.pop(),
          ),
          title: const Text('AI Queue Predictions'),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppTheme.aiGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.aiAccent.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                  SizedBox(width: 6),
                  Text('AI Engine Live', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
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
              // ── Predicted Crowd Gauge Card ──
              Text(
                'Predicted Crowd Capacity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.aiGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.aiAccent.withOpacity(0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: 170,
                      height: 170,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 170,
                            height: 170,
                            child: CircularProgressIndicator(
                              value: 0.65,
                              strokeWidth: 14,
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
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -1,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'MODERATE CROWD',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildGaugeLegend('Low', '0-40%', Colors.white.withOpacity(0.5)),
                        _buildGaugeLegend('Moderate', '40-70%', Colors.white),
                        _buildGaugeLegend('High Peak', '70-100%', AppTheme.warningColor),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Hourly Wait Time Forecast ──
              Text(
                'Hourly Wait Time Forecast',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  children: [
                    _buildFutureTimeRow(context, '12:00 PM', 25, 0.8),
                    Divider(color: theme.dividerColor, height: 20),
                    _buildFutureTimeRow(context, '01:00 PM', 15, 0.5),
                    Divider(color: theme.dividerColor, height: 20),
                    _buildFutureTimeRow(context, '02:00 PM', 10, 0.3),
                    Divider(color: theme.dividerColor, height: 20),
                    _buildFutureTimeRow(context, '03:00 PM', 18, 0.6),
                    Divider(color: theme.dividerColor, height: 20),
                    _buildFutureTimeRow(context, '04:00 PM', 22, 0.75),
                    Divider(color: theme.dividerColor, height: 20),
                    _buildFutureTimeRow(context, '05:00 PM', 30, 0.9),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Resource Requirement AI Recommendations ──
              Text(
                'Smart Resource Allocator',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 14),
              _buildResourceCard(
                context,
                Icons.countertops_rounded,
                'Recommended Counters',
                '5 Counters',
                'Open 2 extra counters to reduce customer wait time by ~40%',
                AppTheme.infoColor,
              ),
              _buildResourceCard(
                context,
                Icons.badge_rounded,
                'Staff Requirement',
                '8 Staff Members',
                'Current: 4 active. Consider calling backup staff for peak hour.',
                AppTheme.warningColor,
              ),
              _buildResourceCard(
                context,
                Icons.schedule_rounded,
                'Peak Crowd Window',
                '11:00 AM - 1:00 PM',
                'Highest arrival rate expected. Maximize counter throughput.',
                AppTheme.errorColor,
              ),
              _buildResourceCard(
                context,
                Icons.trending_down_rounded,
                'Optimal Break Window',
                '2:00 PM - 3:00 PM',
                'Lowest crowd density. Ideal window for staff rotations.',
                AppTheme.successColor,
              ),
              const SizedBox(height: 24),

              // ── Model Confidence Banner ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.aiAccent.withOpacity(0.15) : AppTheme.aiAccentLight,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.aiAccent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppTheme.aiAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Prediction Accuracy: 94.2%',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Trained on 30-day queue velocity models and live arrival patterns',
                            style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGaugeLegend(String label, String range, Color color) {
    return Column(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.9))),
        Text(range, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.6))),
      ],
    );
  }

  Widget _buildFutureTimeRow(BuildContext context, String time, int waitMinutes, double level) {
    final theme = Theme.of(context);
    final barColor = level < 0.4 ? AppTheme.queueLow : level < 0.7 ? AppTheme.queueMedium : AppTheme.queueHigh;
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(time, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: level,
              backgroundColor: barColor.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 14),
        SizedBox(
          width: 60,
          child: Text(
            '~$waitMinutes m',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: barColor),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildResourceCard(BuildContext context, IconData icon, String title, String value, String description, Color color) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        value,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

