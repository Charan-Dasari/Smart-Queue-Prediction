import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../models/models.dart';
import '../../services/auth_provider.dart';
import 'package:provider/provider.dart';

class ServiceManagementScreen extends StatefulWidget {
  const ServiceManagementScreen({super.key});

  @override
  State<ServiceManagementScreen> createState() => _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  final List<Map<String, dynamic>> _services = [];
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      final providerId = user?.providerId ?? 'h1';

      // Populate initial service templates based on admin provider category
      if (providerId == 'b1') {
        _services.addAll([
          {'name': 'Cash Deposit', 'desc': 'Deposit physical currency', 'duration': '8 min', 'cost': '₹0', 'active': true},
          {'name': 'Account Opening', 'desc': 'Open savings/current accounts', 'duration': '20 min', 'cost': '₹100', 'active': true},
          {'name': 'Loan Query', 'desc': 'Consultation on housing/personal loans', 'duration': '30 min', 'cost': '₹0', 'active': true},
          {'name': 'Card Issue', 'desc': 'Collect or replace debit/credit cards', 'duration': '10 min', 'cost': '₹150', 'active': false},
        ]);
      } else if (providerId == 'g1') {
        _services.addAll([
          {'name': 'Document Verification', 'desc': 'Verify government records & identity', 'duration': '15 min', 'cost': '₹50', 'active': true},
          {'name': 'License Renewal', 'desc': 'Driving or professional license renewal', 'duration': '25 min', 'cost': '₹250', 'active': true},
          {'name': 'Govt Grant Inquiry', 'desc': 'Apply for or query welfare schemes', 'duration': '20 min', 'cost': '₹0', 'active': true},
          {'name': 'Certificate Issue', 'desc': 'Birth/Marriage/Income certificates', 'duration': '12 min', 'cost': '₹30', 'active': false},
        ]);
      } else {
        // Default Hospital
        _services.addAll([
          {'name': 'General Consultation', 'desc': 'Basic medical checkup & advice', 'duration': '15 min', 'cost': '₹200', 'active': true},
          {'name': 'Specialist Checkup', 'desc': 'Specialized medical examination', 'duration': '30 min', 'cost': '₹500', 'active': true},
          {'name': 'Lab Test', 'desc': 'Blood work & diagnostic tests', 'duration': '20 min', 'cost': '₹350', 'active': true},
          {'name': 'Follow-up Visit', 'desc': 'Post-treatment follow-up', 'duration': '10 min', 'cost': '₹100', 'active': true},
          {'name': 'Dental Checkup', 'desc': 'Dental examination & cleaning', 'duration': '25 min', 'cost': '₹400', 'active': false},
        ]);
      }
      _isInitialized = true;
    }
  }

  void _showAddServiceDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final durationController = TextEditingController();
    final costController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add New Service', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(hintText: 'Service Name', prefixIcon: Icon(Icons.label_outline, size: 20))),
              const SizedBox(height: 12),
              TextField(controller: descController, decoration: const InputDecoration(hintText: 'Description', prefixIcon: Icon(Icons.description_outlined, size: 20)), maxLines: 2),
              const SizedBox(height: 12),
              TextField(controller: durationController, decoration: const InputDecoration(hintText: 'Duration (e.g. 15 min)', prefixIcon: Icon(Icons.access_time, size: 20)), keyboardType: TextInputType.text),
              const SizedBox(height: 12),
              TextField(controller: costController, decoration: const InputDecoration(hintText: 'Cost (e.g. ₹200)', prefixIcon: Icon(Icons.currency_rupee, size: 20)), keyboardType: TextInputType.text),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final desc = descController.text.trim();
              final duration = durationController.text.trim();
              final cost = costController.text.trim();

              if (name.isEmpty || desc.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter service name and description'), behavior: SnackBarBehavior.floating),
                );
                return;
              }

              setState(() {
                _services.add({
                  'name': name,
                  'desc': desc,
                  'duration': duration.isNotEmpty ? duration : '15 min',
                  'cost': cost.isNotEmpty ? cost : '₹0',
                  'active': true,
                });
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$name service added successfully!'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user ?? AppUser(id: '1', name: 'Guest', email: 'guest@intelliq.com', mobile: '0000000000', password: '', role: UserRole.user, providerId: '');
    final Color categoryColor = user.providerId == 'b1'
        ? AppTheme.bankColor
        : user.providerId == 'g1'
            ? AppTheme.govtColor
            : AppTheme.primaryColor;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Manage Services'),
      ),
      body: _services.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.miscellaneous_services_outlined, size: 48, color: AppTheme.textLightColor),
                  const SizedBox(height: 12),
                  const Text('No services configured yet.', style: TextStyle(fontSize: 15, color: AppTheme.textMutedColor)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _services.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final svc = _services[index];
                final isActive = svc['active'] as bool;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      svc['name'] as String,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isActive ? AppTheme.textDarkColor : AppTheme.textMutedColor,
                                      ),
                                    ),
                                    if (!isActive) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.textLightColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('Inactive', style: TextStyle(fontSize: 10, color: AppTheme.textMutedColor, fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  svc['desc'] as String,
                                  style: const TextStyle(fontSize: 13, color: AppTheme.textMutedColor),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isActive,
                            onChanged: (val) {
                              setState(() {
                                svc['active'] = val;
                              });
                            },
                            activeColor: AppTheme.successColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildInfoChip(Icons.access_time, svc['duration'] as String),
                          const SizedBox(width: 12),
                          _buildInfoChip(Icons.currency_rupee, svc['cost'] as String),
                          const Spacer(),
                          SizedBox(
                            height: 32,
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _services.removeAt(index);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Service deleted'), behavior: SnackBarBehavior.floating, backgroundColor: AppTheme.errorColor),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.errorColor,
                                side: const BorderSide(color: AppTheme.errorColor),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                textStyle: const TextStyle(fontSize: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Delete'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: categoryColor,
        onPressed: _showAddServiceDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Service', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textMutedColor),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textMutedColor)),
      ],
    );
  }
}
