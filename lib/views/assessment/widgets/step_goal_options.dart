import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_colors.dart';
import '../../../models/assessment_model.dart';
import '../../../viewmodels/assessment_viewmodel.dart';
import '../../../widgets/assessment_card.dart';

class StepGoalOptions extends StatelessWidget {
  final AssessmentViewModel viewModel;

  const StepGoalOptions({super.key, required this.viewModel});

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
        _buildGoalCard(
          MindGoal.reduceStress,
          'Reduce Stress',
          'Quiet your mind and find moments of peace throughout the day.',
          Icons.spa_outlined,
        ),
        _buildGoalCard(
          MindGoal.sleepBetter,
          'Sleep Better',
          'Fall asleep faster and improve your deep sleep quality.',
          Icons.nights_stay_outlined,
        ),
        _buildGoalCard(
          MindGoal.focusMore,
          'Increase Focus',
          'Improve concentration and mental clarity in your daily activities.',
          Icons.psychology_outlined,
        ),
        _buildGoalCard(
          MindGoal.buildHabit,
          'Build Habits',
          'Integrate positive habits and mindfulness into your routine.',
          Icons.repeat,
        ),
      ],
    );
  }

  Widget _buildGoalCard(
    MindGoal goal,
    String title,
    String desc,
    IconData icon,
  ) {
    final isSelected = viewModel.response.goal == goal;
    final primaryColor = AppColors.primary;

    return AssessmentCard(
      isSelected: isSelected,
      onTap: () => viewModel.selectGoal(goal),
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
