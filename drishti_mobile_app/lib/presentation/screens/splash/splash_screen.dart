/// Drishti App - Splash Screen
///
/// Modern splash screen with circular reveal animation.
/// The expanding orb creates a circular "hole" that reveals the destination screen underneath.
library;

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/vlm_provider.dart';
import '../../../routes/app_routes.dart';
import '../onboarding/permissions_screen.dart';
import '../auth/login_screen.dart';
import '../main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;

  bool _isExpanding = false;
  bool _isAuthenticated = false;
  bool _showDestination = false;
  Widget? _destinationWidget;
  double _expandProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initialize();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Smooth breathing scale animation
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.06,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.06,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);

    // Fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    // Glow pulse animation
    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.3,
          end: 0.5,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.5,
          end: 0.3,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);

    _controller.repeat();
  }

  Future<void> _initialize() async {
    // Defer initialization until after the first frame to avoid calling
    // notifyListeners during build
    await Future.microtask(() async {
      final authProvider = context.read<AuthProvider>();
      await authProvider.init();
      
      if (!mounted) return;
      
      _isAuthenticated = authProvider.isAuthenticated;
    });

    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    // Determine destination based on auth and permissions
    Widget destinationScreen;
    String destinationRoute;

    if (!_isAuthenticated) {
      // Not logged in - go to login
      destinationScreen = const LoginScreen();
      destinationRoute = AppRoutes.login;
    } else {
      // Logged in - check permissions
      final cameraGranted = await Permission.camera.isGranted;
      final micGranted = await Permission.microphone.isGranted;

      if (!cameraGranted || !micGranted) {
        // Permissions not granted - go to permissions screen
        destinationScreen = const PermissionsScreen();
        destinationRoute = AppRoutes.permissions;
      } else {
        // Permissions granted - check model and go to main
        // ignore: use_build_context_synchronously
        final vlmProvider = context.read<VLMProvider>();
        final modelsDownloaded = await vlmProvider.areModelsDownloaded;

        if (modelsDownloaded) {
          // Models exist - initialize if needed and go to main
          if (!vlmProvider.isReady) {
            await vlmProvider.initialize();
          }
          destinationScreen = const MainShell();
          destinationRoute = AppRoutes.main;
        } else {
          // Models don't exist - go to download screen
          destinationScreen = const MainShell(); // Show main underneath for reveal
          destinationRoute = AppRoutes.modelDownload;
        }
      }
    }

    if (!mounted) return;

    // Show destination screen underneath before expanding
    setState(() {
      _showDestination = true;
      _destinationWidget = destinationScreen;
    });

    // Small delay to ensure destination is rendered
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    // Start expansion animation
    setState(() => _isExpanding = true);
    _controller.stop();

    // Smooth expansion using step-based animation
    const totalDuration = 700; // ms
    const fps = 60;
    const stepMs = 1000 ~/ fps;
    final totalSteps = totalDuration ~/ stepMs;

    for (int i = 0; i <= totalSteps; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: stepMs));
      if (mounted) {
        final t = i / totalSteps;
        // Use easeInOutCubic for smooth acceleration/deceleration
        final curved = t < 0.5
            ? 4 * t * t * t
            : 1 - math.pow(-2 * t + 2, 3) / 2;
        setState(() {
          _expandProgress = curved;
        });
      }
    }

    if (!mounted) return;

    // Navigate to determined destination
    Navigator.pushReplacementNamed(context, destinationRoute);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(
      size.width * size.width + size.height * size.height,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Destination screen (shown underneath during reveal)
          if (_showDestination && _destinationWidget != null)
            Positioned.fill(child: _destinationWidget!),

          // Splash overlay with circular clip
          if (!_isExpanding || _expandProgress < 1.0)
            Positioned.fill(
              child: ClipPath(
                clipper: _CircularRevealClipper(
                  center: center,
                  radius: _isExpanding ? _expandProgress * maxRadius : 0,
                  revealing: _isExpanding,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              AppColors.darkBackgroundGradientStart,
                              AppColors.darkBackgroundGradientEnd,
                            ]
                          : [
                              AppColors.lightBackgroundGradientStart,
                              AppColors.lightBackgroundGradientEnd,
                            ],
                    ),
                  ),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) =>
                        _buildSplashContent(size, isDark),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSplashContent(Size size, bool isDark) {
    const orbBaseSize = 130.0;
    final orbSize = orbBaseSize * (_isExpanding ? 1.0 : _scaleAnimation.value);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Glass orb
        Center(
          child: Opacity(
            opacity: _isExpanding ? 1.0 - _expandProgress : 1.0,
            child: Container(
              width: orbSize,
              height: orbSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(
                      alpha: _glowAnimation.value,
                    ),
                    blurRadius: 50,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: AppColors.gradientStart.withValues(
                      alpha: _glowAnimation.value * 0.5,
                    ),
                    blurRadius: 80,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                Colors.white.withValues(alpha: 0.15),
                                Colors.white.withValues(alpha: 0.05),
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.7),
                                Colors.white.withValues(alpha: 0.3),
                              ],
                      ),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.8),
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Logo and text
                        Center(
                          child: Opacity(
                            opacity: _fadeAnimation.value,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Eye icon
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppColors.primaryGradient,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryBlue.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 15,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.visibility_rounded,
                                    size: 28,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                // App name
                                Text(
                                  'Drishti',
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryBlue,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                Text(
                                  'AI',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.gradientStart,
                                    letterSpacing: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Loading indicator
        if (!_isExpanding)
          Positioned(
            bottom: 120,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Column(
                children: [
                  _LoadingDots(animation: _controller),
                  const SizedBox(height: 16),
                  Text(
                    'Loading',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Version
        if (!_isExpanding)
          Positioned(
            bottom: 50,
            child: Opacity(
              opacity: _fadeAnimation.value * 0.5,
              child: Text(
                'v1.0.0',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Custom clipper for circular reveal effect
/// Creates a "hole" in the splash screen that expands to reveal the destination
class _CircularRevealClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;
  final bool revealing;

  _CircularRevealClipper({
    required this.center,
    required this.radius,
    required this.revealing,
  });

  @override
  Path getClip(Size size) {
    final path = Path();

    if (revealing) {
      // Create a path that excludes the expanding circle (reveals content underneath)
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      path.addOval(Rect.fromCircle(center: center, radius: radius));
      path.fillType = PathFillType.evenOdd;
    } else {
      // Full coverage - no reveal yet
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    return path;
  }

  @override
  bool shouldReclip(_CircularRevealClipper oldClipper) {
    return oldClipper.radius != radius || oldClipper.revealing != revealing;
  }
}

class _LoadingDots extends StatelessWidget {
  final Animation<double> animation;

  const _LoadingDots({required this.animation});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final progress = (animation.value + index * 0.33) % 1.0;
            final scale = 0.5 + (math.sin(progress * math.pi) * 0.5);
            final opacity = 0.3 + (math.sin(progress * math.pi) * 0.7);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryBlue.withValues(alpha: opacity),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
