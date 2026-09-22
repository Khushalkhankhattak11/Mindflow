import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../models/routine_model.dart';
import '../../viewmodels/wellness_plan_viewmodel.dart';
import '../../widgets/scale_pressed_button.dart';
import '../auth/signup/signup_view.dart';

class WellnessPlanView extends StatefulWidget {
  const WellnessPlanView({super.key});

  @override
  State<WellnessPlanView> createState() => _WellnessPlanViewState();
}

class _WellnessPlanViewState extends State<WellnessPlanView> with TickerProviderStateMixin {
  // Animation Controllers
  late final AnimationController _floatController;
  late final AnimationController _entranceController;

  // Animations
  late final Animation<double> _floatAnimation;
  late final List<Animation<double>> _staggeredOpacities = [];
  late final List<Animation<Offset>> _staggeredSlides = [];

  @override
  void initState() {
    super.initState();

    // 1. Floating Animation for Serene Lotus Image (6 seconds)
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

    // 2. Staggered Entrance Animations for headers, cards, and CTA (1200ms)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Define 5 staggered levels of entrance (Hero, Card1, Card2, Card3, CTA)
    for (int i = 0; i < 5; i++) {
      final double start = i * 0.15;
      final double end = (start + 0.5).clamp(0.0, 1.0);
      
      _staggeredOpacities.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        ),
      );

      _staggeredSlides.add(
        Tween<Offset>(begin: const Offset(0.0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        ),
      );
    }

    _entranceController.forward();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<WellnessPlanViewModel>(context);
    final primaryColor = AppColors.primary;
    final secondaryTextColor = AppColors.assessmentTextSecondary;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Lush Gradient Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration:  const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.assessmentBg,
                  Color(0xFFEFE4FB),
                  Color(0xFFE9DDFF),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 2. Main Page Layout
          SafeArea(
            child: Column(
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                           Icon(
                            Icons.spa,
                            color: primaryColor,
                            size: 26,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.appName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          // Notification action trigger
                        },
                        icon:  Icon(
                          Icons.notifications_none,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable Plan Details
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Column(
                          children: [
                            // Hero celebration area (staggered index 0)
                            AnimatedBuilder(
                              animation: _entranceController,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _staggeredOpacities[0].value,
                                  child: FractionalTranslation(
                                    translation: _staggeredSlides[0].value,
                                    child: child,
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  // Serene Glowing Lotus Bloom illustration
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 240,
                                        height: 240,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFFE9DDFF).withAlpha(51),
                                        ),
                                      ),
                                      AnimatedBuilder(
                                        animation: _floatController,
                                        builder: (context, child) {
                                          return Transform.translate(
                                            offset: Offset(0, _floatAnimation.value),
                                            child: child,
                                          );
                                        },
                                        child: Image.network(
                                          'https://lh3.googleusercontent.com/aida-public/AB6AXuBZJPPyOqlOgRdcF9FmME3eQFFwzrk8jiJ7VNu3jbgIOHI_mVc1vrRxE1lr1oI9UufC2vSkWdso6Vw0-M8aYbBwekPfn_cFQMPNeSpnrE5ArXvGzY4yzM2WXtEtWbT7BUsxCQPqW9WM7EqHzgS9YK_-GQ01uHrTdiuQSS8deRl_yr2ry5_GTKktMI0mR2y_dBAEyzCloEaFz5TtilkrhHKcFB0ei5w9eadOTbfheHsKiKOfyilQQjT9Og',
                                          width: 220,
                                          height: 220,
                                          fit: BoxFit.contain,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return  SizedBox(
                                              width: 220,
                                              height: 220,
                                              child: Center(
                                                child: CircularProgressIndicator(color: primaryColor),
                                              ),
                                            );
                                          },
                                          errorBuilder: (context, error, stackTrace) {
                                            return  Icon(
                                              Icons.spa_rounded,
                                              color: primaryColor,
                                              size: 120,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    AppStrings.planReadyTitle,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.assessmentTextPrimary,
                                      letterSpacing: -0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    AppStrings.planReadySubtitle,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      color: secondaryTextColor,
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 48),

                            // Timeline Title
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                AppStrings.planTodayRoutine,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.homeSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Routine Staggered Cards (indices 1, 2, 3)
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: viewModel.routine.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final routineItem = viewModel.routine[index];
                                final animIndex = index + 1;

                                return AnimatedBuilder(
                                  animation: _entranceController,
                                  builder: (context, child) {
                                    return Opacity(
                                      opacity: _staggeredOpacities[animIndex].value,
                                      child: FractionalTranslation(
                                        translation: _staggeredSlides[animIndex].value,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: RoutineCard(
                                    item: routineItem,
                                    onTap: () {
                                      // routine click detail flow placeholder
                                    },
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 48),

                            // Call to Action Start Journey (index 4)
                            AnimatedBuilder(
                              animation: _entranceController,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _staggeredOpacities[4].value,
                                  child: FractionalTranslation(
                                    translation: _staggeredSlides[4].value,
                                    child: child,
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  ScalePressedButton(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation, secondaryAnimation) => const SignupView(),
                                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                            return FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            );
                                          },
                                          transitionDuration: const Duration(milliseconds: 600),
                                        ),
                                      );
                                    },
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(28),
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF6B38D4), Color(0xFF8455EF)],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryColor.withAlpha(51),
                                          blurRadius: 16,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      AppStrings.planStartJourney,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    AppStrings.planCancelSettings,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: secondaryTextColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Reusable RoutineCard
class RoutineCard extends StatefulWidget {
  final RoutineItem item;
  final VoidCallback onTap;

  const RoutineCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  State<RoutineCard> createState() => _RoutineCardState();
}

class _RoutineCardState extends State<RoutineCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(115),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isHovered ? primaryColor.withAlpha(77) : Colors.white.withAlpha(77),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withAlpha(_isHovered ? 26 : 20),
              blurRadius: _isHovered ? 40 : 32,
              offset: Offset(0, _isHovered ? 12 : 8),
            ),
          ],
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon Block container
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: widget.item.color.withAlpha(26),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    widget.item.icon,
                    color: widget.item.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Text details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.item.period.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              color: widget.item.color,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            widget.item.timeLabel,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.assessmentTextSecondary.withAlpha(153),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.item.title,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.assessmentTextPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.item.description,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.assessmentTextSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.assessmentTextSecondary.withAlpha(102),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
