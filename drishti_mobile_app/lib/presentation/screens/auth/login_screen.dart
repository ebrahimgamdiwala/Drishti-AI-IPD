/// Drishti App - Login Screen
///
/// Glassmorphism iOS-style login form.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/services/voice_service.dart';
import '../../../data/services/biometric_service.dart';
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
  final _biometricService = BiometricService();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String _biometricType = 'Biometric';

  @override
  void initState() {
    super.initState();
    _initBiometric();
    _announceScreen();
  }

  Future<void> _initBiometric() async {
    final available = await _biometricService.isBiometricAvailable();
    final enabled = await _biometricService.isBiometricEnabled();
    final typeName = await _biometricService.getBiometricTypeName();
    
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
      _biometricType = typeName;
    });

    // Auto-login with biometric if enabled
    if (enabled && available) {
      await _handleBiometricLogin();
    }
  }

  Future<void> _announceScreen() async {
    await _voiceService.initTts();
    
    if (_biometricEnabled) {
      await _voiceService.speak(
        'Login screen. $_biometricType authentication is enabled. Tap the fingerprint button to login quickly.',
      );
    } else {
      await _voiceService.speak(
        'Login screen. Enter your email and password to continue.',
      );
    }
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
    final l10n = AppLocalizations.of(context)!;
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      _voiceService.speak(l10n.loginSuccessful);
      
      // Offer to enable biometric if available and not already enabled
      if (_biometricAvailable && !_biometricEnabled) {
        _showEnableBiometricDialog();
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.main);
      }
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

  Future<void> _handleBiometricLogin() async {
    setState(() => _isLoading = true);

    await _voiceService.speak('Authenticating with $_biometricType');

    final credentials = await _biometricService.authenticateAndGetCredentials();

    if (credentials != null && mounted) {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.login(
        credentials['email']!,
        credentials['password']!,
      );

      setState(() => _isLoading = false);

      if (success && mounted) {
        _voiceService.speak('$_biometricType authentication successful. Welcome!');
        Navigator.pushReplacementNamed(context, AppRoutes.main);
      } else if (mounted) {
        _voiceService.speak('Login failed. Please try manual login.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Biometric login failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        _voiceService.speak('$_biometricType authentication cancelled');
      }
    }
  }

  void _showEnableBiometricDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enable $_biometricType Login?'),
        content: Text(
          'Would you like to enable $_biometricType authentication for quick login?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, AppRoutes.main);
            },
            child: const Text('Not Now'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _enableBiometric();
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  Future<void> _enableBiometric() async {
    final success = await _biometricService.enableBiometric(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      _voiceService.speak('$_biometricType login enabled successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_biometricType login enabled'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.main);
    } else if (mounted) {
      _voiceService.speak('Failed to enable $_biometricType login');
      Navigator.pushReplacementNamed(context, AppRoutes.main);
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
    final l10n = AppLocalizations.of(context)!;
    
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
                              l10n.welcome,
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.login,
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
                                labelText: l10n.emailOrPhone,
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
                                labelText: l10n.password,
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
                                  l10n.forgotPassword,
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
                                text: l10n.login,
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
                          l10n.orLoginWith,
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
                        onPressed: _biometricAvailable
                            ? _handleBiometricLogin
                            : () {
                                _voiceService.speak(
                                  'Biometric authentication not available on this device',
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Biometric authentication not available',
                                    ),
                                  ),
                                );
                              },
                        isEnabled: _biometricAvailable,
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

                  const SizedBox(height: 40),

                  // Sign up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.dontHaveAccount,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.signup);
                        },
                        child: Text(
                          l10n.signup,
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
  final bool isEnabled;

  const _SocialGlassButton({
    required this.icon,
    required this.onPressed,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      width: 60,
      height: 60,
      padding: EdgeInsets.zero,
      onTap: onPressed,
      child: Icon(
        icon,
        size: 28,
        color: isEnabled
            ? AppColors.primaryBlue
            : AppColors.textSecondaryLight.withValues(alpha: 0.5),
      ),
    );
  }
}
