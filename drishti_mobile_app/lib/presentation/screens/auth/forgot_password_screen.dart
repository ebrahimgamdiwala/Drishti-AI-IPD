/// Drishti App - Forgot Password Screen
/// 
/// Password reset request form.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/inputs/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.forgotPassword(_emailController.text.trim());

    setState(() {
      _isLoading = false;
      _emailSent = success;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset email sent! Check your inbox.'),
          backgroundColor: AppColors.success,
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
                        AppStrings.resetPassword,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 300.ms),

                const SizedBox(height: 60),

                // Icon
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      _emailSent ? Icons.mark_email_read : Icons.lock_reset,
                      size: 50,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 300.ms)
                    .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),

                const SizedBox(height: 32),

                // Title
                Center(
                  child: Text(
                    _emailSent ? 'Check Your Email' : 'Forgot Password?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 300.ms),

                const SizedBox(height: 12),

                // Description
                Center(
                  child: Text(
                    _emailSent
                        ? 'We have sent a password reset link to ${_emailController.text}'
                        : 'Enter your email address and we\'ll send you a link to reset your password.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 300.ms),

                const SizedBox(height: 40),

                if (!_emailSent) ...[
                  // Email field
                  CustomTextField(
                    controller: _emailController,
                    label: AppStrings.email,
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
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 300.ms),

                  const SizedBox(height: 32),

                  // Submit button
                  GradientButton(
                    text: 'Send Reset Link',
                    isLoading: _isLoading,
                    onPressed: _handleSubmit,
                  )
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 300.ms),
                ] else ...[
                  // Return to login button
                  GradientButton(
                    text: 'Back to Login',
                    onPressed: () => Navigator.pop(context),
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 300.ms),

                  const SizedBox(height: 16),

                  // Resend button
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() => _emailSent = false);
                      },
                      child: const Text('Didn\'t receive email? Resend'),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 300.ms),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
