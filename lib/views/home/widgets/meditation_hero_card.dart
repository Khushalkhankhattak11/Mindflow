import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_colors.dart';
import '../../../widgets/app_cached_image.dart';
import '../../../widgets/scale_pressed_button.dart';
import '../../../viewmodels/home_viewmodel.dart';
import '../../breathing/breathing_exercise_view.dart';
import 'quick_start_sheet.dart';

class HeroExerciseItem {
  final String title;
  final String category;
  final String description;
  final String imageUrl;

  const HeroExerciseItem({
    required this.title,
    required this.category,
    required this.description,
    required this.imageUrl,
  });
}

class MeditationHeroCard extends StatefulWidget {
  final HomeViewModel viewModel;

  const MeditationHeroCard({super.key, required this.viewModel});

  @override
  State<MeditationHeroCard> createState() => _MeditationHeroCardState();
}

class _MeditationHeroCardState extends State<MeditationHeroCard> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoPlayTimer;

  static const List<HeroExerciseItem> _exercises = [
    HeroExerciseItem(
      title: 'Ocean Breathing',
      category: 'DAILY SELECTION',
      description: 'A 10-minute deep dive into rhythmic breathwork inspired by the tides of the Pacific.',
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=600&q=80',
    ),
    HeroExerciseItem(
      title: 'Forest Walk',
      category: 'GROUNDING',
      description: 'A grounding mindfulness session through whispering woods to connect with nature.',
      imageUrl: 'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=600&q=80',
    ),
    HeroExerciseItem(
      title: 'Mountain Calm',
      category: 'STILLNESS',
      description: 'Silent concentration session mimicking the majestic stillness of alpine peaks.',
      imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=600&q=80',
    ),
    HeroExerciseItem(
      title: 'Sunset Reflections',
      category: 'GRATITUDE',
      description: 'A gratitude-focused session to let go of daily stress and prepare for rest.',
      imageUrl: 'https://images.unsplash.com/photo-1500627869374-13ad9960a17f?auto=format&fit=crop&w=600&q=80',
    ),
    HeroExerciseItem(
      title: 'Zen Sand Mind',
      category: 'FOCUS',
      description: 'Focus your thoughts with sand-swept calmness and repetitive gentle pacing.',
      imageUrl: 'https://images.unsplash.com/photo-1542362567-b07eac790947?auto=format&fit=crop&w=600&q=80',
    ),
    HeroExerciseItem(
      title: 'Cosmic Expansion',
      category: 'TRANSCENDENCE',
      description: 'Expand your awareness with an infinite-sky perspective and cosmic breathing.',
      imageUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&w=600&q=80',
    ),
    HeroExerciseItem(
      title: 'Summer Rain Patterns',
      category: 'SENSORY RELAXATION',
      description: 'Deep sensory relaxation aligning your breathing to the rhythm of summer rain.',
      imageUrl: 'https://images.unsplash.com/photo-1534274988757-a28bf1a57c17?auto=format&fit=crop&w=600&q=80',
    ),
    HeroExerciseItem(
      title: 'Sunrise Energizer',
      category: 'MORNING FLOW',
      description: 'Reinvigorate your body and clear your mind to start your morning with positive energy.',
      imageUrl: 'https://images.unsplash.com/photo-1470252649378-9c29740c9fa8?auto=format&fit=crop&w=600&q=80',
    ),
    HeroExerciseItem(
      title: 'Deep Sleep Oasis',
      category: 'NIGHT COOLDOWN',
      description: 'Soothing and restorative breathing designed specifically to invite deep restful sleep.',
      imageUrl: 'https://images.unsplash.com/photo-1511295742364-927d44d602ae?auto=format&fit=crop&w=600&q=80',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _exercises.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 300,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: PageView.builder(
              controller: _pageController,
              itemCount: _exercises.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
                // Reset the auto-play timer on manual swiping to prevent immediate jumps
                _autoPlayTimer?.cancel();
                _startAutoPlay();
              },
              itemBuilder: (context, index) {
                final exercise = _exercises[index];
                return Stack(
                  children: [
                    // Background Image
                    Positioned.fill(
                      child: AppCachedImage(
                        imageUrl: exercise.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black.withAlpha(204), Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(51),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              exercise.category,
                              style: GoogleFonts.manrope(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            exercise.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            exercise.description,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: Colors.white.withAlpha(204),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Quick Start Button
        ScalePressedButton(
          onTap: () async {
            final activeExercise = _exercises[_currentPage];
            final config = await showModalBottomSheet<QuickStartConfig>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: QuickStartSheet(
                  viewModel: widget.viewModel,
                  initialImageTitle: activeExercise.title,
                ),
              ),
            );

            if (config != null && context.mounted) {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BreathingExerciseView(
                    exerciseTitle: activeExercise.title,
                    durationSeconds: config.durationSeconds,
                    backgroundImageUrl: config.backgroundImageUrl,
                    backgroundSound: config.backgroundSound,
                    soundEffect: config.soundEffect,
                    voiceGender: config.voiceGender,
                  ),
                ),
              );
            }
          },
          paddingVertical: 14,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF6B38D4), Color(0xFF8455EF)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8455EF).withAlpha(51),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_arrow_rounded, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                'Quick Start',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Centered indicator dots below outside card
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _exercises.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentPage == index ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: _currentPage == index
                    ? AppColors.primary
                    : AppColors.primary.withAlpha(51),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
