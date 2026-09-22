// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../repositories/auth_repository.dart';
import '../../services/service_locator.dart';

class ProgressAnalyticsView extends StatefulWidget {
  const ProgressAnalyticsView({super.key});

  @override
  State<ProgressAnalyticsView> createState() => _ProgressAnalyticsViewState();
}

class _ProgressAnalyticsViewState extends State<ProgressAnalyticsView> {
  final AuthRepository _authRepository = locator<AuthRepository>();

  // Analytics mock / dynamic state
  final List<double> _weeklyMinutes = [15, 20, 10, 25, 30, 15, 40]; // Mon to Sun
  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final int _targetMinutes = 120; // 2 hours weekly goal

  int get totalMinutes => _weeklyMinutes.reduce((a, b) => a + b).toInt();
  double get weeklyProgress => (totalMinutes / _targetMinutes).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final userModel = _authRepository.currentUserModel;
    final dayStreak = userModel?.dayStreak ?? 3;

    return Scaffold(
      backgroundColor: AppColors.homeBg,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(context),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Weekly Goal Card
                        _buildWeeklyGoalCard(),
                        const SizedBox(height: 20),

                        // Weekly Activity Bar Chart
                        _buildWeeklyBarChartCard(),
                        const SizedBox(height: 20),

                        // Mood Distribution Card
                        _buildMoodDistributionCard(),
                        const SizedBox(height: 20),

                        // Milestone Badges Grid
                        _buildMilestonesCard(dayStreak),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(10),
              elevation: 2,
              shadowColor: Colors.black12,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mindfulness Analytics',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.assessmentTextPrimary,
                ),
              ),
              Text(
                'Track your stress reduction & session stats',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppColors.assessmentTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyGoalCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E0052), Color(0xFF6B38D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B38D4).withOpacity(0.25),
            blurRadius: 20,
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
              Text(
                'WEEKLY MINDFULNESS GOAL',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${(weeklyProgress * 100).toInt()}% Achieved',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$totalMinutes',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                ' / $_targetMinutes mins this week',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: weeklyProgress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBarChartCard() {
    final maxVal = _weeklyMinutes.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9DEF5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Practice Activity',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.assessmentTextPrimary,
                      ),
                    ),
                    Text(
                      'Minutes spent meditating per day',
                      style: GoogleFonts.manrope(
                        fontSize: 12.5,
                        color: AppColors.assessmentTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Bar chart
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_weeklyMinutes.length, (index) {
                final mins = _weeklyMinutes[index];
                final heightFactor = mins / maxVal;
                final isToday = index == DateTime.now().weekday - 1;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${mins.toInt()}m',
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isToday ? AppColors.primary : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 22,
                      height: 90 * heightFactor,
                      decoration: BoxDecoration(
                        color: isToday ? AppColors.primary : const Color(0xFFE0E0FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _weekDays[index],
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                        color: isToday ? AppColors.primary : AppColors.assessmentTextSecondary,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodDistributionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9DEF5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00ACC1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.pie_chart_outline_rounded,
                  color: Color(0xFF00ACC1),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Mood Distribution',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.assessmentTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildMoodProgressItem('Calm & Relaxed', 0.45, const Color(0xFF6F5092), '😌'),
          const SizedBox(height: 12),
          _buildMoodProgressItem('Happy & Motivated', 0.30, const Color(0xFF6B38D4), '😊'),
          const SizedBox(height: 12),
          _buildMoodProgressItem('Stressed / Anxious', 0.15, const Color(0xFF4E45D5), '😰'),
          const SizedBox(height: 12),
          _buildMoodProgressItem('Tired / Restless', 0.10, const Color(0xFF78909C), '😴'),
        ],
      ),
    );
  }

  Widget _buildMoodProgressItem(String label, double percent, Color color, String emoji) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.assessmentTextPrimary,
                  ),
                ),
              ],
            ),
            Text(
              '${(percent * 100).toInt()}%',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildMilestonesCard(int dayStreak) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9DEF5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFFF9800),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Milestone Badges',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.assessmentTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBadgeTile(
                icon: '🔥',
                title: '3-Day Streak',
                isUnlocked: dayStreak >= 3,
              ),
              _buildBadgeTile(
                icon: '🌟',
                title: '7-Day Warrior',
                isUnlocked: dayStreak >= 7,
              ),
              _buildBadgeTile(
                icon: '🧘',
                title: '100 Mins Club',
                isUnlocked: totalMinutes >= 100,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeTile({
    required String icon,
    required String title,
    required bool isUnlocked,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isUnlocked ? const Color(0xFFFFF3CD) : Colors.grey.shade100,
            border: Border.all(
              color: isUnlocked ? const Color(0xFFFFC107) : Colors.grey.shade300,
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            icon,
            style: TextStyle(
              fontSize: 26,
              color: isUnlocked ? null : Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: isUnlocked ? FontWeight.bold : FontWeight.w500,
            color: isUnlocked ? AppColors.assessmentTextPrimary : Colors.grey,
          ),
        ),
      ],
    );
  }
}
