import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../models/models.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';

class ServiceManagementScreen extends StatefulWidget {
  const ServiceManagementScreen({super.key});

  @override
  State<ServiceManagementScreen> createState() => _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  List<dynamic> _services = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      final providerId = user?.providerId ?? '';
      if (providerId.isEmpty) return;

      final data = await ApiService.getProviderServices(providerId);
      if (mounted) {
        setState(() {
          _services = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load services';
          _isLoading = false;
        });
      }
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
              TextField(controller: durationController, decoration: const InputDecoration(hintText: 'Duration in Minutes (e.g. 15)', prefixIcon: Icon(Icons.access_time, size: 20)), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: costController, decoration: const InputDecoration(hintText: 'Cost (e.g. 200)', prefixIcon: Icon(Icons.currency_rupee, size: 20)), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final desc = descController.text.trim();
              final duration = int.tryParse(durationController.text.trim()) ?? 15;
              final cost = double.tryParse(costController.text.trim()) ?? 0.0;

              if (name.isEmpty || desc.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter service name and description'), behavior: SnackBarBehavior.floating),
                );
                return;
              }

              Navigator.pop(context);
              setState(() { _isLoading = true; });

              try {
                final user = Provider.of<AuthProvider>(context, listen: false).user;
                final providerId = user?.providerId ?? '';
                await ApiService.createService(providerId, {
                  'name': name,
                  'description': desc,
                  'avgDurationMinutes': duration,
                  'cost': cost,
                  'isActive': true,
                });
                _fetchServices();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$name service added successfully!'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating),
                  );
                }
              } catch (e) {
                if (mounted) {
                  setState(() { _isLoading = false; });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add service')));
                }
              }
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : _services.isEmpty
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
                final isActive = svc['isActive'] as bool? ?? true;

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
                                      svc['name'] as String? ?? '',
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
                                  svc['description'] as String? ?? '',
                                  style: const TextStyle(fontSize: 13, color: AppTheme.textMutedColor),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isActive,
                            onChanged: (val) async {
                              try {
                                final newStatus = await ApiService.toggleService(svc['id']);
                                setState(() {
                                  svc['isActive'] = newStatus;
                                });
                              } catch (e) {
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to toggle status')));
                              }
                            },
                            activeColor: AppTheme.successColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildInfoChip(Icons.access_time, '${svc['avgDurationMinutes']} min'),
                          const SizedBox(width: 12),
                          _buildInfoChip(Icons.currency_rupee, '₹${svc['cost']}'),
                          const Spacer(),
                          SizedBox(
                            height: 32,
                            child: OutlinedButton(
                              onPressed: () async {
                                try {
                                  await ApiService.deleteService(svc['id']);
                                  setState(() {
                                    _services.removeAt(index);
                                  });
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Service deleted'), behavior: SnackBarBehavior.floating, backgroundColor: AppTheme.errorColor),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete')));
                                }
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
