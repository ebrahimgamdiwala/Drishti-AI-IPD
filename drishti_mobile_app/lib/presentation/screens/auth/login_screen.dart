/// Drishti App - Login Screen
/// 
/// Clean login form matching UI reference image 1.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/services/voice_service.dart';
import '../../../routes/app_routes.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/buttons/social_button.dart';
import '../../widgets/inputs/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _voiceService = VoiceService();
  
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _announceScreen();
  }

  Future<void> _announceScreen() async {
    await _voiceService.initTts();
    await _voiceService.speak('Login screen. Enter your email and password to continue.');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      _voiceService.speak('Login successful. Welcome!');
      Navigator.pushReplacementNamed(context, AppRoutes.main);
    } else if (mounted) {
      _voiceService.speak('Login failed. ${authProvider.error ?? "Please try again."}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Login failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.googleSignIn();

    setState(() => _isLoading = false);

    if (success && mounted) {
      _voiceService.speak('Google sign in successful. Welcome!');
      Navigator.pushReplacementNamed(context, AppRoutes.main);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Google sign in failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button and title
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios),
                      tooltip: 'Go back',
                    ),
                    Expanded(
                      child: Text(
                        AppStrings.login,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: -0.2, end: 0),

                const SizedBox(height: 40),

                // Welcome text
                Text(
                  AppStrings.welcome,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 300.ms),

                const SizedBox(height: 8),

                Text(
                  'Please enter your credentials to continue',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 300.ms),

                const SizedBox(height: 40),

                // Email field
                Semantics(
                  label: 'Email or mobile number input field',
                  child: CustomTextField(
                    controller: _emailController,
                    label: AppStrings.emailOrPhone,
                    hint: 'example@example.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 300.ms)
                    .slideX(begin: -0.1, end: 0),

                const SizedBox(height: 20),

                // Password field
                Semantics(
                  label: 'Password input field',
                  child: CustomTextField(
                    controller: _passwordController,
                    label: AppStrings.password,
                    hint: '••••••••',
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 300.ms)
                    .slideX(begin: -0.1, end: 0),

                const SizedBox(height: 12),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.forgotPassword);
                    },
                    child: Text(
                      AppStrings.forgotPassword,
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 300.ms),

                const SizedBox(height: 32),

                // Login button
                Semantics(
                  label: 'Login button',
                  button: true,
                  child: GradientButton(
                    text: AppStrings.login,
                    isLoading: _isLoading,
                    onPressed: _handleLogin,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 300.ms)
                    .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),

                const SizedBox(height: 32),

                // Or divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        AppStrings.orLoginWith,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 700.ms, duration: 300.ms),

                const SizedBox(height: 24),

                // Social login buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SocialButton(
                      icon: Icons.g_mobiledata,
                      label: 'Google',
                      onPressed: _handleGoogleSignIn,
                    ),
                    const SizedBox(width: 16),
                    SocialButton(
                      icon: Icons.facebook,
                      label: 'Facebook',
                      onPressed: () {
                        _voiceService.speak('Facebook login not available');
                      },
                    ),
                    const SizedBox(width: 16),
                    SocialButton(
                      icon: Icons.fingerprint,
                      label: 'Biometric',
                      onPressed: () {
                        _voiceService.speak('Biometric login not available');
                      },
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 300.ms),

                const SizedBox(height: 40),

                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.dontHaveAccount,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.signup);
                      },
                      child: Text(
                        AppStrings.signUp,
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 900.ms, duration: 300.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
