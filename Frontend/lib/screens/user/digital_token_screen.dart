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
    final theme = Theme.of(context);

    return UserThemeWrapper(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => context.pop(),
          ),
          title: const Text('Digital Queue Pass'),
          actions: [
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pass details copied to clipboard!'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
              icon: const Icon(Icons.share_rounded, size: 20),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: AppTheme.errorColor)))
                : _appointment == null
                    ? const Center(child: Text('Token not found'))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Column(
                          children: [
                            // ── Pass Ticket Container ──
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: theme.dividerColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // ── Top Pass Header ──
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                                    decoration: const BoxDecoration(
                                      gradient: AppTheme.primaryGradient,
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(27)),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Text(
                                            'OFFICIAL DIGITAL PASS',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          _appointment!.tokenNumber,
                                          style: const TextStyle(
                                            fontSize: 48,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _appointment!.providerName,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white.withOpacity(0.9),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // ── QR Code Card ──
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppTheme.getBorderColor(context)),
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
                                          size: 160,
                                          foregroundColor: AppTheme.getTextColor(context),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Present QR code at check-in scanner',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodyMedium?.color),
                                  ),
                                  const SizedBox(height: 24),

                                  // ── Dashed Perforation Line ──
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Row(
                                      children: List.generate(
                                        30,
                                        (i) => Expanded(
                                          child: Container(
                                            height: 1,
                                            color: i % 2 == 0 ? theme.dividerColor : Colors.transparent,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // ── Pass Details Grid ──
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    child: Column(
                                      children: [
                                        _buildDetailRow(context, 'Service Requested', _appointment!.serviceName),
                                        const SizedBox(height: 14),
                                        _buildDetailRow(context, 'Scheduled Date', DateFormat.yMMMd().format(_appointment!.date)),
                                        const SizedBox(height: 14),
                                        _buildDetailRow(context, 'Token Status', _appointment!.status.name.toUpperCase()),
                                        const SizedBox(height: 24),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ── Action Buttons ──
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Pass saved to wallet!'),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: AppTheme.successColor,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.download_rounded, size: 18),
                                    label: const Text('Save Pass'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if (_appointment!.status == AppointmentStatus.inQueue || _appointment!.status == AppointmentStatus.serving)
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => context.push('/tracking/${_appointment!.id}'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      icon: const Icon(Icons.my_location_rounded, size: 18),
                                      label: const Text('Live Tracking', style: TextStyle(fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: theme.textTheme.bodyMedium?.color)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }
}

