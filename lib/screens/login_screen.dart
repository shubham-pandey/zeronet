import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  int _selectedTab = 0; // 0: Email/Password, 1: OTP, 2: Register

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin(AuthService authService) async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final success = await authService.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful!')),
        );
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authService.error ?? 'Login failed')),
        );
      }
    }
  }

  Future<void> _handleRegister(AuthService authService) async {
    // Validate fields
    if (_emailController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    // Validate email format
    if (!_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    // Validate passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    // Validate password strength
    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters')),
      );
      return;
    }

    final success = await authService.registerUser(
      email: _emailController.text,
      name: _nameController.text,
      password: _passwordController.text,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please check your email to verify.'),
            duration: Duration(seconds: 3),
          ),
        );
        // Clear fields and go back to login
        setState(() {
          _emailController.clear();
          _nameController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
          _selectedTab = 0;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authService.error ?? 'Registration failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZeronetColors.background,
      body: SafeArea(
        child: Consumer<AuthService>(
          builder: (context, authService, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // Header
                  Row(
                    children: [
                      Text(
                        'ZERONET',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: ZeronetColors.primary,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Emergency Response Network',
                    style: TextStyle(
                      fontSize: 14,
                      color: ZeronetColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Tab selector
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTab(
                          label: 'Login',
                          index: 0,
                          isActive: _selectedTab == 0,
                          color: ZeronetColors.primary,
                        ),
                        const SizedBox(width: 16),
                        _buildTab(
                          label: 'Register',
                          index: 2,
                          isActive: _selectedTab == 2,
                          color: ZeronetColors.success,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Email/Password Tab
                  if (_selectedTab == 0) ...[
                    TextField(
                      controller: _emailController,
                      style: TextStyle(color: ZeronetColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Email',
                        hintStyle: TextStyle(color: ZeronetColors.textTertiary),
                        filled: true,
                        fillColor: ZeronetColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: ZeronetColors.surfaceBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: ZeronetColors.surfaceBorder),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      style: TextStyle(color: ZeronetColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: TextStyle(color: ZeronetColors.textTertiary),
                        filled: true,
                        fillColor: ZeronetColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: ZeronetColors.surfaceBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: ZeronetColors.surfaceBorder),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility : Icons.visibility_off,
                            color: ZeronetColors.textTertiary,
                          ),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: authService.isLoading
                            ? null
                            : () => _handleEmailLogin(authService),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ZeronetColors.primary,
                          disabledBackgroundColor:
                              ZeronetColors.primary.withValues(alpha: 0.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: authService.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text(
                                'LOGIN',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],

                  // OTP Tab
                  if (_selectedTab == 1) ...[
                    Text(
                      'OTP login coming soon',
                      style: TextStyle(color: ZeronetColors.textTertiary),
                    ),
                  ],

                  // Register Tab
                  if (_selectedTab == 2) ...[
                    TextField(
                      controller: _emailController,
                      style: TextStyle(color: ZeronetColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Email',
                        hintStyle: TextStyle(color: ZeronetColors.textTertiary),
                        filled: true,
                        fillColor: ZeronetColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: ZeronetColors.surfaceBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: ZeronetColors.surfaceBorder),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      style: TextStyle(color: ZeronetColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Full Name',
                        hintStyle: TextStyle(color: ZeronetColors.textTertiary),
                        filled: true,
                        fillColor: ZeronetColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: ZeronetColors.surfaceBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: ZeronetColors.surfaceBorder),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      style: TextStyle(color: ZeronetColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Password (min 8 characters)',
                        hintStyle: TextStyle(color: ZeronetColors.textTertiary),
                        filled: true,
                        fillColor: ZeronetColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: ZeronetColors.surfaceBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: ZeronetColors.surfaceBorder),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility : Icons.visibility_off,
                            color: ZeronetColors.textTertiary,
                          ),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: !_showConfirmPassword,
                      style: TextStyle(color: ZeronetColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Confirm Password',
                        hintStyle: TextStyle(color: ZeronetColors.textTertiary),
                        filled: true,
                        fillColor: ZeronetColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: ZeronetColors.surfaceBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: ZeronetColors.surfaceBorder),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                            color: ZeronetColors.textTertiary,
                          ),
                          onPressed: () => setState(
                            () => _showConfirmPassword = !_showConfirmPassword,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: authService.isLoading
                            ? null
                            : () => _handleRegister(authService),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ZeronetColors.success,
                          disabledBackgroundColor:
                              ZeronetColors.success.withValues(alpha: 0.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: authService.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text(
                                'CREATE ACCOUNT',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(
                              fontSize: 13,
                              color: ZeronetColors.textTertiary,
                            ),
                            children: [
                              TextSpan(
                                text: 'Login',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: ZeronetColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (authService.error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ZeronetColors.danger.withValues(alpha: 0.1),
                        border: Border.all(color: ZeronetColors.danger),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        authService.error!,
                        style: TextStyle(color: ZeronetColors.danger, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required int index,
    required bool isActive,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? color : ZeronetColors.surfaceBorder,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isActive ? color : ZeronetColors.textTertiary,
          ),
        ),
      ),
    );
  }
}