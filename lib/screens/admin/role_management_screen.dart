import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  List<AppUser> _users = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final data = await ApiService.getProviderUsers();
      if (mounted) {
        setState(() {
          _users = data.map((json) => AppUser.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load users: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateRole(AppUser user, UserRole newRole) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      await ApiService.updateUserRole(user.id, newRole.index);
      if (mounted) {
        context.pop();
        setState(() {
          user.role = newRole;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Role updated successfully'), backgroundColor: AppTheme.successColor),
        );
      }
    } catch (e) {
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update role: $e'), backgroundColor: AppTheme.errorColor),
        );
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
        title: const Text('Role Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() { _isLoading = true; _error = ''; });
              _fetchUsers();
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                            child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U', style: const TextStyle(color: AppTheme.primaryColor)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textDarkColor)),
                                Text(user.email, style: const TextStyle(fontSize: 12, color: AppTheme.textMutedColor)),
                              ],
                            ),
                          ),
                          DropdownButton<UserRole>(
                            value: user.role,
                            items: const [
                              DropdownMenuItem(value: UserRole.user, child: Text('User', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: UserRole.staff, child: Text('Staff', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: UserRole.admin, child: Text('Admin', style: TextStyle(fontSize: 13))),
                            ],
                            onChanged: (role) {
                              if (role != null && role != user.role) {
                                _updateRole(user, role);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
