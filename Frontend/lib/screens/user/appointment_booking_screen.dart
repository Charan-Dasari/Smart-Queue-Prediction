import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';

class AppointmentBookingScreen extends StatefulWidget {
  final String providerId;
  const AppointmentBookingScreen({super.key, required this.providerId});

  @override
  State<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  DateTime _selectedDate = DateTime.now();
  int _selectedSlotIndex = -1;
  int _aiRecommendedSlotIndex = -1;
  String? _selectedServiceId;
  
  ServiceProviderInfo? _provider;
  bool _isLoading = true;
  bool _notOnboarded = false;
  String _error = '';

  final List<Map<String, dynamic>> _timeSlots = [
    {'time': '09:00 AM', 'available': true, 'crowd': 0.2},
    {'time': '09:30 AM', 'available': true, 'crowd': 0.3},
    {'time': '10:00 AM', 'available': true, 'crowd': 0.6},
    {'time': '10:30 AM', 'available': false, 'crowd': 0.9},
    {'time': '11:00 AM', 'available': true, 'crowd': 0.8},
    {'time': '11:30 AM', 'available': true, 'crowd': 0.5},
    {'time': '12:00 PM', 'available': false, 'crowd': 1.0},
    {'time': '02:00 PM', 'available': true, 'crowd': 0.3},
    {'time': '02:30 PM', 'available': true, 'crowd': 0.2},
    {'time': '03:00 PM', 'available': true, 'crowd': 0.4},
    {'time': '03:30 PM', 'available': true, 'crowd': 0.6},
    {'time': '04:00 PM', 'available': true, 'crowd': 0.7},
  ];

  @override
  void initState() {
    super.initState();
    // Pick a random available slot for the mock AI recommendation
    final availableIndices = [];
    for (int i = 0; i < _timeSlots.length; i++) {
      if (_timeSlots[i]['available'] == true) {
        availableIndices.add(i);
      }
    }
    if (availableIndices.isNotEmpty) {
      availableIndices.shuffle();
      _aiRecommendedSlotIndex = availableIndices.first;
    }
    
    _fetchProviderDetails();
  }

