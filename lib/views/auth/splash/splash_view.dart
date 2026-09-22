import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_strings.dart';
import '../../../services/app_open_ad_service.dart';
import '../../../services/service_locator.dart';
import '../../../viewmodels/splash_viewmodel.dart';
import '../welcome/welcome_view.dart';
import '../../home/home_view.dart';
import '../../assessment/assessment_view.dart';
import '../login/login_view.dart';

import 'package:provider/provider.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SplashViewModel>(
      create: (_) => SplashViewModel()..startInitialization(),
      child: const _SplashViewContent(),
    );
  }
}

class _SplashViewContent extends StatefulWidget {
  const _SplashViewContent();

  @override
  State<_SplashViewContent> createState() => _SplashViewContentState();
}

class _SplashViewContentState extends State<_SplashViewContent> with TickerProviderStateMixin {
  SplashViewModel? _viewModel;

  // Animation Controllers
  late final AnimationController _pulseController;
  late final AnimationController _loadingController;
  late final AnimationController _entranceController;

  // Animations
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _loadingTranslation;
  late final Animation<double> _entranceOpacity;
  late final Animation<Offset> _entranceSlide;
  bool _didHandleCompletion = false;

  @override
  void initState() {
    super.initState();

    // 1. Gentle Pulse Animation for Logo (looping)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 2. Looping progress animation for loading bar (1.8 seconds)
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _loadingTranslation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    // 3. Entrance animation for text and loading indicator (fade-in + slide-up)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _entranceOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _entranceSlide =
        Tween<Offset>(begin: const Offset(0.0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    // Start entrance animations
    _entranceController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = context.read<SplashViewModel>();
    if (_viewModel != vm) {
      _viewModel?.removeListener(_onStateChanged);
      _viewModel = vm;
      _viewModel?.addListener(_onStateChanged);
    }
  }

  void _onStateChanged() {
    final vm = _viewModel;
    if (vm != null && vm.isCompleted && mounted && !_didHandleCompletion) {
      _didHandleCompletion = true;
      Widget targetView;
      if (vm.shouldNavigateToHome) {
        targetView = const HomeView();
      } else if (vm.shouldNavigateToLogin) {
        targetView = const LoginView();
      } else if (vm.hasOnboardingProgress) {
        final data = vm.onboardingData!;
        targetView = AssessmentView(onboardingData: data);
      } else {
        targetView = const WelcomeView();
      }

      // Premium PageRoute transition with a smooth fade-in
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => targetView,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
      unawaited(locator<AppOpenAdService>().showAdIfAvailable());
    }
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_onStateChanged);
    _pulseController.dispose();
    _loadingController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Soft Ambient Radial Glow (behind logo)
          Center(
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 320,
                height: 320,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x208455EF),
                      Color(0x00FFFFFF),
                    ],
                    stops: [0.0, 0.7],
                  ),
                ),
              ),
            ),
          ),

          // 2. Main Content Center (New Logo & Title)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo Container
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6B38D4).withAlpha(30),
                          blurRadius: 36,
                          spreadRadius: 4,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Container(
                      width: 130,
                      height: 130,
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.spa,
                            color: AppColors.primary,
                            size: 64,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Text Section with Slide + Fade animation
                AnimatedBuilder(
                  animation: _entranceController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _entranceOpacity.value,
                      child: FractionalTranslation(
                        translation: _entranceSlide.value,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Text(
                        AppStrings.appName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppStrings.splashSubtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6F5092),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Bottom Progress Section
          Positioned(
            bottom: 64,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _entranceController,
              builder: (context, child) {
                return Opacity(
                  opacity: _entranceOpacity.value,
                  child: FractionalTranslation(
                    translation: _entranceSlide.value,
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Clean Loading Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      width: 140,
                      height: 4,
                      color: const Color(0xFFE9DEF5),
                      alignment: Alignment.centerLeft,
                      child: AnimatedBuilder(
                        animation: _loadingController,
                        builder: (context, child) {
                          return FractionalTranslation(
                            translation: Offset(
                              _loadingTranslation.value,
                              0.0,
                            ),
                            child: child,
                          );
                        },
                        child: Container(
                          width: 70,
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF8455EF),
                                Color(0xFF6B38D4),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Loading Text
                  Text(
                    AppStrings.splashLoading,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary.withAlpha(180),
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
