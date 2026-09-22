// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../models/meditation_model.dart';
import '../../viewmodels/meditation_viewmodel.dart';
import '../../widgets/app_cached_image.dart';
import 'meditation_player_view.dart';

class MeditateLibraryContent extends StatefulWidget {
  const MeditateLibraryContent({super.key});

  @override
  State<MeditateLibraryContent> createState() => _MeditateLibraryContentState();
}

class _MeditateLibraryContentState extends State<MeditateLibraryContent> {
  late final MeditateLibraryViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'For You',
    'Stress',
    'Sleep',
    'Focus',
    'Habit',
    'Morning',
    'Evening',
    'Anxiety',
  ];

  @override
  void initState() {
    super.initState();
    _viewModel = MeditateLibraryViewModel();
    _searchController.addListener(() {
      _viewModel.updateSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.primary;
    final secondaryTextColor = AppColors.assessmentTextSecondary;
    final outlineColor = AppColors.welcomeOutline;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final sessions = _viewModel.filteredSessions;
        final recommended = _viewModel.recommendedSessions;

        return Column(
          children: [
            // 1. Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F4).withAlpha(128),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: outlineColor.withAlpha(77),
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    color: AppColors.assessmentTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search meditations...',
                    hintStyle: GoogleFonts.manrope(
                      color: secondaryTextColor.withAlpha(128),
                    ),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: secondaryTextColor),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 2. Onboarding Personalization Banner
                        _buildOnboardingPersonalizedBanner(),
                        const SizedBox(height: 24),

                        // 3. Recommended Exercises Horizontal Carousel
                        if (recommended.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.auto_awesome_rounded,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Recommended For You',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.assessmentTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  _viewModel.selectCategory('For You');
                                },
                                child: Text(
                                  'See All',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 220,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: _viewModel.isLoadingAssessment ? 3 : recommended.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 14),
                              itemBuilder: (context, index) {
                                if (_viewModel.isLoadingAssessment) {
                                  return _buildRecommendedCardSkeleton();
                                }
                                final session = recommended[index];
                                return _buildRecommendedCard(session);
                              },
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],

                        // 4. Category Chips Horizontal Scroll
                        _buildCategoryChips(),
                        const SizedBox(height: 28),

                        // 5. Grid Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _viewModel.selectedCategory == 'All'
                                  ? 'All Meditations'
                                  : '${_viewModel.selectedCategory} Sessions',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.assessmentTextPrimary,
                              ),
                            ),
                            Text(
                              '${sessions.length} available',
                              style: GoogleFonts.manrope(
                                color: secondaryTextColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 6. Popular Meditations Responsive Grid
                        _viewModel.isLoadingAssessment
                            ? LayoutBuilder(
                                builder: (context, gridConstraints) {
                                  final cols =
                                      gridConstraints.maxWidth > 560 ? 2 : 1;
                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: 6,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: cols,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 0.95,
                                    ),
                                    itemBuilder: (context, index) =>
                                        _buildMeditationCardSkeleton(),
                                  );
                                },
                              )
                            : (sessions.isEmpty
                                ? _buildEmptyState()
                                : LayoutBuilder(
                                    builder: (context, gridConstraints) {
                                      final cols =
                                          gridConstraints.maxWidth > 560 ? 2 : 1;

                                      return GridView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: sessions.length,
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: cols,
                                          crossAxisSpacing: 16,
                                          mainAxisSpacing: 16,
                                          childAspectRatio: 0.95,
                                        ),
                                        itemBuilder: (context, index) {
                                          final session = sessions[index];
                                          return _buildMeditationCard(session);
                                        },
                                      );
                                    },
                                  )),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Personalized Onboarding Header Banner
  Widget _buildOnboardingPersonalizedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E0052), Color(0xFF6B38D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B38D4).withAlpha(64),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withAlpha(77),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_pin_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'MATCHED TO YOUR ONBOARDING PROFILE',
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.psychology_rounded,
                color: Colors.white70,
                size: 26,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Exercises Tailored For You',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Personalized sessions selected based on your onboarding answers:',
            style: GoogleFonts.manrope(
              fontSize: 13.5,
              color: Colors.white.withAlpha(217),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // User Onboarding Goal & Mood Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBadgeChip(
                icon: Icons.track_changes_rounded,
                label: 'Goal: ${_viewModel.onboardingGoalLabel}',
              ),
              _buildBadgeChip(
                icon: Icons.sentiment_satisfied_alt_rounded,
                label: 'Mood: ${_viewModel.onboardingFeelingLabel}',
              ),
              _buildBadgeChip(
                icon: Icons.timer_outlined,
                label: 'Pace: ${_viewModel.onboardingTimeLabel}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withAlpha(64),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Recommended Session Horizontal Card
  Widget _buildRecommendedCard(MeditationSession session) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MeditationPlayerView(session: session),
          ),
        );
      },
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFE9DEF5),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  AppCachedImage(
                    imageUrl: session.imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Matches Goal',
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(153),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        session.durationLabel,
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              session.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.assessmentTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              session.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppColors.assessmentTextSecondary,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Recommended Card Skeleton Loader matching exact card UI
  Widget _buildRecommendedCardSkeleton() {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE9DEF5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppShimmer(
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          const SizedBox(height: 10),
          AppShimmer(
            width: 140,
            height: 16,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 6),
          AppShimmer(
            width: 100,
            height: 12,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      ),
    );
  }

  // Meditation Card Skeleton Loader matching exact grid card UI
  Widget _buildMeditationCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFE9DEF5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppShimmer(
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 12),
          AppShimmer(
            width: 120,
            height: 16,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 6),
          AppShimmer(
            width: 80,
            height: 12,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      ),
    );
  }

  // Category chip slider list
  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _categories.map((category) {
          final isSelected = _viewModel.selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => _viewModel.selectCategory(category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.white.withAlpha(200),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : const Color(0xFFE9DEF5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppColors.primary.withAlpha(51)
                          : Colors.black.withAlpha(8),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (category == 'For You') ...[
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 14,
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      category,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : AppColors.assessmentTextPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Reusable meditation session card details
  Widget _buildMeditationCard(MeditationSession session) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MeditationPlayerView(session: session),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFE9DEF5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Graphic container
            Expanded(
              child: Stack(
                children: [
                  AppCachedImage(
                    imageUrl: session.imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  // Level Badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(128),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        session.difficulty,
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Favorite Heart icon
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(180),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () =>
                            _viewModel.toggleFavorite(session.title),
                        icon: Icon(
                          session.isFavorited
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: session.isFavorited
                              ? Colors.red
                              : Colors.black87,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  // Duration Label
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(153),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        session.durationLabel,
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Text(
              session.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.assessmentTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              session.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                color: AppColors.assessmentTextSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                if (session.instructorAvatars.isNotEmpty)
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: NetworkImage(session.instructorAvatars.first),
                  ),
                const SizedBox(width: 8),
                Text(
                  session.instructorName,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.assessmentTextSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(
            Icons.filter_list_off_rounded,
            size: 48,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Meditations Found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.assessmentTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try selecting a different category or clearing your search.',
            style: GoogleFonts.manrope(
              fontSize: 13.5,
              color: AppColors.assessmentTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
