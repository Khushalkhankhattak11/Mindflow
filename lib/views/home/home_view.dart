// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/sleep_viewmodel.dart';
import '../meditation/meditate_library_content.dart';
import '../sleep/sleep_sounds_content.dart';
import '../profile/profile_content.dart';
import '../notifications/notifications_view.dart';
import '../breathing/breathing_library_content.dart';
import '../breathing/breathing_exercise_view.dart';
import '../../exercises/box_breathing.dart';
import '../../exercises/wave_animation.dart';
import '../../exercises/bubbles_animation.dart';
import '../../exercises/calm_breathing_animation.dart';
import '../../exercises/breath_cycle_animation.dart';
import '../meditation/meditation_player_view.dart';
import '../../models/meditation_model.dart';
import 'widgets/quick_start_sheet.dart';
import '../subscription/subscription_view.dart';
import '../../services/service_locator.dart';
import '../../repositories/auth_repository.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      locator<AuthRepository>().checkAndSyncSubscription();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFFCF9F8),
      body: Stack(
        children: [
          // Shifting Parallax Mesh Background
          const _ParallaxBackground(),

          Column(
            children: [
              // Top App Bar
              _buildTopAppBar(),

              // Content Area
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: _buildActiveTabContent(viewModel),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8E94F2).withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(viewModel, 0, Icons.home_rounded, 'Home'),
                  _buildNavItem(
                    viewModel,
                    1,
                    Icons.self_improvement_rounded,
                    'Meditate',
                  ),
                  _buildNavItem(viewModel, 2, Icons.air_rounded, 'Breathe'),
                  _buildNavItem(viewModel, 3, Icons.bedtime_rounded, 'Sleep'),
                  _buildNavItem(viewModel, 4, Icons.person_rounded, 'Profile'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF4F55AE).withOpacity(0.2),
                      width: 2,
                    ),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuAVg3LWd6HtkBJ-4ch5ZV-JovmUCfryNsglLtMTSr_wvarYRZd0TjqNFGrpcMMocR_IVRfwbqIcVBmKWLKIBABjwR15h3zvk10wXc7hGgy2nClgrAPud1Yxnvq8ulwMNbZ5XkVyTY7e788kN6_Rs9YvezcH23OutqyKVV0oIJJQcHwXxeRKvebZzf7APAR_7sF61xiQME84692eCXZostNMov2ljuDwtf46mxi6dCO8CrbsHFtN2RNWVQ',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Inhalo',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF4F55AE),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsView(),
                  ),
                );
              },
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF464652),
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(HomeViewModel viewModel) {
    switch (viewModel.activeTab) {
      case 0:
        return DashboardContent(viewModel: viewModel);
      case 1:
        return const MeditateLibraryContent();
      case 2:
        return BreathingLibraryContent(viewModel: viewModel);
      case 3:
        return SleepSoundsContent(homeViewModel: viewModel);
      case 4:
        return const ProfileContent();
      default:
        return DashboardContent(viewModel: viewModel);
    }
  }

  Widget _buildNavItem(HomeViewModel viewModel, int index, IconData icon, String label) {
    final isSelected = viewModel.activeTab == index;
    final activeColor = const Color(0xFF4F55AE);

    return GestureDetector(
      onTap: () => viewModel.setActiveTab(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : const Color(0xFF464652),
          size: 24,
        ),
      ),
    );
  }
}

// Parallax Decorative Background Elements
class _ParallaxBackground extends StatelessWidget {
  const _ParallaxBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -96,
          left: -96,
          child: Container(
            width: 384,
            height: 384,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF8E94F2).withOpacity(0.12),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          right: -96,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFB6DFFD).withOpacity(0.12),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
      ],
    );
  }
}

// Bento Dashboard Content (Tab 0)
class DashboardContent extends StatelessWidget {
  final HomeViewModel viewModel;

  const DashboardContent({super.key, required this.viewModel});

