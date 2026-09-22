import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_colors.dart';
import '../../../widgets/app_cached_image.dart';
import '../../../viewmodels/home_viewmodel.dart';
import '../../../models/meditation_model.dart';
import '../../meditation/meditation_player_view.dart';

class ContinueLastSessionCard extends StatelessWidget {
  final HomeViewModel viewModel;

  const ContinueLastSessionCard({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    const session = MeditationSession(
      title: 'Deep Relaxation',
      description: 'Continue your deep relaxation practice.',
      durationLabel: '15 min',
      difficulty: 'Beginner',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBRghZU17Rv9_PgavmQexFu5J_uCrOG56xqF1E1_eYs9_XwV_M50RSG6vGS6AJdu8VrIGgwcSYkYTpAD-I13Kr7D0l22vhzIDgqsUPd1QbJPOQ2oMA6WQgx1l-lQP0dnKSWMHkQyiwFHmQXtqxUomk3peicOwvtgZIlDFilwKhfzWjFpLi74zBGeLUWuSItoMZ-M5H3GISE3WdbQFpIVfzu9YdVodp0urx0DnVVcAL2TkGDfRhBCEnZZw',
      instructorName: 'MindFlow Guide',
      instructorAvatars: [
        'https://lh3.googleusercontent.com/aida-public/AB6AXuBTgR1qoiieSJIp5ZrYmMjRRt3WM8aQpyinzqJ9SDSv23adUs2hGnad2QaSU1h77bZL1IEFpUy4IVrQGdZmUgG1RfwoGlom5FNpCBAMm3bz4W9sLMCS98vn1bUCO0w0IrrlaLe8TwzNHPuVltcSGzklG9GJXJs59RSd-fOkdu-D-Lzn8inJNDgytzFax6ClyIhpRhI3SdmEPga3GEcQiy-QuGw_avHhPzdGM6CEveA8VXOu6SgSG-Y5JA'
      ],
      categories: ['Mindfulness'],
    );

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const MeditationPlayerView(session: session),
          ),
        );
      },
      borderRadius: BorderRadius.circular(32),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F1FF),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          children: [
            AppCachedImage(
              imageUrl:
                  'https://nvouexmeevpdkfbspyer.supabase.co/storage/v1/object/public/medition/m2.png',
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(16),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONTINUE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.homeSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Deep Relaxation',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.assessmentTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Remaining: 12:45',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.assessmentTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      height: 5,
                      width: double.infinity,
                      color: const Color(0xFFE9DEF5),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: 0.33,
                        child: Container(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withAlpha(51),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
