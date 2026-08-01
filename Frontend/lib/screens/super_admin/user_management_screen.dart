import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import 'package:provider/provider.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedRole = 'All';

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    try {
      final users = await ApiService.getAllUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    _filteredUsers = _users.where((u) {
      final name = (u['name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final role = (u['role'] ?? '').toString();
      final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery.toLowerCase()) || email.contains(_searchQuery.toLowerCase());
      final matchesRole = _selectedRole == 'All' || role == _selectedRole;
      return matchesSearch && matchesRole;
    }).toList();
  }

  Future<void> _deleteUser(String userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account Permanently?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: Text('This will permanently delete $userName\'s account and all their data. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteUserAccount(userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$userName\'s account has been deleted'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating),
          );
          _fetchUsers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.errorColor, behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  Future<void> _approveDeletion(String userId, String userName) async {
    int selectedDays = 3;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Set Deletion Timer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How many days before $userName\'s account is deleted?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: selectedDays > 1 ? () => setDialogState(() => selectedDays--) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
                    ),
                    child: Text('$selectedDays days', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.warningColor)),
                  ),
                  IconButton(
                    onPressed: selectedDays < 30 ? () => setDialogState(() => selectedDays++) : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'The user will be notified and can revoke this within the timer period.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMutedColor),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningColor),
              child: const Text('Approve Deletion'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.approveDeletion(userId, selectedDays);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deletion approved. $userName will be deleted in $selectedDays day(s).'), backgroundColor: AppTheme.warningColor, behavior: SnackBarBehavior.floating),
          );
          _fetchUsers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.errorColor, behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pendingRequests = _users.where((u) => u['deletionRequest'] != null && u['deletionRequest']['status'] == 'Pending').toList();

    return UserThemeWrapper(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => context.pop()),
          title: const Text('User Management'),
          actions: [
            IconButton(icon: const Icon(Icons.refresh_rounded, size: 22), onPressed: () { setState(() => _isLoading = true); _fetchUsers(); }),
            const SizedBox(width: 8),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetchUsers,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Pending Deletion Requests ──
                      if (pendingRequests.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.warningColor.withOpacity(0.15), AppTheme.warningColor.withOpacity(0.05)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: AppTheme.warningColor, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Pending Deletion Requests (${pendingRequests.length})',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.warningColor),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...pendingRequests.map((u) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.getBorderColor(context)),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: AppTheme.warningColor.withOpacity(0.15),
                                      child: Text(
                                        (u['name'] ?? '?').toString().substring(0, 1).toUpperCase(),
                                        style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.warningColor),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(u['name'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.getTextColor(context))),
                                          Text(u['email'] ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textMutedColor)),
                                          if (u['deletionRequest']?['reason'] != null)
                                            Text('Reason: ${u['deletionRequest']['reason']}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.textMutedColor)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _approveDeletion(u['id'], u['name']),
                                      icon: const Icon(Icons.timer_rounded, size: 20),
                                      color: AppTheme.warningColor,
                                      tooltip: 'Approve with timer',
                                    ),
                                    IconButton(
                                      onPressed: () => _deleteUser(u['id'], u['name']),
                                      icon: const Icon(Icons.delete_forever_rounded, size: 20),
                                      color: AppTheme.errorColor,
                                      tooltip: 'Delete instantly',
                                    ),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Search Bar ──
                      TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                            _applyFilters();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search by name or email...',
                          hintStyle: TextStyle(color: AppTheme.getMutedTextColor(context)),
                          prefixIcon: Icon(Icons.search_rounded, color: AppTheme.getMutedTextColor(context)),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); setState(() { _searchQuery = ''; _applyFilters(); }); })
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Role Filter Chips ──
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['All', 'User', 'Admin', 'Staff'].map((role) {
                            final isSelected = _selectedRole == role;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(role),
                                selected: isSelected,
                                onSelected: (_) { setState(() { _selectedRole = role; _applyFilters(); }); },
                                selectedColor: AppTheme.primaryColor.withOpacity(0.15),
                                checkmarkColor: AppTheme.primaryColor,
                                labelStyle: TextStyle(
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppTheme.primaryColor : AppTheme.textMutedColor,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── User Count ──
                      Text(
                        '${_filteredUsers.length} user${_filteredUsers.length == 1 ? '' : 's'}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.getMutedTextColor(context)),
                      ),
                      const SizedBox(height: 10),

                      // ── User List ──
                      ..._filteredUsers.map((u) {
                        final deletionReq = u['deletionRequest'];
                        final hasRequest = deletionReq != null;
                        final isApproved = hasRequest && deletionReq['status'] == 'Approved';
                        final isPending = hasRequest && deletionReq['status'] == 'Pending';
                        final role = u['role'] ?? 'User';
                        final initial = (u['name'] ?? '?').toString().isNotEmpty ? (u['name']).toString().substring(0, 1).toUpperCase() : '?';

                        Color roleColor;
                        switch (role) {
                          case 'Admin': roleColor = AppTheme.hospitalColor; break;
                          case 'Staff': roleColor = AppTheme.bankColor; break;
                          default: roleColor = AppTheme.primaryColor;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isApproved ? AppTheme.errorColor.withOpacity(0.3) : AppTheme.getBorderColor(context)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: roleColor.withOpacity(0.12),
                                  child: Text(initial, style: TextStyle(fontWeight: FontWeight.w700, color: roleColor, fontSize: 16)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(child: Text(u['name'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.getTextColor(context)), overflow: TextOverflow.ellipsis)),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: roleColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                            child: Text(role, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: roleColor)),
                                          ),
                                          if (isPending) ...[
                                            const SizedBox(width: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: AppTheme.warningColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                              child: const Text('Deletion Requested', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.warningColor)),
                                            ),
                                          ],
                                          if (isApproved) ...[
                                            const SizedBox(width: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: AppTheme.errorColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                              child: const Text('Deletion Approved', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.errorColor)),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(u['email'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textMutedColor)),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert_rounded, size: 20, color: AppTheme.getMutedTextColor(context)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  onSelected: (action) {
                                    if (action == 'delete') _deleteUser(u['id'], u['name']);
                                    if (action == 'approve') _approveDeletion(u['id'], u['name']);
                                  },
                                  itemBuilder: (ctx) => [
                                    if (isPending)
                                      const PopupMenuItem(value: 'approve', child: Row(children: [Icon(Icons.timer_rounded, size: 18, color: AppTheme.warningColor), SizedBox(width: 8), Text('Approve with Timer')])),
                                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_forever_rounded, size: 18, color: AppTheme.errorColor), SizedBox(width: 8), Text('Delete Instantly', style: TextStyle(color: AppTheme.errorColor))])),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
