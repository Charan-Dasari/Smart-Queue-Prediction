import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final String appointmentId;
  const BookingConfirmationScreen({super.key, required this.appointmentId});

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  QueueToken? _token;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5)),
    );
    _controller.forward();
    
    _fetchTokenDetails();
  }
  
  Future<void> _fetchTokenDetails() async {
    try {
      final data = await ApiService.getQueueTracking(widget.appointmentId);
      if (mounted) {
        setState(() {
          _token = QueueToken.fromJson(data['queueToken']);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load booking details: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error.isNotEmpty || _token == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Confirmation')),
        body: Center(child: Text(_error.isNotEmpty ? _error : 'Token not found')),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              // ── Success Animation ──
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _opacityAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppTheme.successGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.successColor.withOpacity(0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Booking Confirmed!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDarkColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your queue position has been successfully booked',
                style: TextStyle(fontSize: 14, color: AppTheme.textMutedColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              // ── Appointment Details Card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Provider', _token!.providerName),
                    const Divider(color: AppTheme.dividerColor, height: 24),
                    _buildDetailRow('Service', _token!.serviceName),
                    const Divider(color: AppTheme.dividerColor, height: 24),
                    _buildDetailRow('Status', _token!.status.name.toUpperCase(), valueColor: AppTheme.successColor),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Token Number ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'YOUR TOKEN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.6),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _token!.tokenNumber,
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── QR Code (Placeholder Pattern) ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  children: [
                    const Text(
                      'QR Code',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDarkColor),
                    ),
                    const SizedBox(height: 16),
                    // QR-like pattern placeholder
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderColor, width: 2),
                      ),
                      child: CustomPaint(
                        painter: _QRPlaceholderPainter(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Scan at the counter for quick check-in',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMutedColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Action Buttons ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/token/${_token!.id}'),
                  icon: const Icon(Icons.confirmation_number_outlined, size: 20),
                  label: const Text('View Digital Token', style: TextStyle(fontSize: 15)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Back to Home'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textMutedColor)),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppTheme.textDarkColor,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _QRPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppTheme.primaryColor;
    final cellSize = size.width / 12;
    // Create a QR-like pattern
    final pattern = [
      [1,1,1,1,1,1,0,1,0,1,1,1],
      [1,0,0,0,0,1,0,0,1,0,0,1],
      [1,0,1,1,0,1,0,1,0,1,0,1],
      [1,0,1,1,0,1,0,0,1,1,0,1],
      [1,0,0,0,0,1,0,1,0,0,0,1],
      [1,1,1,1,1,1,0,1,0,1,0,1],
      [0,0,0,0,0,0,0,0,1,0,1,0],
      [1,0,1,0,1,0,0,1,0,1,0,1],
      [0,1,0,1,0,1,0,0,1,0,1,0],
      [1,0,1,1,0,0,0,1,0,1,1,1],
      [1,1,0,0,1,1,0,0,1,0,0,0],
      [1,1,1,1,1,1,0,1,0,1,0,1],
    ];

    for (int row = 0; row < pattern.length; row++) {
      for (int col = 0; col < pattern[row].length; col++) {
        if (pattern[row][col] == 1) {
          canvas.drawRect(
            Rect.fromLTWH(col * cellSize + 8, row * cellSize + 8, cellSize - 1, cellSize - 1),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
