import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';

class SmartSlotScreen extends StatelessWidget {
  final String providerId;
  const SmartSlotScreen({super.key, required this.providerId});

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Smart Slot Recommendation'),
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
            // ── AI Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.aiGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.aiAccent.withOpacity(0.3),
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
                      const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'AI Analysis Complete',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      const Spacer(),
                      // ── Prediction Confidence ──
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                value: 0.92,
                                strokeWidth: 2,
                                backgroundColor: Colors.white.withOpacity(0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('92%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Based on historical patterns and current queue data, we recommend visiting at 2:00 PM for the shortest wait time.',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85), height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Prediction Factors ──
            const Text(
              'Prediction Factors',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _buildFactorCard(Icons.history, 'Historical\nData', 85, AppTheme.infoColor)),
                const SizedBox(width: 10),
                Expanded(child: _buildFactorCard(Icons.people_outline, 'Live\nQueue', 92, AppTheme.successColor)),
                const SizedBox(width: 10),
                Expanded(child: _buildFactorCard(Icons.access_time, 'Peak\nHours', 78, AppTheme.warningColor)),
              ],
            ),
            const SizedBox(height: 28),

            // ── AI Recommended Slots ──
            const Text(
              '⭐ Recommended Slots',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            ...List.generate(recommendations.length, (index) {
              final rec = recommendations[index];
              final score = (rec['score'] as double) * 100;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: index == 0 ? AppTheme.aiAccent.withOpacity(0.4) : AppTheme.borderColor,
                    width: index == 0 ? 2 : 1,
                  ),
                  boxShadow: index == 0
                      ? [BoxShadow(color: AppTheme.aiAccent.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))]
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: index == 0
                            ? AppTheme.aiAccent.withOpacity(0.1)
                            : Theme.of(context).dividerColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '#${index + 1}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: index == 0 ? AppTheme.aiAccent : AppTheme.textMutedColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
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
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (index == 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.aiAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    rec['label'] as String,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.aiAccent),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Predicted wait: ~${rec['wait']} min',
                            style: const TextStyle(fontSize: 13, color: AppTheme.textMutedColor),
                          ),
                        ],
                      ),
                    ),
                    // Score badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${score.toInt()}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
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
            const Text(
              'Predicted Waiting Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: [
                  // Simple bar chart
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
                                  '${slot['wait']}',
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.textMutedColor),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 140 * crowd,
                                  decoration: BoxDecoration(
                                    color: barColor.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // X-axis labels
                  Row(
                    children: List.generate(allSlots.length, (index) {
                      final slot = allSlots[index];
                      final time = (slot['time'] as String).replaceAll(' AM', '').replaceAll(' PM', '');
                      return Expanded(
                        child: Text(
                          time,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 7, color: AppTheme.textLightColor),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Best Time Suggestions ──
            const Text(
              'Tips for Visiting',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            _buildSuggestionTile(context, Icons.schedule, AppTheme.successColor, 'Shortest Wait', 'Visit at 2:00 PM — only ~8 min wait'),
            _buildSuggestionTile(context, Icons.groups_outlined, AppTheme.infoColor, 'Least Crowded', 'Morning 9:00 AM has minimal crowd'),
            _buildSuggestionTile(context, Icons.trending_down, AppTheme.warningColor, 'Avoid Peak', 'Skip 11:00 AM – 12:00 PM for less waiting'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionTile(BuildContext context, IconData icon, Color color, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textMutedColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorCard(IconData icon, String label, int percentage, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            '$percentage%',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppTheme.textMutedColor, height: 1.2),
          ),
        ],
      ),
    );
  }
}
