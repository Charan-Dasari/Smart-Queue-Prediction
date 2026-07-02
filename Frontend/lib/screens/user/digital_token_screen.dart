import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import 'dart:math';

class DigitalTokenScreen extends StatelessWidget {
  final String tokenId;
  const DigitalTokenScreen({super.key, required this.tokenId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Digital Token'),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Token shared successfully!'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            icon: const Icon(Icons.share_outlined, size: 20),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // ── Token Circle ──
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'TOKEN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.6),
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'H-204',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── QR Code Placeholder ──
              Container(
                width: 160,
                height: 160,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _QRPlaceholderPainter(),
                  size: const Size(136, 136),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Scan at counter for check-in',
                style: TextStyle(fontSize: 12, color: AppTheme.textMutedColor),
              ),
              const SizedBox(height: 20),

              // ── Share Token Button ──
              SizedBox(
                width: 180,
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Token shared successfully!'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  },
                  icon: const Icon(Icons.share_outlined, size: 16),
                  label: const Text('Share Token', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Info Cards ──
              Row(
                children: [
                  Expanded(child: _buildInfoCard('Queue Position', '3', Icons.people_outline, AppTheme.infoColor)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildInfoCard('Est. Wait', '~10 min', Icons.access_time, AppTheme.warningColor)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildInfoCard('Now Serving', 'H-201', Icons.play_circle_outline, AppTheme.successColor)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildInfoCard('Counter', '#2', Icons.countertops_outlined, AppTheme.accentColor)),
                ],
              ),
              const SizedBox(height: 28),

              // ── Provider & Service ──
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
                    _buildDetailRow('Provider', 'Metro City Hospital'),
                    const Divider(color: AppTheme.dividerColor, height: 20),
                    _buildDetailRow('Service', 'General Consultation'),
                    const Divider(color: AppTheme.dividerColor, height: 20),
                    _buildDetailRow('Booked At', '10:15 AM'),
                    const Divider(color: AppTheme.dividerColor, height: 20),
                    _buildDetailRow('Scheduled', '02:00 PM'),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Track Queue Button ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/tracking/$tokenId'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.track_changes, size: 20),
                  label: const Text('Track Queue Live', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMutedColor),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textMutedColor)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDarkColor)),
      ],
    );
  }
}

/// Custom painter that generates a QR-code-like placeholder grid
class _QRPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42); // Fixed seed for consistent pattern
    final cellSize = size.width / 11;
    final paint = Paint()..color = AppTheme.textDarkColor;

    // Draw corner markers
    _drawCornerMarker(canvas, 0, 0, cellSize, paint);
    _drawCornerMarker(canvas, size.width - cellSize * 3, 0, cellSize, paint);
    _drawCornerMarker(canvas, 0, size.height - cellSize * 3, cellSize, paint);

    // Fill random cells
    for (int row = 0; row < 11; row++) {
      for (int col = 0; col < 11; col++) {
        // Skip corner marker areas
        if ((row < 3 && col < 3) || (row < 3 && col > 7) || (row > 7 && col < 3)) continue;

        if (random.nextBool()) {
          canvas.drawRect(
            Rect.fromLTWH(col * cellSize, row * cellSize, cellSize - 1, cellSize - 1),
            paint,
          );
        }
      }
    }
  }

  void _drawCornerMarker(Canvas canvas, double x, double y, double cellSize, Paint paint) {
    // Outer box
    canvas.drawRect(Rect.fromLTWH(x, y, cellSize * 3, cellSize * 3), paint);
    // Inner white
    canvas.drawRect(
      Rect.fromLTWH(x + cellSize * 0.5, y + cellSize * 0.5, cellSize * 2, cellSize * 2),
      Paint()..color = Colors.white,
    );
    // Center dot
    canvas.drawRect(
      Rect.fromLTWH(x + cellSize, y + cellSize, cellSize, cellSize),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
