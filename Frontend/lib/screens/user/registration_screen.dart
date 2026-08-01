import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import 'package:country_code_picker/country_code_picker.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  bool _obscurePassword = true;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedCountryCode = '+91';

  bool _hasMinLength = false;
  bool _hasUpper = false;
  bool _hasLower = false;
  bool _hasNumber = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
  }

  void _validatePassword() {
    final pass = _passwordController.text;
    setState(() {
      _hasMinLength = pass.length >= 8;
      _hasUpper = pass.contains(RegExp(r'[A-Z]'));
      _hasLower = pass.contains(RegExp(r'[a-z]'));
      _hasNumber = pass.contains(RegExp(r'[0-9]'));
    });
  }

  @override
  void dispose() {
    _passwordController.removeListener(_validatePassword);
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isPasswordValid() {
    return _hasMinLength && _hasUpper && _hasLower && _hasNumber;
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final mobileNumber = _mobileController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || mobileNumber.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_isPasswordValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please ensure your password meets all requirements.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (mobileNumber.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mobile number must be exactly 10 digits.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final fullMobile = '$_selectedCountryCode$mobileNumber';

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.register(name, email, fullMobile, password);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.successColor,
        ),
      );

      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.isNotEmpty ? msg : 'Registration failed. Please try again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return UserThemeWrapper(
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => context.pop(),
          ),
          title: const Text('Create Account'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero Badge Header ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Join IntelliQ Platform',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Book smart appointments with zero wait time',
                              style: TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Form Panel Container ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.getBorderColor(context)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Full Name ──
                      _buildLabel(context, 'Full Name'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        style: TextStyle(color: AppTheme.getTextColor(context)),
                        decoration: InputDecoration(
                          hintText: 'Enter your full legal name',
                          hintStyle: TextStyle(color: AppTheme.getMutedTextColor(context)),
                          prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.getMutedTextColor(context), size: 20),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Email ──
                      _buildLabel(context, 'Email Address'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: AppTheme.getTextColor(context)),
                        decoration: InputDecoration(
                          hintText: 'you@example.com',
                          hintStyle: TextStyle(color: AppTheme.getMutedTextColor(context)),
                          prefixIcon: Icon(Icons.email_outlined, color: AppTheme.getMutedTextColor(context), size: 20),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Mobile Phone Number ──
                      _buildLabel(context, 'Mobile Phone Number'),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A1730) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.getBorderColor(context)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Row(
                            children: [
                              CountryCodePicker(
                                onChanged: (countryCode) {
                                  setState(() {
                                    _selectedCountryCode = countryCode.dialCode ?? '+91';
                                  });
                                },
                                initialSelection: 'IN',
                                countryFilter: const ['IN'],
                                showCountryOnly: false,
                                showOnlyCountryWhenClosed: false,
                                alignLeft: false,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                textStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.getTextColor(context)),
                              ),
                              Container(width: 1, height: 24, color: AppTheme.getBorderColor(context)),
                              Expanded(
                                child: TextField(
                                  controller: _mobileController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 10,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  style: TextStyle(color: AppTheme.getTextColor(context), fontWeight: FontWeight.w600),
                                  decoration: InputDecoration(
                                    hintText: '10-digit mobile number',
                                    hintStyle: TextStyle(color: AppTheme.getMutedTextColor(context), fontWeight: FontWeight.normal),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    fillColor: Colors.transparent,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    counterText: "",
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Secure Password ──
                      _buildLabel(context, 'Secure Password'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleRegister(),
                        style: TextStyle(color: AppTheme.getTextColor(context)),
                        decoration: InputDecoration(
                          hintText: 'Create a strong password',
                          hintStyle: TextStyle(color: AppTheme.getMutedTextColor(context)),
                          prefixIcon: Icon(Icons.lock_outline_rounded, color: AppTheme.getMutedTextColor(context), size: 20),
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                            child: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppTheme.getMutedTextColor(context),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Password Requirements Matrix ──
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF141226) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          childAspectRatio: 4.5,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildPasswordHint(_hasMinLength ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, '8+ characters', _hasMinLength),
                            _buildPasswordHint(_hasUpper ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, 'Uppercase letter', _hasUpper),
                            _buildPasswordHint(_hasLower ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, 'Lowercase letter', _hasLower),
                            _buildPasswordHint(_hasNumber ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, 'Number (0-9)', _hasNumber),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Submit Button ──
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: Consumer<AuthProvider>(
                          builder: (context, auth, child) {
                            return ElevatedButton(
                              onPressed: auth.isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: auth.isLoading
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Create Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Login Link ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(fontSize: 14, color: AppTheme.getMutedTextColor(context)),
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.getTextColor(context),
      ),
    );
  }

  Widget _buildPasswordHint(IconData icon, String text, bool met) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 13,
          color: met ? AppTheme.successColor : AppTheme.textMutedColor.withOpacity(0.5),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: met ? AppTheme.successColor : AppTheme.textMutedColor.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
