import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../models/onboarding_model.dart';
import '../../viewmodels/assessment_viewmodel.dart';
import 'widgets/step_feeling_options.dart';
import 'widgets/step_stress_options.dart';
import 'widgets/step_sleep_options.dart';
import 'widgets/step_goal_options.dart';
import 'widgets/step_commitment_options.dart';
import '../wellness/wellness_plan_view.dart';

class AssessmentView extends StatefulWidget {
  final OnboardingData onboardingData;

  const AssessmentView({
    super.key,
    required this.onboardingData,
  });

  @override
  State<AssessmentView> createState() => _AssessmentViewState();
}

class _AssessmentViewState extends State<AssessmentView> {
  AssessmentViewModel? _viewModel;
  Offset _mouseOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
  }

  void _onStateChanged() {
    if (_viewModel?.isComplete == true && mounted) {
      // Transition to WellnessPlanView once assessment is saved
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const WellnessPlanView(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_onStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AssessmentViewModel>(
      create: (_) {
        final vm = AssessmentViewModel(
          onboardingData: widget.onboardingData,
        );
        _viewModel?.removeListener(_onStateChanged);
        _viewModel = vm;
        _viewModel!.addListener(_onStateChanged);
        return vm;
      },
      child: Builder(
        builder: (context) {
          final viewModel = context.watch<AssessmentViewModel>();
          final primaryColor = AppColors.primary;
          final secondaryTextColor = AppColors.assessmentTextSecondary;
          final progressBgColor = AppColors.progressBg;

          return Scaffold(
            body: Stack(
              children: [
                // 1. Ambient Background Layer with shifting parallax blobs
                MouseRegion(
                  onHover: (event) {
                    setState(() {
                      _mouseOffset = Offset(
                        (event.localPosition.dx - MediaQuery.of(context).size.width / 2) * 0.015,
                        (event.localPosition.dy - MediaQuery.of(context).size.height / 2) * 0.015,
                      );
                    });
                  },
                  child: Stack(
                    children: [
                      // Base Linear Gradient
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.assessmentBg,
                              Color(0xFFF4EAFF),
                              Color(0xFFE9DDFF),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      // Blob 1 (Top Left)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 100),
                        top: -100 + _mouseOffset.dy,
                        left: -100 + _mouseOffset.dx,
                        child: Container(
                          width: 500,
                          height: 500,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF8455EF).withAlpha(38),
                                const Color(0xFFC9A3FF).withAlpha(0),
                              ],
                              stops: const [0.0, 0.7],
                            ),
                          ),
                        ),
                      ),
                      // Blob 2 (Bottom Right)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 100),
                        bottom: -200 + (_mouseOffset.dy * -1.5),
                        right: -100 + (_mouseOffset.dx * -1.5),
                        child: Container(
                          width: 600,
                          height: 600,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF4E45D5).withAlpha(26),
                                const Color(0xFF8455EF).withAlpha(0),
                              ],
                              stops: const [0.0, 0.7],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Main Content Layout
                SafeArea(
                  child: Column(
                    children: [
                      // Header with Progress bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Previous Button (Hidden/disabled on Step 1)
                              Opacity(
                                opacity: viewModel.currentStep > 1 ? 1.0 : 0.0,
                                child: TextButton(
                                  onPressed: viewModel.currentStep > 1
                                      ? viewModel.previousStep
                                      : null,
                                  style: TextButton.styleFrom(
                                    foregroundColor: secondaryTextColor,
                                  ),
                                  child: Text(
                                    AppStrings.btnPrevious,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              // Step indicator text
                              Text(
                                'Step ${viewModel.currentStep} of 5',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: secondaryTextColor,
                                ),
                              ),
                              // Empty placeholder to balance spacing
                              const SizedBox(width: 80),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Progress Bar
                          Container(
                            width: double.infinity,
                            height: 6,
                            decoration: BoxDecoration(
                              color: progressBgColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                                width: MediaQuery.of(context).size.width *
                                    viewModel.progressPercentage,
                                height: 6,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF6B38D4),
                                      Color(0xFF8455EF),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Scrollable content area
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.0, 0.05),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: Column(
                                key: ValueKey<int>(viewModel.currentStep),
                                children: [
                                  // Step Heading & Subheading
                                  _buildStepHeader(viewModel),
                                  const SizedBox(height: 36),
                                  // Step Options Content
                                  _buildStepOptions(viewModel),
                                  const SizedBox(height: 48),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Bottom Navigation Button
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: GestureDetector(
                          onTap: viewModel.canContinue && !viewModel.isSubmitting
                              ? viewModel.nextStep
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              gradient: viewModel.canContinue
                                  ? const LinearGradient(
                                      colors: [Color(0xFF6B38D4), Color(0xFF8455EF)],
                                    )
                                  : null,
                              color: viewModel.canContinue
                                  ? null
                                  : primaryColor.withAlpha(128),
                              boxShadow: viewModel.canContinue
                                  ? [
                                      BoxShadow(
                                        color: primaryColor.withAlpha(51),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: viewModel.isSubmitting
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        AppStrings.btnSaving,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        viewModel.currentStep == 5
                                            ? AppStrings.btnFinish
                                            : AppStrings.btnContinue,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.arrow_forward,
                                        color: Colors.white,
                                        size: 18,
                                      ),
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
      },
    ),
  );
}

  Widget _buildStepHeader(AssessmentViewModel viewModel) {
    String title = '';
    String subtitle = '';

    switch (viewModel.currentStep) {
      case 1:
        title = AppStrings.step1Title;
        subtitle = AppStrings.step1Subtitle;
        break;
      case 2:
        title = AppStrings.step2Title;
        subtitle = AppStrings.step2Subtitle;
        break;
      case 3:
        title = AppStrings.step3Title;
        subtitle = AppStrings.step3Subtitle;
        break;
      case 4:
        title = AppStrings.step4Title;
        subtitle = AppStrings.step4Subtitle;
        break;
      case 5:
        title = AppStrings.step5Title;
        subtitle = AppStrings.step5Subtitle;
        break;
    }

    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.assessmentTextPrimary,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.assessmentTextSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStepOptions(AssessmentViewModel viewModel) {
    switch (viewModel.currentStep) {
      case 1:
        return StepFeelingOptions(viewModel: viewModel);
      case 2:
        return StepStressOptions(viewModel: viewModel);
      case 3:
        return StepSleepOptions(viewModel: viewModel);
      case 4:
        return StepGoalOptions(viewModel: viewModel);
      case 5:
        return StepCommitmentOptions(viewModel: viewModel);
      default:
        return const SizedBox.shrink();
    }
  }
}
