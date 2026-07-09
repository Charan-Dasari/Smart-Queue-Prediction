import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../models/models.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _darkMode = false;
  bool _pushNotifications = true;

  int _totalVisits = 0;
  int _upcomingCount = 0;
  int _cancelledCount = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _darkMode = AppTheme.themeNotifier.value == ThemeMode.dark;
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final dashData = await ApiService.getUserDashboard();
      final appointmentsData = await ApiService.getMyAppointments();

      final stats = DashboardStats.fromJson(dashData);
      final appointments = appointmentsData
          .map((a) => Appointment.fromJson(a as Map<String, dynamic>))
          .toList();

      final cancelled = appointments.where((a) => a.status == AppointmentStatus.cancelled).length;
      final upcoming = appointments.where((a) => a.status == AppointmentStatus.upcoming).length;

      if (mounted) {
        setState(() {
          _totalVisits = stats.completedVisits;
          _upcomingCount = upcoming;
          _cancelledCount = cancelled;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user ?? AppUser(id: '1', name: 'Guest', email: 'guest@intelliq.com', mobile: '0000000000', password: '', role: UserRole.user, providerId: '');
    String initials = user.name.isNotEmpty
        ? user.name.split(' ').map((e) => e.isNotEmpty ? e.substring(0, 1) : '').join().toUpperCase()
        : '?';
    if (initials.length > 2) initials = initials.substring(0, 2);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Profile'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ── Avatar & Name ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(fontSize: 14, color: AppTheme.textMutedColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.mobile,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textMutedColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Stats Row ──
              _isLoadingStats
                  ? const SizedBox(
                      height: 80,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : Row(
                      children: [
                        Expanded(child: _buildStatCard('$_totalVisits', 'Total Visits', AppTheme.infoColor)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('$_upcomingCount', 'Upcoming', AppTheme.warningColor)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('$_cancelledCount', 'Cancelled', AppTheme.errorColor)),
                      ],
                    ),
              const SizedBox(height: 20),

              // ── Account Settings ──
              _buildSectionLabel('Account'),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(Icons.person_outline, 'Edit Profile', 'Update your personal details', () {
                      _showEditProfileDialog(context, user);
                    }),
                    const Divider(color: AppTheme.dividerColor, height: 0),
                    _buildMenuItem(Icons.lock_outline, 'Change Password', 'Update your account password', () {
                      _showChangePasswordDialog(context);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Preferences ──
              _buildSectionLabel('Preferences'),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  children: [
                    _buildToggleMenuItem(Icons.notifications_outlined, 'Push Notifications', 'Get alerts for queue & bookings', _pushNotifications, (val) {
                      setState(() => _pushNotifications = val);
                    }),
                    const Divider(color: AppTheme.dividerColor, height: 0),
                    _buildToggleMenuItem(Icons.dark_mode_outlined, 'Dark Mode', 'Switch to dark theme', _darkMode, (val) {
                      setState(() => _darkMode = val);
                      AppTheme.themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val ? 'Dark mode enabled' : 'Light mode enabled'),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }),
                    const Divider(color: AppTheme.dividerColor, height: 0),
                    _buildMenuItem(Icons.language, 'Language', 'English', () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Language selection coming soon'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }, trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('English', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Support ──
              _buildSectionLabel('Support'),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(Icons.help_outline, 'Help & Support', 'FAQs and contact support', () {
                      context.push('/help-support');
                    }),
                    const Divider(color: AppTheme.dividerColor, height: 0),
                    _buildMenuItem(Icons.info_outline, 'About IntelliQ', 'Version 0.2.5', () {
                      context.push('/about');
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Logout Button ──
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    await auth.logout();
                    if (context.mounted) context.go('/login');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    side: const BorderSide(color: AppTheme.errorColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text('Logout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.push('/history');
              break;
            case 2:
              context.push('/notifications');
              break;
            case 3:
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), activeIcon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textMutedColor, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMutedColor)),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, VoidCallback onTap, {Widget? trailing}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).brightness == Brightness.dark ? AppTheme.accentColor : AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textMutedColor)),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textLightColor),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleMenuItem(IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.accentColor : AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textMutedColor)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.accentColor : AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Current Password', prefixIcon: Icon(Icons.lock_outline, size: 20)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'New Password', prefixIcon: Icon(Icons.lock_outline, size: 20)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Confirm New Password', prefixIcon: Icon(Icons.lock_outline, size: 20)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final currentPass = currentPasswordController.text.trim();
              final newPass = newPasswordController.text.trim();
              final confirmPass = confirmPasswordController.text.trim();

              if (currentPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All fields are required'), behavior: SnackBarBehavior.floating),
                );
                return;
              }

              if (newPass != confirmPass) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New passwords do not match'), behavior: SnackBarBehavior.floating),
                );
                return;
              }

              try {
                await ApiService.changePassword(currentPass, newPass);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password updated successfully'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to update password. Check your current password.'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AppUser user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final mobileController = TextEditingController(text: user.mobile);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'Mobile Number',
                prefixIcon: Icon(Icons.phone_outlined, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newEmail = emailController.text.trim();
              final newMobile = mobileController.text.trim();

              if (newName.isEmpty || newEmail.isEmpty || newMobile.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All fields are required'), behavior: SnackBarBehavior.floating),
                );
                return;
              }

              try {
                await ApiService.updateProfile(name: newName, email: newEmail, mobile: newMobile);

                // Update the local user state
                setState(() {
                  user.name = newName;
                  user.email = newEmail;
                  user.mobile = newMobile;
                });

                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update profile: $e'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
