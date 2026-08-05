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
  bool _isFetchingSlots = true;
  bool _notOnboarded = false;
  String _error = '';

  List<Map<String, dynamic>> _timeSlots = [];

  @override
  void initState() {
    super.initState();
    _fetchProviderDetails();
  }

  Future<void> _fetchTimeSlots() async {
    if (_selectedServiceId == null) return;
    
    setState(() {
      _isFetchingSlots = true;
      _timeSlots.clear();
      _selectedSlotIndex = -1;
      _aiRecommendedSlotIndex = -1;
    });

    try {
      final slotsData = await ApiService.getTimeSlots(
        widget.providerId, 
        _selectedServiceId!, 
        _selectedDate
      );
      
      if (mounted) {
        setState(() {
          _timeSlots.clear();
          for (var slot in slotsData) {
            _timeSlots.add({
              'time': slot['time'],
              'available': slot['available'],
              'crowd': slot['crowdLevel'],
              'wait': slot['waitTime']
            });
          }

          final availableIndices = <int>[];
          for (int i = 0; i < _timeSlots.length; i++) {
            if (_timeSlots[i]['available'] == true) {
              availableIndices.add(i);
            }
          }
          if (availableIndices.isNotEmpty) {
            // ML-Driven Recommendation: Pick the slot with the lowest crowd/wait time!
            availableIndices.sort((a, b) {
              double crowdA = _timeSlots[a]['crowd'] as double;
              double crowdB = _timeSlots[b]['crowd'] as double;
              return crowdA.compareTo(crowdB);
            });
            _aiRecommendedSlotIndex = availableIndices.first;
          }
          _isFetchingSlots = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFetchingSlots = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load time slots: $e')),
        );
      }
    }
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
          
          if (activeServiceNames.isNotEmpty) {
            _provider!.services.retainWhere((s) => activeServiceNames.contains(s.name.toLowerCase()));
          }
          
          if (_provider!.services.isNotEmpty) {
            _selectedServiceId = _provider!.services.first.id;
          }
          
          _fetchTimeSlots();

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

      final timeStr = _timeSlots[_selectedSlotIndex]['time'] as String;
      int hour = int.parse(timeStr.split(':')[0]);
      int minute = int.parse(timeStr.split(':')[1].substring(0, 2));
      bool isPM = timeStr.contains('PM');
      if (isPM && hour != 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;
      
      final appointmentDate = DateTime(
        _selectedDate.year, 
        _selectedDate.month, 
        _selectedDate.day, 
        hour, 
        minute
      );

      final tokenData = await ApiService.bookAppointment(
        widget.providerId, 
        _selectedServiceId!, 
        null, // AI randomized dummy slot or unassigned slot
        appointmentDate
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
                Text(
                  'Not Available on IntelliQ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.getTextColor(context)),
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

    Color categoryColor = AppTheme.primaryColor;
    IconData categoryIcon = Icons.place;

    switch (_provider!.category) {
      case ServiceCategory.hospital:
        categoryColor = AppTheme.hospitalColor;
        categoryIcon = Icons.local_hospital;
        break;
      case ServiceCategory.bank:
        categoryColor = AppTheme.bankColor;
        categoryIcon = Icons.account_balance;
        break;
      case ServiceCategory.restaurant:
        categoryColor = AppTheme.restaurantColor;
        categoryIcon = Icons.restaurant;
        break;
      case ServiceCategory.college:
        categoryColor = AppTheme.collegeColor;
        categoryIcon = Icons.school;
        break;
      case ServiceCategory.governmentOffice:
        categoryColor = AppTheme.govtColor;
        categoryIcon = Icons.account_balance_outlined;
        break;
      case ServiceCategory.hotel:
        categoryColor = Colors.indigo;
        categoryIcon = Icons.hotel;
        break;
      default:
        categoryColor = AppTheme.otherColor;
        categoryIcon = Icons.business;
        break;
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
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.getBorderColor(context)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(categoryIcon, color: categoryColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _provider!.name,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.getTextColor(context)),
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
            Text(
              'Select Service',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.getTextColor(context)),
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
                      color: selected ? AppTheme.primaryColor : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? AppTheme.primaryColor : AppTheme.getBorderColor(context),
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
                            color: selected ? Colors.white : AppTheme.getTextColor(context),
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
            Text(
              'Select Date',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.getTextColor(context)),
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
                    onTap: () => setState(() {
                      _selectedDate = date;
                      _selectedSlotIndex = -1;
                      _fetchTimeSlots();
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 58,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryColor : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryColor : AppTheme.getBorderColor(context),
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
                              color: isSelected ? Colors.white : AppTheme.getTextColor(context),
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
            if (!_isFetchingSlots && _aiRecommendedSlotIndex != -1)
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
                Text(
                  'Select Time Slot',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.getTextColor(context)),
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
            if (_isFetchingSlots)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else
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
                              ? dotColor
                              : dotColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: !isAvailable
                            ? AppTheme.getBorderColor(context)
                            : isSelected
                                ? dotColor
                                : dotColor.withOpacity(0.3),
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
                                    : AppTheme.getTextColor(context),
                          ),
                        ),
                        if (!isAvailable) ...[
                          const SizedBox(height: 3),
                          Text(
                            'Full',
                            style: TextStyle(fontSize: 10, color: AppTheme.textLightColor),
                          ),
                        ]
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
