import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_colors.dart';
import '../../../models/assessment_model.dart';
import '../../../viewmodels/assessment_viewmodel.dart';
import '../../../widgets/assessment_card.dart';

class StepStressOptions extends StatelessWidget {
  final AssessmentViewModel viewModel;

  const StepStressOptions({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildStressCard(
          StressLevel.low,
          'Low',
          'I feel calm, collected, and ready to take on the world.',
          Icons.sentiment_very_satisfied,
        ),
        _buildStressCard(
          StressLevel.medium,
          'Medium',
          "I have a few things on my mind, but I'm managing okay.",
          Icons.sentiment_satisfied,
        ),
        _buildStressCard(
          StressLevel.high,
          'High',
          "I'm feeling quite overwhelmed and finding it hard to focus.",
          Icons.sentiment_dissatisfied,
        ),
        _buildStressCard(
          StressLevel.veryHigh,
          'Very High',
          "I'm at a breaking point and need immediate relief strategies.",
          Icons.sentiment_very_dissatisfied,
        ),
      ],
    );
  }

  Widget _buildStressCard(
    StressLevel level,
    String title,
    String desc,
    IconData icon,
  ) {
    final isSelected = viewModel.response.stressLevel == level;
    final primaryColor = AppColors.primary;

    return AssessmentCard(
      isSelected: isSelected,
      onTap: () => viewModel.selectStressLevel(level),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9DEF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: primaryColor, size: 24),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.assessmentTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.assessmentTextSecondary,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isSelected)
            Positioned(
              top: 12,
              right: 12,
              child: Icon(
                Icons.check_circle,
                color: primaryColor,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}
