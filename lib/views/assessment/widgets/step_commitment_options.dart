import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_colors.dart';
import '../../../models/assessment_model.dart';
import '../../../viewmodels/assessment_viewmodel.dart';
import '../../../widgets/assessment_card.dart';

class StepCommitmentOptions extends StatelessWidget {
  final AssessmentViewModel viewModel;

  const StepCommitmentOptions({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.0,
      children: [
        _buildCommitmentCard(
          CommitmentTime.threeMin,
          '⏱ 3 Minutes',
          'Perfect for busy days',
        ),
        _buildCommitmentCard(
          CommitmentTime.fiveMin,
          '⏱ 5 Minutes',
          'A quick daily reset',
        ),
        _buildCommitmentCard(
          CommitmentTime.tenMin,
          '⏱ 10 Minutes',
          'Build a healthy habit',
          isRecommended: true,
        ),
        _buildCommitmentCard(
          CommitmentTime.fifteenMin,
          '⏱ 15 Minutes',
          'Deeper relaxation',
        ),
        _buildCommitmentCard(
          CommitmentTime.twentyMin,
          '⏱ 20 Minutes',
          'A complete mindfulness session',
        ),
        _buildCommitmentCard(
          CommitmentTime.thirtyPlusMin,
          '⏱ 30 Minutes',
          'An immersive meditation practice',
        ),
      ],
    );
  }

  Widget _buildCommitmentCard(
    CommitmentTime time,
    String title,
    String desc, {
    bool isRecommended = false,
  }) {
    final isSelected = viewModel.response.commitment == time;
    final primaryColor = AppColors.primary;

    return AssessmentCard(
      isSelected: isSelected,
      onTap: () => viewModel.selectCommitment(time),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isRecommended) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withAlpha(38),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '⭐ Recommended',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB28F00),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 6),
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
