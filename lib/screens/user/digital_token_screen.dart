import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';

class DigitalTokenScreen extends StatefulWidget {
  final String tokenId;
  const DigitalTokenScreen({super.key, required this.tokenId});

  @override
  State<DigitalTokenScreen> createState() => _DigitalTokenScreenState();
}

class _DigitalTokenScreenState extends State<DigitalTokenScreen> {
  bool _isLoading = true;
  Appointment? _appointment;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchToken();
  }

  Future<void> _fetchToken() async {
    try {
      final data = await ApiService.getAppointmentById(widget.tokenId);
      if (mounted) {
        setState(() {
          _appointment = Appointment.fromJson(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppTheme.errorColor)))
              : _appointment == null
                  ? const Center(child: Text('Token not found'))
                  : Center(
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
                                  Text(
                                    _appointment!.tokenNumber,
                                    style: const TextStyle(
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

                            // ── QR Code ──
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
                              child: Builder(
                                builder: (context) {
                                  final user = Provider.of<AuthProvider>(context, listen: false).user;
                                  final qrData = '''
Name: ${user?.name ?? 'User'}
Email: ${user?.email ?? 'N/A'}
Booked Date: ${DateFormat('MMM dd, yyyy').format(_appointment!.date)}
Time Slot: ${_appointment!.timeSlot != null ? '${_appointment!.timeSlot!.startTime} - ${_appointment!.timeSlot!.endTime}' : 'N/A'}
Service Type: ${_appointment!.serviceName}
Provider: ${_appointment!.providerName}
Status: ${_appointment!.status.name.toUpperCase()}
Token ID: ${_appointment!.id}
'''.trim();
                                  
                                  return QrImageView(
                                    data: qrData,
                                    version: QrVersions.auto,
                                    size: 136,
                                    foregroundColor: AppTheme.textDarkColor,
                                  );
                                },
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
                                  _buildDetailRow('Provider', _appointment!.providerName),
                                  const Divider(color: AppTheme.dividerColor, height: 20),
                                  _buildDetailRow('Service', _appointment!.serviceName),
                                  const Divider(color: AppTheme.dividerColor, height: 20),
                                  _buildDetailRow('Booked At', DateFormat.yMMMd().format(_appointment!.date)),
                                  const Divider(color: AppTheme.dividerColor, height: 20),
                                  _buildDetailRow('Status', _appointment!.status.name.toUpperCase()),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            // ── Track Queue Button ──
                            if (_appointment!.status == AppointmentStatus.inQueue || _appointment!.status == AppointmentStatus.serving)
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton.icon(
                                  onPressed: () => context.push('/tracking/${_appointment!.id}'),
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
