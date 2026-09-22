import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_colors.dart';
import '../../../models/assessment_model.dart';
import '../../../viewmodels/assessment_viewmodel.dart';
import '../../../widgets/assessment_card.dart';

class StepSleepOptions extends StatelessWidget {
  final AssessmentViewModel viewModel;

  const StepSleepOptions({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSleepItem(
          SleepQuality.excellent,
          'Excellent',
          'I wake up feeling refreshed and energized every day.',
          Icons.bedtime,
        ),
        const SizedBox(height: 12),
        _buildSleepItem(
          SleepQuality.good,
          'Good',
          'I generally sleep well, with occasional disruptions.',
          Icons.sentiment_satisfied,
        ),
        const SizedBox(height: 12),
        _buildSleepItem(
          SleepQuality.average,
          'Average',
          'My sleep is hit or miss; I often feel tired during the day.',
          Icons.sentiment_neutral,
        ),
        const SizedBox(height: 12),
        _buildSleepItem(
          SleepQuality.poor,
          'Poor',
          'I struggle to fall or stay asleep most nights.',
          Icons.sentiment_dissatisfied,
        ),
        const SizedBox(height: 12),
        _buildSleepItem(
          SleepQuality.veryPoor,
          'Very Poor',
          'I feel exhausted constantly and have severe sleep issues.',
          Icons.mood_bad,
        ),
      ],
    );
  }

  Widget _buildSleepItem(
    SleepQuality sleep,
    String title,
    String desc,
    IconData icon,
  ) {
    final isSelected = viewModel.response.sleepQuality == sleep;
    final primaryColor = AppColors.primary;

    return AssessmentCard(
      isSelected: isSelected,
      onTap: () => viewModel.selectSleepQuality(sleep),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primaryColor.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: primaryColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.assessmentTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.assessmentTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? primaryColor : const Color(0xFFCBC3D7),
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: AnimatedScale(
                scale: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
