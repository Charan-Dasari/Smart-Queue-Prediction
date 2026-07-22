import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../services/auth_provider.dart';
import 'package:provider/provider.dart';

class StaffCounterScreen extends StatefulWidget {
  const StaffCounterScreen({super.key});

  @override
  State<StaffCounterScreen> createState() => _StaffCounterScreenState();
}

class _StaffCounterScreenState extends State<StaffCounterScreen> {
  List<ServiceCounter> _counters = [];
  List<dynamic> _staffList = [];
  List<dynamic> _services = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final providerId = auth.user?.providerId ?? '';
      
      final countersData = await ApiService.getProviderCounters();
      final staffData = await ApiService.getProviderStaff();
      final servicesData = providerId.isNotEmpty ? await ApiService.getProviderServices(providerId) : [];
      
      if (mounted) {
        setState(() {
          _counters = countersData.map((json) => ServiceCounter.fromJson(json)).toList();
          _staffList = staffData;
          _services = servicesData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load data: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteCounter(String id) async {
    try {
      await ApiService.deleteCounter(id);
      _fetchData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Counter deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _deleteStaff(String id) async {
    try {
      await ApiService.deleteStaff(id);
      _fetchData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final int activeCount = _counters.where((c) => c.status == CounterStatus.active).length;
    final int breakCount = _counters.where((c) => c.status == CounterStatus.onBreak).length;
    final int offlineCount = _counters.where((c) => c.status == CounterStatus.offline).length;

    final user = Provider.of<AuthProvider>(context).user;
    final categoryStr = (user?.role.name ?? 'hospital').toLowerCase();
    
    final Color categoryColor = categoryStr == 'bank'
        ? AppTheme.bankColor
        : categoryStr == 'govtoffice'
            ? AppTheme.govtColor
            : AppTheme.primaryColor;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Staff & Counters'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() { _isLoading = true; _error = ''; });
              _fetchData();
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStaffDialog,
        backgroundColor: categoryColor,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Staff'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Summary ──
                      Row(
                        children: [
                          Expanded(child: _buildMiniStat('Active', '$activeCount', AppTheme.successColor)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildMiniStat('On Break', '$breakCount', AppTheme.warningColor)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildMiniStat('Offline', '$offlineCount', AppTheme.textLightColor)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Counters Management',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDarkColor),
                          ),
                          TextButton.icon(
                            onPressed: _showAddCounterDialog,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Counter'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      
                      if (_counters.isEmpty)
                        const Center(child: Text('No counters found.', style: TextStyle(color: AppTheme.textMutedColor))),

                      ..._counters.asMap().entries.map((entry) {
                        final index = entry.key;
                        final c = entry.value;
                        final status = c.status;
                        
                        Color statusColor;
                        String statusLabel;
                        IconData statusIcon;

                        switch (status) {
                          case CounterStatus.active:
                            statusColor = AppTheme.successColor;
                            statusLabel = 'Active';
                            statusIcon = Icons.circle;
                            break;
                          case CounterStatus.onBreak:
                            statusColor = AppTheme.warningColor;
                            statusLabel = 'On Break';
                            statusIcon = Icons.pause_circle;
                            break;
                          case CounterStatus.offline:
                          default:
                            statusColor = AppTheme.textLightColor;
                            statusLabel = 'Offline';
                            statusIcon = Icons.circle_outlined;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
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
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '#${c.number}',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: statusColor),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.staffName,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textDarkColor),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Service: ${c.serviceName}',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textMutedColor, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 4),
                                    if (c.activeTokenNumber != null)
                                      Text(
                                        'Serving: ${c.activeTokenNumber}',
                                        style: const TextStyle(fontSize: 13, color: AppTheme.textMutedColor),
                                      )
                                    else
                                      Text(
                                        status == CounterStatus.onBreak ? 'Currently on break' : status == CounterStatus.offline ? 'No staff assigned' : 'Ready to serve',
                                        style: const TextStyle(fontSize: 13, color: AppTheme.textMutedColor),
                                      ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          'Served: ${c.todayCustomers}',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textMutedColor),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Avg: ${c.avgServiceMinutes}m',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textMutedColor),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(statusIcon, size: 10, color: statusColor),
                                            const SizedBox(width: 4),
                                            Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () => _deleteCounter(c.id),
                                        child: const Icon(Icons.delete_outline, size: 18, color: AppTheme.errorColor),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () => _showAssignStaffDialog(c.id),
                                    child: const Text('Assign Staff', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                      
                      const SizedBox(height: 32),
                      const Text(
                        'Staff Members',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDarkColor),
                      ),
                      const SizedBox(height: 14),
                      
                      if (_staffList.isEmpty)
                        const Center(child: Text('No staff members found.', style: TextStyle(color: AppTheme.textMutedColor))),

                      ..._staffList.map((staff) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                child: Text(
                                  staff['name'] != null && staff['name'].isNotEmpty ? staff['name'][0].toUpperCase() : 'S',
                                  style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      staff['name'] ?? '',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textDarkColor),
                                    ),
                                    const SizedBox(height: 4),
                                    SelectableText(
                                      'Email: ${staff['email'] ?? ''}',
                                      style: const TextStyle(fontSize: 13, color: AppTheme.textMutedColor),
                                    ),
                                    const SizedBox(height: 2),
                                    SelectableText(
                                      'Password: ${(staff['name'] ?? '').toString().split(' ').first.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '')}@123',
                                      style: const TextStyle(fontSize: 13, color: AppTheme.textMutedColor),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, color: AppTheme.primaryColor),
                                tooltip: 'Copy Credentials',
                                onPressed: () {
                                  final pwd = '${(staff['name'] ?? '').toString().split(' ').first.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '')}@123';
                                  Clipboard.setData(ClipboardData(text: 'Email: ${staff['email'] ?? ''}\nPassword: $pwd'));
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Credentials copied to clipboard')));
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                                onPressed: () => _deleteStaff(staff['id']),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
    );
  }

  void _showAddStaffDialog() {
    final firstController = TextEditingController();
    final lastController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Staff'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstController,
              decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lastController,
              decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final result = await ApiService.createStaff(firstController.text, lastController.text);
                if (mounted) {
                  _fetchData();
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Staff Created'),
                      content: Text('Name: ${result['name']}\nEmail: ${result['email']}\nPassword: ${result['password']}\n\nPlease share these credentials with the staff member.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
                      ],
                    )
                  );
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddCounterDialog() {
    final numberController = TextEditingController();
    String? selectedService;
    if (_services.isNotEmpty) {
      selectedService = _services.first['name'];
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Counter'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: numberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Counter Number', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                if (_services.isNotEmpty)
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Service Name', border: OutlineInputBorder()),
                    value: selectedService,
                    items: _services.map((s) {
                      final serviceName = s['name'].toString();
                      return DropdownMenuItem(
                        value: serviceName,
                        child: Text(serviceName),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedService = val;
                      });
                    },
                  )
                else
                  const Text('No services configured. Please add services first.', style: TextStyle(color: AppTheme.errorColor)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: _services.isEmpty ? null : () async {
                  Navigator.pop(ctx);
                  try {
                    final number = int.tryParse(numberController.text) ?? 1;
                    await ApiService.createCounter(number, selectedService ?? '');
                    _fetchData();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Counter created')));
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<void> _showAssignStaffDialog(String counterId) async {
    try {
      final staffList = await ApiService.getProviderStaff();
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Assign Staff'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: staffList.length + 1,
                itemBuilder: (context, i) {
                  if (i == staffList.length) {
                    return ListTile(
                      title: const Text('Unassign Staff', style: TextStyle(color: Colors.red)),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await ApiService.assignCounter(counterId, null);
                        _fetchData();
                      },
                    );
                  }
                  final staff = staffList[i];
                  return ListTile(
                    title: Text(staff['name']),
                    subtitle: Text(staff['email']),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await ApiService.assignCounter(counterId, staff['id']);
                      _fetchData();
                    },
                  );
                },
              ),
            ),
          )
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load staff: $e')));
    }
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMutedColor)),
        ],
      ),
    );
  }
}
