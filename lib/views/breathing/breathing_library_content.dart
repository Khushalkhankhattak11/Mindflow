// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../home/widgets/quick_start_sheet.dart';
import '../subscription/subscription_view.dart';
import '../../exercises/box_breathing.dart';
import '../../exercises/wave_animation.dart';
import '../../exercises/bubbles_animation.dart';
import '../../exercises/calm_breathing_animation.dart';
import '../../exercises/breath_cycle_animation.dart';
import 'breathing_exercise_view.dart';

class BreathingLibraryContent extends StatelessWidget {
  final HomeViewModel viewModel;

  const BreathingLibraryContent({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF4F55AE);
    const secondaryColor = Color(0xFF3A637C);

    final exercises = [
      _BreathingItem(
        title: 'Calm Breath',
        technique: '4-7-8 Technique',
        description:
            'Perfect for reducing anxiety and falling asleep. Inhale for 4s, hold for 7s, exhale for 8s.',
        duration: 300,
        icon: Icons.spa_outlined,
        color: primaryColor,
        bgImage:
            'https://images.unsplash.com/photo-1518241353330-0f7941c2d9b5?auto=format&fit=crop&w=600&q=80',
      ),
      _BreathingItem(
        title: 'Box Breathing',
        technique: 'Equal Intervals',
        description:
            'Used by navy seals for stress relief and extreme focus. Inhale, hold, exhale, hold for 4s each.',
        duration: 240,
        icon: Icons.grid_view_outlined,
        color: secondaryColor,
        bgImage:
            'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=600&q=80',
      ),
      _BreathingItem(
        title: 'Wave Breathing',
        technique: 'Ocean Flow',
        description:
            'Harmonize your breath with the flow of ocean waves. 5s Inhale, 5s Exhale.',
        duration: 300,
        icon: Icons.waves_rounded,
        color: const Color(0xFF00ACC1),
        bgImage:
            'https://images.unsplash.com/photo-1518837695005-2083093ee35b?auto=format&fit=crop&w=600&q=80',
      ),
      _BreathingItem(
        title: 'Bubble Breathing',
        technique: 'Rise and Fall',
        description:
            'Breathe in harmony with rising and sinking bubbles. 6s Inhale, 3s Hold, 6s Exhale.',
        duration: 240,
        icon: Icons.bubble_chart_outlined,
        color: const Color(0xFFE91E63),
        bgImage:
            'https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?auto=format&fit=crop&w=600&q=80',
      ),
      _BreathingItem(
        title: 'Awake Breath',
        technique: 'Bellows Breath',
        description:
            'Boost energy and mental alertness immediately. Rapid, rhythmic inhales and exhales.',
        duration: 180,
        icon: Icons.wb_sunny_outlined,
        color: const Color(0xFFE67E22),
        bgImage:
            'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=600&q=80',
      ),
      _BreathingItem(
        title: 'Cleansing Breath',
        technique: 'Sigh Release',
        description:
            'Instantly release accumulated stress. Double inhale followed by a long vocalized sigh.',
        duration: 120,
        icon: Icons.air_outlined,
        color: const Color(0xFF27AE60),
        bgImage:
            'https://images.unsplash.com/photo-1447752875215-b2761acb3c5d?auto=format&fit=crop&w=600&q=80',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Breathing Sanctuary',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1C1B1B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Harmonize your mind and body with breathing techniques',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    color: const Color(0xFF464652),
                  ),
                ),
                const SizedBox(height: 24),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: exercises.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = exercises[index];
                    final isLocked = (item.title != 'Calm Breath' && item.title != 'Box Breathing') && !viewModel.isPremium;

                    return GestureDetector(
                      onTap: () async {
                        if (isLocked) {
                          await showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => SizedBox(
                              height: MediaQuery.of(context).size.height * 0.85,
                              child: SubscriptionView(viewModel: viewModel),
                            ),
                          );
                          return;
                        }

                        final config =
                            await showModalBottomSheet<QuickStartConfig>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.75,
                                child: QuickStartSheet(
                                  viewModel: viewModel,
                                  initialImageTitle: item.title,
                                ),
                              ),
                            );

                        if (config != null && context.mounted) {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) {
                                if (item.title == 'Box Breathing') {
                                  return BoxBreathingScreen(
                                    durationSeconds: config.durationSeconds,
                                    backgroundImageUrl: config.backgroundImageUrl,
                                    backgroundSound: config.backgroundSound,
                                    voiceGender: config.voiceGender,
                                  );
                                } else if (item.title == 'Wave Breathing') {
                                  return WaveAnimationScreen(
                                    durationSeconds: config.durationSeconds,
                                    backgroundImageUrl: config.backgroundImageUrl,
                                    backgroundSound: config.backgroundSound,
                                    voiceGender: config.voiceGender,
                                  );
                                } else if (item.title == 'Bubble Breathing') {
                                  return BubbleBreathingScreen(
                                    durationSeconds: config.durationSeconds,
                                    backgroundImageUrl: config.backgroundImageUrl,
                                    backgroundSound: config.backgroundSound,
                                    voiceGender: config.voiceGender,
                                  );
                                } else if (item.title == 'Calm Breath') {
                                  return ClamBreathingScreen(
                                    durationSeconds: config.durationSeconds,
                                    backgroundImageUrl: config.backgroundImageUrl,
                                    backgroundSound: config.backgroundSound,
                                    voiceGender: config.voiceGender,
                                  );
                                } else if (item.title == 'Awake Breath' || item.title == 'Awake Breathe') {
                                  return BreathCyle(
                                    durationSeconds: config.durationSeconds,
                                    backgroundImageUrl: config.backgroundImageUrl,
                                    backgroundSound: config.backgroundSound,
                                    voiceGender: config.voiceGender,
                                  );
                                }
                                return BreathingExerciseView(
                                  exerciseTitle: item.title,
                                  durationSeconds: config.durationSeconds,
                                  backgroundImageUrl: config.backgroundImageUrl,
                                  backgroundSound: config.backgroundSound,
                                  soundEffect: config.soundEffect,
                                  voiceGender: config.voiceGender,
                                );
                              },
                            ),
                          );
                        }
                      },
                      child: Container(
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                            image: NetworkImage(item.bgImage),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(isLocked ? 0.75 : 0.55),
                              BlendMode.darken,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: item.color.withOpacity(0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item.technique,
                                      style: GoogleFonts.manrope(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.title,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.description,
                                    style: GoogleFonts.manrope(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.85),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isLocked ? Colors.white24 : Colors.white,
                                  ),
                                  child: Icon(
                                    isLocked ? Icons.lock_rounded : Icons.play_arrow_rounded,
                                    color: isLocked ? Colors.white70 : item.color,
                                    size: isLocked ? 20 : 28,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${item.duration ~/ 60} Min',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BreathingItem {
  final String title;
  final String technique;
  final String description;
  final int duration;
  final IconData icon;
  final Color color;
  final String bgImage;

  _BreathingItem({
    required this.title,
    required this.technique,
    required this.description,
    required this.duration,
    required this.icon,
    required this.color,
    required this.bgImage,
  });
}
