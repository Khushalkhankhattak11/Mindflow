import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_colors.dart';
import '../../../viewmodels/home_viewmodel.dart';
import '../../progress/progress_view.dart';

class DailyProgressCard extends StatelessWidget {
  final HomeViewModel viewModel;

  const DailyProgressCard({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.primary;
    final progress = viewModel.data.dailyProgress;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ProgressView()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(102),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withAlpha(77), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withAlpha(10),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAILY PROGRESS',
                      style: GoogleFonts.plusJakartaSans(
                        color: primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '75% Mindful Today',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.assessmentTextPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        backgroundColor: const Color(0xFFE9DEF5),
                        color: primaryColor,
                        strokeWidth: 4.5,
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(
                  viewModel.data.chartData.length,
                  (index) {
                    final barVal = viewModel.data.chartData[index];
                    final isToday = index == 5;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeOutBack,
                                  height: barVal * constraints.maxHeight,
                                  decoration: BoxDecoration(
                                    color: isToday
                                        ? primaryColor
                                        : primaryColor.withAlpha(26),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "You're 15 minutes away from your daily goal. Keep going!",
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppColors.assessmentTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
