import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  int _selectedPeriod = 0; // 0 = Daily, 1 = Weekly

  final List<Map<String, double>> _peakHours = [
    {'hour': 9, 'value': 0.3},
    {'hour': 10, 'value': 0.6},
    {'hour': 11, 'value': 0.85},
    {'hour': 12, 'value': 0.95},
    {'hour': 13, 'value': 0.5},
    {'hour': 14, 'value': 0.4},
    {'hour': 15, 'value': 0.55},
    {'hour': 16, 'value': 0.7},
    {'hour': 17, 'value': 0.9},
    {'hour': 18, 'value': 0.45},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Analytics'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _selectedPeriod = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _selectedPeriod == 0 ? AppTheme.primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Daily',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _selectedPeriod == 0 ? Colors.white : AppTheme.textMutedColor,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _selectedPeriod = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _selectedPeriod == 1 ? AppTheme.primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Weekly',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _selectedPeriod == 1 ? Colors.white : AppTheme.textMutedColor,
                      ),
                    ),
                  ),
                ),
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
            // ── Key Metrics ──
            Row(
              children: [
                Expanded(child: _buildMetricCard('Total Visitors', _selectedPeriod == 0 ? '89' : '523', '+12%', true)),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard('Avg Wait', _selectedPeriod == 0 ? '18 min' : '21 min', '-8%', false)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildMetricCard('Completion', _selectedPeriod == 0 ? '94%' : '91%', '+3%', true)),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard('No Shows', _selectedPeriod == 0 ? '5' : '28', '-15%', false)),
              ],
            ),
            const SizedBox(height: 28),

            // ── Peak Hours Chart ──
            const Text(
              'Peak Hours',
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
                  SizedBox(
                    height: 180,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: _peakHours.map((data) {
                        final value = data['value']!;
                        final hour = data['hour']!.toInt();
                        final barColor = value < 0.4
                            ? AppTheme.queueLow
                            : value < 0.7
                                ? AppTheme.queueMedium
                                : AppTheme.queueHigh;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '${(value * 100).toInt()}%',
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.textMutedColor),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 150 * value,
                                  decoration: BoxDecoration(
                                    color: barColor.withOpacity(0.75),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${hour > 12 ? hour - 12 : hour}${hour >= 12 ? 'P' : 'A'}',
                                  style: const TextStyle(fontSize: 9, color: AppTheme.textMutedColor),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Average Waiting Time Trend ──
            const Text(
              'Wait Time Trend',
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
                  // Simple line chart using dots
                  SizedBox(
                    height: 120,
                    child: CustomPaint(
                      size: const Size(double.infinity, 120),
                      painter: _WaitTimeTrendPainter(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: (_selectedPeriod == 0
                            ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                            : ['W1', 'W2', 'W3', 'W4'])
                        .map((label) => Text(
                              label,
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMutedColor),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Queue Trends ──
            const Text(
              'Queue Trends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDarkColor),
            ),
            const SizedBox(height: 14),
            _buildTrendItem('Busiest Day', 'Wednesday', Icons.trending_up, AppTheme.errorColor),
            _buildTrendItem('Quietest Day', 'Sunday', Icons.trending_down, AppTheme.successColor),
            _buildTrendItem('Peak Service', 'General Consultation', Icons.star, AppTheme.warningColor),
            _buildTrendItem('Avg Queue Length', '8 people', Icons.people_outline, AppTheme.infoColor),
            const SizedBox(height: 28),

            // ── Average Wait Time Card ──
            const Text(
              'Average Wait Time',
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
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.access_time, color: AppTheme.warningColor, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('14 min', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.textDarkColor)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.successColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('↓ 3 min', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.successColor)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text('Compared to last week', style: TextStyle(fontSize: 12, color: AppTheme.textMutedColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Daily Visitors ──
            const Text(
              'Daily Visitors',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDarkColor),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 120,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildVisitorBar('Mon', 0.6, 72),
                        _buildVisitorBar('Tue', 0.7, 85),
                        _buildVisitorBar('Wed', 0.9, 108),
                        _buildVisitorBar('Thu', 0.75, 90),
                        _buildVisitorBar('Fri', 0.65, 78),
                        _buildVisitorBar('Sat', 0.45, 54),
                        _buildVisitorBar('Sun', 0.25, 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, String change, bool isPositive) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMutedColor)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textDarkColor)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isPositive ? AppTheme.successColor : AppTheme.errorColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isPositive ? AppTheme.successColor : AppTheme.errorColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendItem(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textMutedColor)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDarkColor)),
        ],
      ),
    );
  }

  Widget _buildVisitorBar(String day, double ratio, int count) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('$count', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.textMutedColor)),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: 100 * ratio,
          decoration: BoxDecoration(
            color: ratio > 0.8
                ? AppTheme.errorColor.withOpacity(0.6)
                : ratio > 0.5
                    ? AppTheme.infoColor.withOpacity(0.6)
                    : AppTheme.successColor.withOpacity(0.6),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Text(day, style: const TextStyle(fontSize: 10, color: AppTheme.textMutedColor)),
      ],
    );
  }
}

class _WaitTimeTrendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final points = [0.5, 0.6, 0.45, 0.7, 0.55, 0.3, 0.2];
    final paint = Paint()
      ..color = AppTheme.accentColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppTheme.accentColor.withOpacity(0.15), AppTheme.accentColor.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final segmentWidth = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final x = i * segmentWidth;
      final y = size.height - (points[i] * size.height);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, y);
      } else {
        final prevX = (i - 1) * segmentWidth;
        final prevY = size.height - (points[i - 1] * size.height);
        final cpX1 = prevX + segmentWidth / 3;
        final cpX2 = x - segmentWidth / 3;
        path.cubicTo(cpX1, prevY, cpX2, y, x, y);
        fillPath.cubicTo(cpX1, prevY, cpX2, y, x, y);
      }

      // Draw dot
      canvas.drawCircle(Offset(x, y), 3.5, Paint()..color = AppTheme.accentColor);
      canvas.drawCircle(Offset(x, y), 2, Paint()..color = Colors.white);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