  void _openQuickStartSheet(BuildContext context, String exerciseTitle) async {
    final config = await showModalBottomSheet<QuickStartConfig>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: QuickStartSheet(
          viewModel: viewModel,
          initialImageTitle: exerciseTitle,
        ),
      ),
    );

    if (config != null && context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            if (exerciseTitle == 'Box Breathing') {
              return BoxBreathingScreen(
                durationSeconds: config.durationSeconds,
                backgroundImageUrl: config.backgroundImageUrl,
                backgroundSound: config.backgroundSound,
                voiceGender: config.voiceGender,
              );
            } else if (exerciseTitle == 'Wave Breathing') {
              return WaveAnimationScreen(
                durationSeconds: config.durationSeconds,
                backgroundImageUrl: config.backgroundImageUrl,
                backgroundSound: config.backgroundSound,
                voiceGender: config.voiceGender,
              );
            } else if (exerciseTitle == 'Bubble Breathing') {
              return BubbleBreathingScreen(
                durationSeconds: config.durationSeconds,
                backgroundImageUrl: config.backgroundImageUrl,
                backgroundSound: config.backgroundSound,
                voiceGender: config.voiceGender,
              );
            } else if (exerciseTitle == 'Calm Breath' || exerciseTitle == 'Clam Breathing') {
              return ClamBreathingScreen(
                durationSeconds: config.durationSeconds,
                backgroundImageUrl: config.backgroundImageUrl,
                backgroundSound: config.backgroundSound,
                voiceGender: config.voiceGender,
              );
            } else if (exerciseTitle == 'Awake Breath' || exerciseTitle == 'Awake Breathe') {
              return BreathCyle(
                durationSeconds: config.durationSeconds,
                backgroundImageUrl: config.backgroundImageUrl,
                backgroundSound: config.backgroundSound,
                voiceGender: config.voiceGender,
              );
            }
            return BreathingExerciseView(
              exerciseTitle: exerciseTitle,
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
  }

  @override
  Widget build(BuildContext context) {
    final userName = viewModel.data.userName;
    final activeFeeling = viewModel.data.activeFeeling;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 120),
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Header
              Text(
                '${viewModel.timeOfDayGreeting}, $userName 🌿',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1C1B1B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'How are you feeling today?',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  color: const Color(0xFF464652),
                ),
              ),
              const SizedBox(height: 20),

              // Mood Tracker Row
              _buildMoodTracker(),
              const SizedBox(height: 24),

              // Stats Row
              _buildStatsRow(),
              const SizedBox(height: 24),

              // Continue Last Session Lotus Card
              _buildContinueSessionCard(context),
              const SizedBox(height: 24),

              // AI Wellness Coach
              _buildAICoachCard(context, activeFeeling),
              const SizedBox(height: 24),

              // Daily Quote
              _buildDailyQuoteCard(),
              const SizedBox(height: 24),

              // Breathing Exercises
              _buildBreathingSection(context),
              const SizedBox(height: 24),

              // Sleep Sounds
              _buildSleepSoundsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodTracker() {
    final feelings = [
      {'emoji': '😊', 'label': 'Happy', 'key': 'happy'},
      {'emoji': '😌', 'label': 'Calm', 'key': 'calm'},
      {'emoji': '😔', 'label': 'Sad', 'key': 'sad'},
      {'emoji': '⚡', 'label': 'Anxious', 'key': 'anxious'},
      {'emoji': '😴', 'label': 'Tired', 'key': 'tired'},
    ];

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: feelings.length,
        itemBuilder: (context, index) {
          final feeling = feelings[index];
          final isSelected = viewModel.data.activeFeeling == feeling['key'];
          final activeColor = const Color(0xFF4F55AE);

          return GestureDetector(
            onTap: () => viewModel.selectFeeling(feeling['key']!),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 72,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? const Color(0xFFE0E0FF)
                          : const Color(0xFFF0EDED),
                      border: Border.all(
                        color: isSelected ? activeColor : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: activeColor.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      feeling['emoji']!,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    feeling['label']!,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected ? activeColor : const Color(0xFF464652),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsRow() {
    final streakDays = viewModel.data.streakDays;
    final wellnessPercent = (viewModel.data.dailyProgress * 100).toInt();

    return Row(
      children: [
        // Streak Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF3CD),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text('🔥', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STREAK',
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF464652),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '$streakDays Days',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1C1B1B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Wellness Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: viewModel.data.dailyProgress,
                        strokeWidth: 4,
                        backgroundColor: const Color(0xFFE5E2E1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF4F55AE),
                        ),
                      ),
                      Text(
                        '$wellnessPercent%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1C1B1B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WELLNESS',
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF464652),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Today',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1C1B1B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueSessionCard(BuildContext context) {
    const session = MeditationSession(
      title: 'Morning Calm Meditation',
      description: 'Continue your deep relaxation practice.',
      durationLabel: '15 min',
      difficulty: 'Beginner',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBc5qLKQ3bkpgdCOVC1yNHAu9LFwfHUacyG5JNUYSJI2lZf2dZenzaKvkZ7qdR7f2iHgii1prKkiY2ozekNU-oq26GXVTq-fmo4MLhxpRhQG8WIwTabIKdUeCB3UboozYZ5AFAC8VPga5I0fc2FSFmqZ0u5Mtp0rwTa54a9IqxVMqIXkISBlIIxGU6SeB--rojBh3Z1_cpyIIbMNXZLsrO-8Tj-CWKmA_D4nNVC_ZNYGIKkWpCN7YvQyA',
      instructorName: 'MindFlow Guide',
      instructorAvatars: [],
      categories: ['Mindfulness'],
    );

    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: NetworkImage(session.imageUrl),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Continue Session',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        session.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '12:45 remaining',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            const MeditationPlayerView(session: session),
                      ),
                    );
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Color(0xFF4F55AE),
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAICoachCard(BuildContext context, String activeFeeling) {
    String moodQuote = 'You seem slightly stressed today.';
    if (activeFeeling == 'happy') {
      moodQuote = 'You seem happy and energized today!';
    } else if (activeFeeling == 'calm') {
      moodQuote = 'You feel relaxed and centered.';
    } else if (activeFeeling == 'sad') {
      moodQuote = 'You feel a bit low today.';
    } else if (activeFeeling == 'anxious') {
      moodQuote = 'You seem slightly anxious today.';
    } else if (activeFeeling == 'tired') {
      moodQuote = 'You seem tired today.';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'AI Wellness Coach ✨',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1C1B1B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"Based on your mood: $moodQuote"',
            style: GoogleFonts.manrope(
              fontSize: 16,
              color: const Color(0xFF464652),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          _buildAICoachActionItem(context, '🌿', '5 min Calm Breathing', () {
            _openQuickStartSheet(context, 'Calm Breath');
          }),
          const SizedBox(height: 8),
          _buildAICoachActionItem(context, '🎧', 'Relaxing Forest Sounds', () {
            viewModel.setActiveTab(3); // Navigate to Sleep sounds tab
          }),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => _openQuickStartSheet(context, 'Calm Breath'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F55AE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: Text(
                'Start Now',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAICoachActionItem(
    BuildContext context,
    String icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF4F55AE).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C1B1B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyQuoteCard() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: NetworkImage(
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDLhixycYLX4rvsg3gs33tQPGWfFs-agdhMAZ3yiXuxkIykoTkB6zADdAVSQ0rTLCSVhc6gS-Zdwkl9oNW2_tO8uF4eMrUo5PCD7lW790_5_nkKDcifNe1K3Iet9PrM1qG4zijt00T_D_hnaxvTtn2YkneGuwtCYyfvtdng_183jErpLCkD5LZRo5sriOkI-d37bBGsn5TWqR6JCCH8avn_-D3sNAVriRTptZ5HHe8DUbkCYyZsLA0fHg',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withOpacity(0.75),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '"Your mind deserves moments of peace."',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4F55AE),
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '— Daily Inspiration',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF464652),
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreathingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Breathing Exercises',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1C1B1B),
              ),
            ),
            TextButton(
              onPressed: () {
                viewModel.setActiveTab(2); // Navigate to Breathe tab
              },
              child: Text(
                'View All',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4F55AE),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildExerciseCard(
                context,
                title: 'Calm Breath',
                subtitle: '4-7-8 Technique',
                color: const Color(0xFF4F55AE),
                animation: const _BreathingCircleAnimation(),
              ),
              const SizedBox(width: 16),
              _buildExerciseCard(
                context,
                title: 'Box Breathing',
                subtitle: 'Equal Intervals',
                color: const Color(0xFF3A637C),
                animation: const _RotatingDiamondAnimation(),
              ),
              const SizedBox(width: 16),
              _buildExerciseCard(
                context,
                title: 'Wave Breathing',
                subtitle: 'Ocean Flow',
                color: const Color(0xFF00ACC1),
                animation: const _WaveLineAnimation(),
              ),
              const SizedBox(width: 16),
              _buildExerciseCard(
                context,
                title: 'Bubble Breathing',
                subtitle: 'Rise and Fall',
                color: const Color(0xFFE91E63),
                animation: const _MultiBubblesAnimation(),
              ),
              const SizedBox(width: 16),
              _buildExerciseCard(
                context,
                title: 'Awake Breath',
                subtitle: 'Bellows Breath',
                color: const Color(0xFFE67E22),
                animation: const _PulsingSunAnimation(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSubscriptionView(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: SubscriptionView(viewModel: viewModel),
      ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color color,
    required Widget animation,
  }) {
    final isLocked = (title != 'Calm Breath' && title != 'Box Breathing') && !viewModel.isPremium;

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          _showSubscriptionView(context);
        } else {
          _openQuickStartSheet(context, title);
        }
      },
      child: Stack(
        children: [
          Container(
            width: 160,
            padding: const EdgeInsets.all(16),
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: isLocked ? 0.3 : 1.0,
                  child: animation,
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isLocked ? Colors.grey : color,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: const Color(0xFF464652),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isLocked)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSleepSoundsSection(BuildContext context) {
    final soundscapes = SleepSoundsViewModel.defaultSoundscapes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sleep Sounds',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1C1B1B),
              ),
            ),
            TextButton(
              onPressed: () {
                viewModel.setActiveTab(3); // Navigate to Sleep sounds tab
              },
              child: Text(
                'Explore',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4F55AE),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: soundscapes.length,
            itemBuilder: (context, index) {
              final item = soundscapes[index];
              final isLocked = index >= 2 && !viewModel.isPremium;

              return GestureDetector(
                onTap: () {
                  if (isLocked) {
                    showModalBottomSheet(
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
                  // Set pre-selected sound and navigate to Sleep Sounds tab
                  viewModel.selectedSleepSoundTitle = item.title;
                  viewModel.setActiveTab(3);
                },
                child: Container(
                  width: 280,
                  margin: EdgeInsets.only(right: index == soundscapes.length - 1 ? 0 : 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage(item.bgImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: isLocked 
                              ? Colors.black.withOpacity(0.6) 
                              : Colors.black.withOpacity(0.3),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.subtitle,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isLocked)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Breating Circle Animation Widget for Calm Breath Card
class _BreathingCircleAnimation extends StatefulWidget {
  const _BreathingCircleAnimation();

  @override
  State<_BreathingCircleAnimation> createState() =>
      _BreathingCircleAnimationState();
}

class _BreathingCircleAnimationState extends State<_BreathingCircleAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _scale = Tween<double>(
      begin: 0.8,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF4F55AE).withOpacity(0.2),
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(scale: _scale.value, child: child);
        },
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF4F55AE).withOpacity(0.4),
          ),
        ),
      ),
    );
  }
}

// Rotating Diamond Animation Widget for Box Breathing Card
class _RotatingDiamondAnimation extends StatefulWidget {
  const _RotatingDiamondAnimation();

  @override
  State<_RotatingDiamondAnimation> createState() =>
      _RotatingDiamondAnimationState();
}

class _RotatingDiamondAnimationState extends State<_RotatingDiamondAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _rotation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: AnimatedBuilder(
        animation: _rotation,
        builder: (context, child) {
          return Transform.rotate(angle: _rotation.value, child: child);
        },
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF3A637C), width: 3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

// Mini Wave Line Animation Widget for Wave Breathing Card
class _WaveLineAnimation extends StatefulWidget {
  const _WaveLineAnimation();

  @override
  State<_WaveLineAnimation> createState() => _WaveLineAnimationState();
}

class _WaveLineAnimationState extends State<_WaveLineAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _MiniWavePainter(_controller.value),
          );
        },
      ),
    );
  }
}

