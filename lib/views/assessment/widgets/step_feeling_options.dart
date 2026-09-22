import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_colors.dart';
import '../../../models/assessment_model.dart';
import '../../../viewmodels/assessment_viewmodel.dart';
import '../../../widgets/assessment_card.dart';

class StepFeelingOptions extends StatelessWidget {
  final AssessmentViewModel viewModel;

  const StepFeelingOptions({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFeelingRow(
          Feeling.happy, 'Happy', '😊', AppColors.feelingHappy,
          Feeling.calm, 'Calm', '😌', AppColors.feelingCalm,
        ),
        const SizedBox(height: 16),
        _buildFeelingRow(
          Feeling.stressed, 'Stressed', '😰', AppColors.feelingStressed,
          Feeling.sad, 'Sad', '😔', AppColors.feelingSad,
        ),
        const SizedBox(height: 16),
        _buildFeelingRow(
          Feeling.anxious, 'Anxious', '😟', AppColors.feelingAnxious,
          Feeling.angry, 'Angry', '😡', AppColors.feelingAngry,
        ),
        const SizedBox(height: 16),
        _buildFeelingRow(
          Feeling.tired, 'Tired', '😴', AppColors.feelingTired,
          Feeling.overwhelmed, 'Overwhelmed', '🤯', AppColors.feelingOverwhelmed,
        ),
        const SizedBox(height: 16),
        _buildFeelingRow(
          Feeling.motivated, 'Motivated', '🎯', AppColors.feelingMotivated,
          Feeling.grateful, 'Grateful', '❤️', AppColors.feelingGrateful,
        ),
        const SizedBox(height: 16),
        _buildFeelingRow(
          Feeling.distracted, 'Distracted', '😶', AppColors.feelingDistracted,
          Feeling.lonely, 'Lonely', '🤍', AppColors.feelingLonely,
        ),
      ],
    );
  }

  Widget _buildFeelingRow(
    Feeling f1, String l1, String e1, Color c1,
    Feeling f2, String l2, String e2, Color c2,
  ) {
    return Row(
      children: [
        Expanded(child: _buildFeelingCard(f1, l1, e1, c1)),
        const SizedBox(width: 16),
        Expanded(child: _buildFeelingCard(f2, l2, e2, c2)),
      ],
    );
  }

  Widget _buildFeelingCard(
    Feeling feeling,
    String label,
    String emoji,
    Color color,
  ) {
    final isSelected = viewModel.response.feeling == feeling;

    return AssessmentCard(
      isSelected: isSelected,
      onTap: () => viewModel.selectFeeling(feeling),
      child: Container(
        height: 90,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.assessmentTextPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
