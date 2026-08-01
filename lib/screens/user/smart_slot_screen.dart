import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';

class SmartSlotScreen extends StatelessWidget {
  final String providerId;
  const SmartSlotScreen({super.key, required this.providerId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final recommendations = [
      {'time': '02:00 PM', 'wait': 8, 'score': 0.95, 'label': 'Best Choice'},
      {'time': '02:30 PM', 'wait': 12, 'score': 0.88, 'label': 'Great Option'},
      {'time': '09:00 AM', 'wait': 10, 'score': 0.82, 'label': 'Good Slot'},
    ];

    final allSlots = [
      {'time': '09:00 AM', 'crowd': 0.2, 'wait': 10},
      {'time': '09:30 AM', 'crowd': 0.3, 'wait': 12},
      {'time': '10:00 AM', 'crowd': 0.6, 'wait': 22},
      {'time': '10:30 AM', 'crowd': 0.8, 'wait': 35},
      {'time': '11:00 AM', 'crowd': 0.9, 'wait': 45},
      {'time': '11:30 AM', 'crowd': 0.7, 'wait': 30},
      {'time': '02:00 PM', 'crowd': 0.2, 'wait': 8},
      {'time': '02:30 PM', 'crowd': 0.3, 'wait': 12},
      {'time': '03:00 PM', 'crowd': 0.5, 'wait': 20},
      {'time': '03:30 PM', 'crowd': 0.6, 'wait': 25},
      {'time': '04:00 PM', 'crowd': 0.7, 'wait': 30},
    ];

    return UserThemeWrapper(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => context.pop(),
          ),
          title: const Text('Smart Slot Optimizer'),
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
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                  SizedBox(width: 6),
                  Text('AI Smart Engine', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
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
              // ── AI Header ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: AppTheme.aiGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.aiAccent.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          'AI Optimizer Complete',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text('92% Accuracy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Based on historical arrival rates and live queue velocity, visiting at 2:00 PM will minimize your estimated wait time to under 8 minutes.',
                      style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9), height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Prediction Factors ──
              Text(
                'AI Analysis Factors',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _buildFactorCard(context, Icons.history_rounded, 'Historical\nData', 85, AppTheme.infoColor)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildFactorCard(context, Icons.people_outline_rounded, 'Live\nQueue', 92, AppTheme.successColor)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildFactorCard(context, Icons.access_time_rounded, 'Peak\nHours', 78, AppTheme.warningColor)),
                ],
              ),
              const SizedBox(height: 28),

              // ── AI Recommended Slots ──
              Text(
                'Top AI Recommended Slots',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 14),
              ...List.generate(recommendations.length, (index) {
                final rec = recommendations[index];
                final score = (rec['score'] as double) * 100;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: index == 0 ? AppTheme.aiAccent : theme.dividerColor,
                      width: index == 0 ? 1.8 : 1,
                    ),
                    boxShadow: index == 0
                        ? [BoxShadow(color: AppTheme.aiAccent.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 4))]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: index == 0
                              ? AppTheme.aiAccent.withOpacity(0.12)
                              : theme.dividerColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            '#${index + 1}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: index == 0 ? AppTheme.aiAccent : theme.hintColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  rec['time'] as String,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (index == 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.aiAccent.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      rec['label'] as String,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.aiAccent),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Predicted wait time: ~${rec['wait']} mins',
                              style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${score.toInt()}% Match',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.successColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 28),

              // ── Predicted Waiting Time Chart ──
              Text(
                'Crowd Distribution Forecast',
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
                    SizedBox(
                      height: 160,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(allSlots.length, (index) {
                          final slot = allSlots[index];
                          final crowd = slot['crowd'] as double;
                          final barColor = crowd < 0.4
                              ? AppTheme.queueLow
                              : crowd < 0.7
                                  ? AppTheme.queueMedium
                                  : AppTheme.queueHigh;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '${slot['wait']}m',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: theme.textTheme.bodyMedium?.color),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 130 * crowd,
                                    decoration: BoxDecoration(
                                      color: barColor.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: List.generate(allSlots.length, (index) {
                        final slot = allSlots[index];
                        final time = (slot['time'] as String).replaceAll(' AM', '').replaceAll(' PM', '');
                        return Expanded(
                          child: Text(
                            time,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 8, color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.w600),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Best Time Suggestions ──
              Text(
                'Smart Visit Advice',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 14),
              _buildSuggestionTile(context, Icons.schedule_rounded, AppTheme.successColor, 'Shortest Wait Window', 'Visit at 2:00 PM — only ~8 min expected wait'),
              _buildSuggestionTile(context, Icons.groups_rounded, AppTheme.infoColor, 'Least Crowded Period', 'Morning 9:00 AM features minimal crowd density'),
              _buildSuggestionTile(context, Icons.trending_down_rounded, AppTheme.warningColor, 'Avoid Peak Hours', 'Skip 11:00 AM – 12:00 PM for optimal experience'),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionTile(BuildContext context, IconData icon, Color color, String title, String subtitle) {
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
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorCard(BuildContext context, IconData icon, String label, int percentage, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            '$percentage%',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.textTheme.bodyMedium?.color, height: 1.2),
          ),
        ],
      ),
    );
  }
}

