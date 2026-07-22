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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed. Please try again. ($e)'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.errorColor,
        ),
      );
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
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Join IntelliQ',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDarkColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create your account to start booking smart appointments',
                style: TextStyle(fontSize: 14, color: AppTheme.textMutedColor),
              ),
              const SizedBox(height: 32),

              // ── Full Name ──
              _buildLabel('Full Name'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Enter your full name',
                  hintStyle: TextStyle(color: AppTheme.textLightColor),
                  prefixIcon: Icon(Icons.person_outline, color: AppTheme.textMutedColor, size: 20),
                ),
              ),
              const SizedBox(height: 20),

              // ── Email ──
              _buildLabel('Email Address'),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'you@example.com',
                  hintStyle: TextStyle(color: AppTheme.textLightColor),
                  prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textMutedColor, size: 20),
                ),
              ),
              const SizedBox(height: 20),

              // ── Mobile ──
              _buildLabel('Mobile Number'),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFF8FAFC),
                    ),
                    child: CountryCodePicker(
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
                      padding: EdgeInsets.zero,
                      textStyle: const TextStyle(fontSize: 14, color: AppTheme.textDarkColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _mobileController,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        hintText: '98765 43210',
                        hintStyle: TextStyle(color: AppTheme.textLightColor),
                        prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.textMutedColor, size: 20),
                        counterText: "", // Hide character counter
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Password ──
              _buildLabel('Password'),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleRegister(),
                decoration: InputDecoration(
                  hintText: 'Create a strong password',
                  hintStyle: const TextStyle(color: AppTheme.textLightColor),
                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textMutedColor, size: 20),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                    child: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppTheme.textMutedColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Password Strength Hints ──
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildPasswordHint(_hasMinLength ? Icons.check_circle_outline : Icons.circle_outlined, '8+ characters', _hasMinLength),
                  _buildPasswordHint(_hasUpper ? Icons.check_circle_outline : Icons.circle_outlined, 'Uppercase', _hasUpper),
                  _buildPasswordHint(_hasLower ? Icons.check_circle_outline : Icons.circle_outlined, 'Lowercase', _hasLower),
                  _buildPasswordHint(_hasNumber ? Icons.check_circle_outline : Icons.circle_outlined, 'Number', _hasNumber),
                ],
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: Consumer<AuthProvider>(
                  builder: (context, auth, child) {
                    return ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleRegister,
                      child: auth.isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Create Account', style: TextStyle(fontSize: 16)),
                    );
                  }
                ),
              ),
              const SizedBox(height: 24),

              // ── Login Link ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(fontSize: 14, color: AppTheme.textMutedColor),
                  ),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textDarkColor,
      ),
    );
  }

  Widget _buildPasswordHint(IconData icon, String text, bool met) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: met ? AppTheme.successColor : AppTheme.textLightColor,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: met ? AppTheme.successColor : AppTheme.textLightColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