class _MiniWavePainter extends CustomPainter {
  final double value;

  _MiniWavePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00ACC1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final h = size.height;
    final w = size.width;

    path.moveTo(0, h / 2);
    for (double x = 0; x <= w; x += 1) {
      final y = h / 2 + math.sin((x / w * 2 * math.pi) + (value * 2 * math.pi)) * 10;
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MiniWavePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

// Mini Rising Bubbles Animation Widget for Bubble Breathing Card
class _MultiBubblesAnimation extends StatefulWidget {
  const _MultiBubblesAnimation();

  @override
  State<_MultiBubblesAnimation> createState() => _MultiBubblesAnimationState();
}

class _MultiBubblesAnimationState extends State<_MultiBubblesAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          return Stack(
            children: List.generate(3, (index) {
              final progress = (t + index / 3.0) % 1.0;
              final y = 48.0 - (progress * 38.0);
              final x = 32.0 + math.sin(progress * 2 * math.pi) * 8.0;
              final size = (1.0 - progress) * 10.0 + 4.0;
              final opacity = 1.0 - progress;

              return Positioned(
                left: x - size / 2,
                top: y - size / 2,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE91E63).withOpacity(0.3),
                      border: Border.all(color: const Color(0xFFE91E63), width: 1.5),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// Mini Pulsing Sun Animation Widget for Awake Breath Card
class _PulsingSunAnimation extends StatefulWidget {
  const _PulsingSunAnimation();

  @override
  State<_PulsingSunAnimation> createState() => _PulsingSunAnimationState();
}

class _PulsingSunAnimationState extends State<_PulsingSunAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Center(
        child: ScaleTransition(
          scale: _scale,
          child: const Icon(
            Icons.wb_sunny_rounded,
            color: Color(0xFFE67E22),
            size: 34,
          ),
        ),
      ),
    );
  }
}