  Future<void> _fetchProviderDetails() async {
    try {
      final data = await ApiService.getProviderById(widget.providerId);
      final countersData = await ApiService.getProviderCountersById(widget.providerId);
      
      final Set<String> activeServiceNames = countersData
          .map((c) => c['serviceName'].toString().toLowerCase())
          .toSet();

      if (mounted) {
        setState(() {
          _provider = ServiceProviderInfo.fromJson(data);
          
          // Filter out services that don't have assigned counters based on name matching
          _provider!.services.retainWhere((s) => activeServiceNames.contains(s.name.toLowerCase()));

          if (_provider!.services.isNotEmpty) {
            _selectedServiceId = _provider!.services.first.id;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e.toString().contains('ProviderNotOnboarded')) {
            _notOnboarded = true;
          } else {
            _error = 'Failed to load provider details';
          }
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleBooking() async {
    if (_selectedServiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service')),
      );
      return;
    }

    try {
      if (_selectedSlotIndex == -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a time slot')),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final tokenData = await ApiService.bookAppointment(
        widget.providerId, 
        _selectedServiceId!, 
        null, // AI randomized dummy slot or unassigned slot
        _selectedDate
      );
      
      final token = Appointment.fromJson(tokenData);

      if (!mounted) return;
      context.pop(); // dismiss loading dialog
      context.push('/confirmation/${token.id}');
    } catch (e) {
      if (!mounted) return;
      context.pop(); // dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking failed: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book Appointment')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_notOnboarded) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.pop(),
          ),
          title: const Text('Book Appointment'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store_outlined, size: 80, color: AppTheme.textMutedColor.withOpacity(0.5)),
                const SizedBox(height: 24),
                const Text(
                  'Not Available on IntelliQ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDarkColor),
                ),
                const SizedBox(height: 12),
                const Text(
                  'This business hasn\'t started using this app yet. Appointments and queues cannot be managed here at the moment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppTheme.textMutedColor, height: 1.5),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_error.isNotEmpty || _provider == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book Appointment')),
        body: Center(child: Text(_error)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Book Appointment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Provider Card ──
            Container(
              padding: const EdgeInsets.all(16),
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
                      color: AppTheme.hospitalColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.local_hospital, color: AppTheme.hospitalColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _provider!.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textDarkColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _provider!.address,
                          style: const TextStyle(fontSize: 13, color: AppTheme.textMutedColor),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 14, color: AppTheme.warningColor),
                          const SizedBox(width: 3),
                          Text(_provider!.rating.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Select Service ──
            const Text(
              'Select Service',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textDarkColor),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _provider!.services.map((service) {
                final selected = service.id == _selectedServiceId;
                return GestureDetector(
                  onTap: () => setState(() => _selectedServiceId = service.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? AppTheme.primaryColor : AppTheme.borderColor,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          service.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : AppTheme.textDarkColor,
                          ),
                        ),
                        Text(
                          'Wait: ~${service.estimatedWaitMinutes}m',
                          style: TextStyle(
                            fontSize: 11,
                            color: selected ? Colors.white70 : AppTheme.textMutedColor,
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // ── Select Date ──
            const Text(
              'Select Date',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textDarkColor),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 14,
                itemBuilder: (context, index) {
                  final date = DateTime.now().add(Duration(days: index));
                  final isSelected = date.day == _selectedDate.day &&
                      date.month == _selectedDate.month;
                  final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

                  return GestureDetector(
                    onTap: () => setState(() => _selectedDate = date),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 58,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayNames[(date.weekday - 1) % 7],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white.withOpacity(0.7) : AppTheme.textMutedColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : AppTheme.textDarkColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),

            // ── AI Recommended Slot ──
            if (_aiRecommendedSlotIndex != -1)
              GestureDetector(
                onTap: () => setState(() => _selectedSlotIndex = _aiRecommendedSlotIndex),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.aiGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.aiAccent.withOpacity(0.2),
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
                        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AI Recommended Slot',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_timeSlots[_aiRecommendedSlotIndex]['time']} — Expected wait: ~${(_timeSlots[_aiRecommendedSlotIndex]['crowd'] * 20).round()} min',
                              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                            ),
                          ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Select', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Select Time Slot ──
            Row(
              children: [
                const Text(
                  'Select Time Slot',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textDarkColor),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.push('/smart-slots/${widget.providerId}'),
                  child: Container(
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
                        Text(
                          'AI Suggest',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.2,
              ),
              itemCount: _timeSlots.length,
              itemBuilder: (context, index) {
                final slot = _timeSlots[index];
                final isAvailable = slot['available'] as bool;
                final isSelected = index == _selectedSlotIndex;
                final crowd = slot['crowd'] as double;
                Color dotColor = crowd < 0.4
                    ? AppTheme.queueLow
                    : crowd < 0.7
                        ? AppTheme.queueMedium
                        : AppTheme.queueHigh;

                return GestureDetector(
                  onTap: isAvailable ? () => setState(() => _selectedSlotIndex = index) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: !isAvailable
                          ? const Color(0xFFF1F5F9)
                          : isSelected
                              ? AppTheme.primaryColor
                              : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: !isAvailable
                            ? AppTheme.borderColor
                            : isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.borderColor,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          slot['time'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: !isAvailable
                                ? AppTheme.textLightColor
                                : isSelected
                                    ? Colors.white
                                    : AppTheme.textDarkColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (isAvailable)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white.withOpacity(0.7) : dotColor,
                              shape: BoxShape.circle,
                            ),
                          )
                        else
                          Text(
                            'Full',
                            style: TextStyle(fontSize: 10, color: AppTheme.textLightColor),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendDot(AppTheme.queueLow, 'Low'),
                const SizedBox(width: 16),
                _buildLegendDot(AppTheme.queueMedium, 'Medium'),
                const SizedBox(width: 16),
                _buildLegendDot(AppTheme.queueHigh, 'High'),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _selectedSlotIndex >= 0 ? _handleBooking : null,
              child: const Text('Confirm Booking', style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMutedColor)),
      ],
    );
  }
}
