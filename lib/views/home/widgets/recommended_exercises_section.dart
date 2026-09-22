import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_colors.dart';
import '../../../widgets/app_cached_image.dart';
import '../../../viewmodels/home_viewmodel.dart';
import '../../../models/meditation_model.dart';
import '../../../models/mood_exercise_model.dart';
import '../../meditation/meditation_player_view.dart';
import '../../subscription/subscription_view.dart';

class RecommendedExercisesSection extends StatelessWidget {
  final HomeViewModel viewModel;

  const RecommendedExercisesSection({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final activeFeeling = viewModel.data.activeFeeling;
    final recommendation = moodRecommendations[activeFeeling];
    if (recommendation == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recommended for you',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.assessmentTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Goal: ${recommendation.goal}',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.assessmentTextSecondary,
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recommendation.exercises.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final exercise = recommendation.exercises[index];
            final isLocked = index >= 2 && !viewModel.isPremium;
            return _buildRecommendedExerciseCard(context, exercise, isLocked);
          },
        ),
      ],
    );
  }

  Widget _buildRecommendedExerciseCard(
      BuildContext context, MoodExercise exercise, bool isLocked) {
    final primaryColor = AppColors.primary;

    // Build a mock MeditationSession to pass to MeditationPlayerView when tapped
    final mockSession = MeditationSession(
      title: exercise.title,
      description: 'A guided session customized for your current feeling: ${exercise.title}.',
      durationLabel: exercise.duration,
      difficulty: 'All Levels',
      imageUrl: 'https://nvouexmeevpdkfbspyer.supabase.co/storage/v1/object/public/medition/m1.png',
      instructorName: 'MindFlow Guide',
      instructorAvatars: const [
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=100&q=80',
      ],
      categories: const ['Mindfulness'],
    );

    return InkWell(
      onTap: () {
        if (isLocked) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SubscriptionView(viewModel: viewModel),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MeditationPlayerView(session: mockSession),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(32),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isLocked ? const Color(0xFFF5F3F7) : const Color(0xFFF9F1FF),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withAlpha(5),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Opacity(
              opacity: isLocked ? 0.6 : 1.0,
              child: AppCachedImage(
                imageUrl:
                    'https://nvouexmeevpdkfbspyer.supabase.co/storage/v1/object/public/medition/m1.png',
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECOMMENDED',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isLocked ? Colors.grey : AppColors.homeSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${exercise.emoji} ${exercise.title}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isLocked
                          ? AppColors.assessmentTextPrimary.withAlpha(128)
                          : AppColors.assessmentTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'Duration: ${exercise.duration}',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppColors.assessmentTextSecondary,
                        ),
                      ),
                      if (isLocked) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9E4ED),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '🔒 LOCKED',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ],
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
                        widthFactor: 0.1, // Simulated light progress start
                        child: Container(
                          color: isLocked ? Colors.grey : AppColors.primary,
                        ),
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
                  color: isLocked
                      ? Colors.grey.withAlpha(51)
                      : AppColors.primary.withAlpha(51),
                  width: 1.5,
                ),
              ),
              child: Icon(
                isLocked ? Icons.lock_outline_rounded : Icons.play_arrow_rounded,
                color: isLocked ? Colors.grey : AppColors.primary,
                size: isLocked ? 20 : 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
