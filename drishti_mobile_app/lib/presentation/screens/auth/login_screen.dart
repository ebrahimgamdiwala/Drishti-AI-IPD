/// Drishti App - Login Screen
///
/// Glassmorphism iOS-style login form.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/services/voice_service.dart';
import '../../../routes/app_routes.dart';
import '../../widgets/glass_button.dart';
import '../../widgets/glass_text_field.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_card.dart';

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
    await _voiceService.speak(
      'Login screen. Enter your email and password to continue.',
    );
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
      _voiceService.speak(
        'Login failed. ${authProvider.error ?? "Please try again."}',
      );
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
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Logo and Welcome
                  Center(
                        child: Column(
                          children: [
                            // Glass logo container
                            GlassCard(
                              width: 80,
                              height: 80,
                              padding: const EdgeInsets.all(16),
                              child: Icon(
                                Icons.visibility,
                                size: 40,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              AppStrings.welcome,
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sign in to continue',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: -0.1, end: 0),

                  const SizedBox(height: 48),

                  // Login Form in Glass Card
                  GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Email field
                            Semantics(
                              label: 'Email or mobile number input field',
                              child: GlassTextField(
                                controller: _emailController,
                                labelText: AppStrings.emailOrPhone,
                                hintText: 'example@example.com',
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
                            ),

                            const SizedBox(height: 20),

                            // Password field
                            Semantics(
                              label: 'Password input field',
                              child: GlassTextField(
                                controller: _passwordController,
                                labelText: AppStrings.password,
                                hintText: '••••••••',
                                obscureText: _obscurePassword,
                                prefixIcon: Icons.lock_outline,
                                suffixIcon: _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                onSuffixIconTap: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
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
                            ),

                            const SizedBox(height: 12),

                            // Forgot password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.forgotPassword,
                                  );
                                },
                                child: Text(
                                  AppStrings.forgotPassword,
                                  style: TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Login button
                            Semantics(
                              label: 'Login button',
                              button: true,
                              child: GlassButton(
                                text: AppStrings.login,
                                isLoading: _isLoading,
                                onPressed: _handleLogin,
                                width: double.infinity,
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 32),

                  // Or divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: AppColors.textSecondaryLight.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          AppStrings.orLoginWith,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondaryLight),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: AppColors.textSecondaryLight.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                  const SizedBox(height: 24),

                  // Social login buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SocialGlassButton(
                        icon: Icons.g_mobiledata,
                        onPressed: _handleGoogleSignIn,
                      ),
                      const SizedBox(width: 16),
                      _SocialGlassButton(
                        icon: Icons.facebook,
                        onPressed: () {
                          _voiceService.speak('Facebook login not available');
                        },
                      ),
                      const SizedBox(width: 16),
                      _SocialGlassButton(
                        icon: Icons.fingerprint,
                        onPressed: () {
                          _voiceService.speak('Biometric login not available');
                        },
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

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
                  ).animate().fadeIn(delay: 800.ms, duration: 400.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Social login glass button
class _SocialGlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _SocialGlassButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      width: 60,
      height: 60,
      padding: EdgeInsets.zero,
      onTap: onPressed,
      child: Icon(icon, size: 28, color: AppColors.primaryBlue),
    );
  }
}
