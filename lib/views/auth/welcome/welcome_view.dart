import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_strings.dart';
import '../../../models/welcome_model.dart';
import '../../../viewmodels/welcome_viewmodel.dart';
import '../../../widgets/scale_pressed_button.dart';
import '../../../services/service_locator.dart';
import '../../../repositories/onboarding_repository.dart';
import '../login/login_view.dart';
import '../../assessment/assessment_view.dart';

import 'package:provider/provider.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<WelcomeViewModel>(
      create: (_) => WelcomeViewModel()..prepareOnboarding(),
      child: const _WelcomeViewContent(),
    );
  }
}

class _WelcomeViewContent extends StatefulWidget {
  const _WelcomeViewContent();

  @override
  State<_WelcomeViewContent> createState() => _WelcomeViewContentState();
}

class _WelcomeViewContentState extends State<_WelcomeViewContent> with TickerProviderStateMixin {
  WelcomeViewModel? _viewModel;

  // Animation Controllers
  late final AnimationController _floatController;
  late final AnimationController _entranceController;

  // Animations
  late final Animation<double> _floatAnimation;
  late final Animation<double> _entranceOpacity;
  late final Animation<Offset> _entranceSlide;

  @override
  void initState() {
    super.initState();

    // 1. Floating Animation for the Illustration (looping up and down)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0.0, end: -15.0).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOut,
      ),
    );

    // 2. Entrance Animation for Content (fade-in + slide-up)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _entranceOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOut,
      ),
    );

    _entranceSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOut,
      ),
    );

    // Start entrance animation
    _entranceController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = context.read<WelcomeViewModel>();
    if (_viewModel != vm) {
      _viewModel?.removeListener(_onActionTriggered);
      _viewModel = vm;
      _viewModel?.addListener(_onActionTriggered);
    }
  }

  Future<void> _onActionTriggered() async {
    final vm = _viewModel;
    if (vm != null && vm.selectedAction != null && mounted) {
      // Determine target view based on user selection
      final Widget targetView;
      if (vm.selectedAction == WelcomeAction.getStarted) {
        if (vm.onboardingData == null) {
          await vm.prepareOnboarding();
        }
        targetView = AssessmentView(onboardingData: vm.onboardingData!);
      } else {
        // Record visit to LoginScreen in Firestore
        try {
          final repo = locator<OnboardingRepository>();
          final data = await repo.getUnregisteredOnboarding();
          if (data != null) {
            final updated = data.recordVisit('LoginScreen');
            await repo.saveUnregisteredOnboarding(updated);
          }
        } catch (_) {}
        targetView = const LoginView();
      }

      if (!mounted) return;

      await Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => targetView,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
      // Clear action afterwards
      vm.clearAction();
    }
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_onActionTriggered);
    _floatController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.welcomePrimary;
    final secondaryTextColor = AppColors.welcomeSecondaryText;
    final outlineColor = AppColors.welcomeOutline;
    final footerLinkColor = AppColors.welcomeFooterLink;

    return Scaffold(
      backgroundColor: AppColors.welcomeBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      // Header Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           Icon(
                            Icons.spa,
                            color: primaryColor,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.appName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      
                      // Illustration Section (Expands to fill space)
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Soft Background Glow
                            Container(
                              width: 320,
                              height: 320,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Color(0x33F0DBFF),
                                    Color(0x00FFFFFF),
                                  ],
                                  stops: [0.0, 0.7],
                                ),
                              ),
                            ),
                            // Floating 3D Illustration
                            AnimatedBuilder(
                              animation: _floatController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _floatAnimation.value),
                                  child: child,
                                );
                              },
                              child: Container(
                                width: 280,
                                height: 280,
                                decoration: const BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x1A4B0082),
                                      blurRadius: 40,
                                      offset: Offset(0, 20),
                                    ),
                                  ],
                                ),
                                child: Image.network(
                                  'https://lh3.googleusercontent.com/aida-public/AB6AXuBjiktaYxBN6tGcZPsaeGJCMTT3nM_c3k7nTRw6nE7cJW1AWwXSSfw-JTvx9r1xOKSYhpxEq5BelJVeWC8NIPz-gNJ2FBI9C2BKO_c37XNVjfAqoniJafouKecfQ9j_ob0Gnoe8BAEe3C31HIS5SyO_gzKQX1igd9uz1twr3fVHQBxH1403DHs3TEWQaRk45vcEhfjpbeu5gLSsimu_ySWvq0VAkcDi_2TXiS9qG5XcTgN_Za5sghzZYg',
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return  Center(
                                      child: CircularProgressIndicator(
                                        color: primaryColor,
                                        strokeWidth: 3,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return  Center(
                                      child: Icon(
                                        Icons.self_improvement,
                                        color: primaryColor,
                                        size: 100,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Text and Buttons Section
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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppStrings.welcomeTitle,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: primaryColor,
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 280),
                                child: Text(
                                  AppStrings.welcomeSubtitle,
                                  style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: secondaryTextColor,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 48),

                              // CTA Buttons
                              ScalePressedButton(
                                onTap: () => context.read<WelcomeViewModel>().selectAction(WelcomeAction.getStarted),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4B0082).withAlpha(38),
                                      blurRadius: 30,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  AppStrings.getStarted,
                                  style: GoogleFonts.manrope(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ScalePressedButton(
                                onTap: () => context.read<WelcomeViewModel>().selectAction(WelcomeAction.login),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: outlineColor,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  AppStrings.logIn,
                                  style: GoogleFonts.manrope(
                                    color: primaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),

                      // Footer Links Section
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {},
                              child: Text(
                                AppStrings.terms,
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: footerLinkColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            GestureDetector(
                              onTap: () {},
                              child: Text(
                                AppStrings.privacy,
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: footerLinkColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
