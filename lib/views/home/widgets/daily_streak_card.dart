import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_colors.dart';
import '../../../viewmodels/home_viewmodel.dart';

class DailyStreakCard extends StatefulWidget {
  final HomeViewModel viewModel;

  const DailyStreakCard({super.key, required this.viewModel});

  @override
  State<DailyStreakCard> createState() => _DailyStreakCardState();
}

class _DailyStreakCardState extends State<DailyStreakCard> with SingleTickerProviderStateMixin {
  late final AnimationController _flameController;
  late final Animation<double> _flameFloat;

  @override
  void initState() {
    super.initState();
    _flameController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _flameFloat = Tween<double>(begin: 0.0, end: -10.0).animate(
      CurvedAnimation(parent: _flameController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(102),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withAlpha(77), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(10),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _flameController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _flameFloat.value),
                child: child,
              );
            },
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFEFDBFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: AppColors.primary,
                size: 38,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${widget.viewModel.data.streakDays} Days',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.assessmentTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Mindfulness Streak',
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: AppColors.assessmentTextSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.viewModel.data.streakHistory.length,
              (index) {
                final active = widget.viewModel.data.streakHistory[index];
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active
                        ? AppColors.primary
                        : AppColors.welcomeOutline,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
