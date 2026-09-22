import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_colors.dart';
import '../../../viewmodels/home_viewmodel.dart';
import '../../breathing/breathing_exercise_view.dart';

class QuickActionsRow extends StatelessWidget {
  final HomeViewModel viewModel;

  const QuickActionsRow({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildActionItem(context, 'Meditate', Icons.self_improvement),
          const SizedBox(width: 12),
          _buildActionItem(context, 'Sleep', Icons.bedtime_outlined),
          const SizedBox(width: 12),
          _buildActionItem(context, 'Breathing', Icons.air),
          const SizedBox(width: 12),
          _buildActionItem(context, 'Journal', Icons.edit_note),
        ],
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, String label, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4EAFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () {
          if (label == 'Breathing') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const BreathingExerciseView(),
              ),
            );
          } else if (label == 'Meditate') {
            viewModel.setActiveTab(1);
          } else if (label == 'Sleep') {
            viewModel.setActiveTab(2);
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.spa_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: AppColors.assessmentTextPrimary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
