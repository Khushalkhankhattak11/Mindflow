// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../constants/app_colors.dart';
import '../../subscription/subscription_view.dart';
import '../../../viewmodels/home_viewmodel.dart';

class QuickStartConfig {
  final int durationSeconds;
  final String backgroundImageUrl;
  final String backgroundImageTitle;
  final String backgroundSound;
  final String
  soundEffect; // In this design, represents breathing Animation type
  final String voiceGender; // In this design, represents Guide Voice name

  const QuickStartConfig({
    required this.durationSeconds,
    required this.backgroundImageUrl,
    required this.backgroundImageTitle,
    required this.backgroundSound,
    required this.soundEffect,
    required this.voiceGender,
  });
}

class ImageOption {
  final String title;
  final String imageUrl;

  const ImageOption({required this.title, required this.imageUrl});
}

class QuickStartSheet extends StatefulWidget {
  final String initialImageTitle;
  final HomeViewModel viewModel;

  const QuickStartSheet({
    super.key,
    required this.viewModel,
    this.initialImageTitle = 'Ocean Breathing',
  });

  @override
  State<QuickStartSheet> createState() => _QuickStartSheetState();
}

class _QuickStartSheetState extends State<QuickStartSheet>
    with TickerProviderStateMixin {
  // Pre-configured background images
  static const List<ImageOption> _images = [
    ImageOption(
      title: 'Floral',
      imageUrl:
          'https://images.unsplash.com/photo-1526047932273-341f2a7631f9?auto=format&fit=crop&w=300&q=80',
    ),
    ImageOption(
      title: 'Dandelion Field',
      imageUrl:
          'https://images.unsplash.com/photo-1538998073820-4dfa76300194?q=80&w=987&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
    ),
    ImageOption(
      title: 'Deep Forest',
      imageUrl:
          'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=300&q=80',
    ),
    ImageOption(
      title: 'Ocean',
      imageUrl:
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=300&q=80',
    ),
    ImageOption(
      title: 'Cosmic',
      imageUrl:
          'https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&w=300&q=80',
    ),
    ImageOption(title: 'Lotus Night', imageUrl: 'animated_lotus_night'),
  ];

  // Options
  static const List<String> _bgSounds = [
    'Rain',
    'Wind',
    'Breeze',
    'Beach',
    'Fire',
  ];
  // ignore: unused_field
  static const List<String> _animations = [
    '4 Bubbles',
    'Bubbles',
    'Line Heart',
    'Orbit',
  ];
  static const List<String> _voices = [
    'Warm',
    'Clear',
    'Deep',
    'Whisper',
    'Soft',
  ];

  // Current selections
  int _selectedDuration = 180; // default 3 min (index 2)
  late ImageOption _selectedImage;
  String _selectedBgSound = 'Rain';
  final String _selectedAnimation = 'Bubbles';
  String _selectedVoice = 'Warm';

  // Controllers
  late final PageController _timePageController;
  late final AnimationController _animationController;
  late final AnimationController _pulseController;
  late final AudioPlayer _audioPlayer;

  void _showSubscriptionView() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubscriptionView(viewModel: widget.viewModel),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Try to match active hero card title to pre-select image
    final normalizedInitial = widget.initialImageTitle.toLowerCase();
    _selectedImage = _images.firstWhere((img) {
      if (!normalizedInitial.contains(img.title.toLowerCase())) return false;
      final index = _images.indexOf(img);
      if (index >= 2 && !widget.viewModel.isPremium) return false;
      return true;
    }, orElse: () => _images.first);

    // Initial page set to index 2 (3 min)
    _timePageController = PageController(
      initialPage: 2,
      viewportFraction: 0.22,
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _timePageController.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onSoundSelected(String sound, bool isLocked) async {
    if (isLocked) {
      _showSubscriptionView();
      return;
    }
    setState(() {
      _selectedBgSound = sound;
    });
  }

  // Map sound labels to icons
  IconData _getSoundIcon(String sound) {
    switch (sound) {
      case 'Rain':
        return Icons.umbrella_rounded;
      case 'Wind':
        return Icons.air_rounded;
      case 'Breeze':
        return Icons.waves_rounded;
      case 'Beach':
        return Icons.beach_access_rounded;
      case 'Fire':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.music_note_rounded;
    }
  }

  // Map voice labels to icons
  IconData _getVoiceIcon(String voice) {
    switch (voice) {
      case 'Warm':
        return Icons.sentiment_satisfied_rounded;
      case 'Clear':
        return Icons.face_rounded;
      case 'Deep':
        return Icons.sentiment_very_satisfied_rounded;
      case 'Whisper':
        return Icons.child_care_rounded;
      case 'Soft':
        return Icons.sentiment_satisfied_alt_rounded;
      default:
        return Icons.face_rounded;
    }
  }

  Widget _buildAnimatedSection({required int index, required Widget child}) {
    final start = index * 0.08;
    final end = (start + 0.4).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1.0 - animation.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    const textColor = AppColors.assessmentTextPrimary;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        top: 8,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          _buildAnimatedSection(
            index: 0,
            child: Text(
              'Exercise Settings',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),

          // Main scrollable sheet body
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Time Selection Horizontal Wheel
                  _buildAnimatedSection(
                    index: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            'Time',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 90,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Active center Chevron Down
                              const Positioned(
                                top: 4,
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              PageView.builder(
                                controller: _timePageController,
                                itemCount: 30, // 1 to 30 min
                                onPageChanged: (page) {
                                  setState(() {
                                    _selectedDuration = (page + 1) * 60;
                                  });
                                },
                                itemBuilder: (context, index) {
                                  final minVal = index + 1;
                                  final isSelected =
                                      (_selectedDuration ~/ 60) == minVal;
                                  return AnimatedScale(
                                    scale: isSelected ? 1.0 : 0.8,
                                    duration: const Duration(milliseconds: 200),
                                    child: Center(
                                      child: Text(
                                        minVal.toString().padLeft(2, '0'),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: isSelected ? 34 : 22,
                                          fontWeight: isSelected
                                              ? FontWeight.w900
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // active 'min' label at the bottom
                              Positioned(
                                bottom: 2,
                                child: Text(
                                  'min',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 2. Sound Selection Row
                        _buildAnimatedSection(
                          index: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeaderRow('Sound'),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: _bgSounds.asMap().entries.map((
                                  entry,
                                ) {
                                  final index = entry.key;
                                  final sound = entry.value;
                                  final isSelected = _selectedBgSound == sound;
                                  final isLocked =
                                      index >= 2 && !widget.viewModel.isPremium;
                                  return _buildCircularOption(
                                    label: sound,
                                    icon: _getSoundIcon(sound),
                                    isSelected: isSelected,
                                    isLocked: isLocked,
                                    onTap: () =>
                                        _onSoundSelected(sound, isLocked),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 3. Background Section Row
                        _buildAnimatedSection(
                          index: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeaderRow('Background'),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 172,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _images.length,
                                  itemBuilder: (context, index) {
                                    final img = _images[index];
                                    final isSelected =
                                        _selectedImage.title == img.title;
                                    final isLocked =
                                        index >= 2 &&
                                        !widget.viewModel.isPremium;
                                    return _buildBackgroundCard(
                                      img: img,
                                      isSelected: isSelected,
                                      isLocked: isLocked,
                                      onTap: () {
                                        if (isLocked) {
                                          _showSubscriptionView();
                                        } else {
                                          setState(() => _selectedImage = img);
                                        }
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 4. Animation Selection Row
                        /*
                  _buildAnimatedSection(
                    index: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderRow('Animation'),
                        const SizedBox(height: 12),
                        Row(
                          children: _animations.asMap().entries.map((entry) {
                            final index = entry.key;
                            final anim = entry.value;
                            final isSelected = _selectedAnimation == anim;
                            final isLocked = index >= 2 && !widget.viewModel.isPremium;
                            return Expanded(
                              child: _buildAnimationCard(
                                label: anim,
                                preview: _getAnimationPreviewWidget(
                                  anim,
                                  isSelected,
                                ),
                                isSelected: isSelected,
                                isLocked: isLocked,
                                onTap: () {
                                  if (isLocked) {
                                    _showSubscriptionView();
                                  } else {
                                    setState(() => _selectedAnimation = anim);
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  */

                        // 5. Guide Voice Row
                        _buildAnimatedSection(
                          index: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeaderRow('Guide Voice'),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: _voices.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final voice = entry.value;
                                  final isSelected = _selectedVoice == voice;
                                  final isLocked =
                                      index >= 2 && !widget.viewModel.isPremium;
                                  return _buildCircularOption(
                                    label: voice,
                                    icon: _getVoiceIcon(voice),
                                    isSelected: isSelected,
                                    isLocked: isLocked,
                                    onTap: () {
                                      if (isLocked) {
                                        _showSubscriptionView();
                                      } else {
                                        setState(() => _selectedVoice = voice);
                                      }
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Start Session Button
                  _buildAnimatedSection(
                    index: 6,
                    child: GestureDetector(
                      onTap: () async {
                        final isImageLocked =
                            _images.indexOf(_selectedImage) >= 2 &&
                            !widget.viewModel.isPremium;
                        final isSoundLocked =
                            _bgSounds.indexOf(_selectedBgSound) >= 2 &&
                            !widget.viewModel.isPremium;
                        final isVoiceLocked =
                            _voices.indexOf(_selectedVoice) >= 2 &&
                            !widget.viewModel.isPremium;

                        if (isImageLocked || isSoundLocked || isVoiceLocked) {
                          _showSubscriptionView();
                          return;
                        }

                        try {
                          await _audioPlayer.stop();
                        } catch (e) {
                          debugPrint('Error stopping preview: $e');
                        }
                        if (context.mounted) {
                          Navigator.pop(
                            context,
                            QuickStartConfig(
                              durationSeconds: _selectedDuration,
                              backgroundImageUrl: _selectedImage.imageUrl,
                              backgroundImageTitle: _selectedImage.title,
                              backgroundSound: _selectedBgSound,
                              soundEffect: _selectedAnimation,
                              voiceGender: _selectedVoice,
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                        alignment: Alignment.center,
                        child: Text(
                          'Start Session',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
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

  Widget _buildHeaderRow(String title, [bool showAnimatedBg = false]) {
    final textColor = showAnimatedBg
        ? Colors.white
        : AppColors.assessmentTextPrimary;
    final secondaryTextColor = showAnimatedBg
        ? Colors.white70
        : AppColors.assessmentTextSecondary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        // Preview button matching screenshot
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: showAnimatedBg
                ? Colors.white.withOpacity(0.08)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: showAnimatedBg
                  ? Colors.white.withOpacity(0.12)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Preview',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.play_circle_fill_rounded,
                color: showAnimatedBg ? Colors.white : AppColors.primary,
                size: 14,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCircularOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    bool isLocked = false,
    bool showAnimatedBg = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Colors.transparent
                      : (showAnimatedBg
                            ? Colors.white.withOpacity(0.08)
                            : Colors.grey.shade100),
                  border: Border.all(
                    color: isSelected
                        ? (showAnimatedBg ? Colors.white : AppColors.primary)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(2), // Active Border spacing
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? (showAnimatedBg
                              ? Colors.white.withOpacity(0.2)
                              : AppColors.primary.withAlpha(26))
                        : (showAnimatedBg
                              ? Colors.white.withOpacity(0.08)
                              : Colors.grey.shade100),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? (showAnimatedBg ? Colors.white : AppColors.primary)
                        : (isLocked
                              ? Colors.grey.shade400
                              : (showAnimatedBg
                                    ? Colors.white70
                                    : Colors.grey.shade700)),
                    size: 22,
                  ),
                ),
              ),
              if (isLocked)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    child: const Icon(Icons.lock, color: Colors.grey, size: 10),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? (showAnimatedBg ? Colors.white : AppColors.primary)
                  : (isLocked
                        ? Colors.grey
                        : (showAnimatedBg
                              ? Colors.white70
                              : AppColors.assessmentTextSecondary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundCard({
    required ImageOption img,
    required bool isSelected,
    required VoidCallback onTap,
    bool isLocked = false,
    bool showAnimatedBg = false,
  }) {
    final textColor = showAnimatedBg
        ? Colors.white
        : AppColors.assessmentTextPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 104,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 124,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? (showAnimatedBg ? Colors.white : AppColors.primary)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(1.5),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    if (img.imageUrl == 'animated_lotus_night')
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF050815), Color(0xFF1B1440)],
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.nights_stay_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      )
                    else
                      Image.network(
                        img.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: showAnimatedBg
                              ? Colors.white.withOpacity(0.08)
                              : AppColors.primary.withAlpha(26),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            color: showAnimatedBg
                                ? Colors.white70
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    if (isLocked) ...[
                      Positioned.fill(
                        child: Container(color: Colors.black.withAlpha(120)),
                      ),
                      const Positioned.fill(
                        child: Align(
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.lock_outline_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    img.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isLocked
                          ? Colors.grey
                          : (isSelected
                                ? (showAnimatedBg
                                      ? Colors.white
                                      : AppColors.primary)
                                : textColor),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Image',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: showAnimatedBg
                          ? Colors.white38
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
Widget _buildAnimationCard({
  required String label,
  required Widget preview,
  required bool isSelected,
  required VoidCallback onTap,
  bool isLocked = false,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Container(
            height: 64,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withAlpha(20)
                  : (isLocked
                        ? Colors.grey.shade100.withAlpha(128)
                        : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: isLocked
                ? Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.grey.shade400,
                    size: 20,
                  )
                : preview,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppColors.primary
                  : (isLocked
                        ? Colors.grey
                        : AppColors.assessmentTextSecondary),
            ),
          ),
        ],
      ),
    ),
  );
}

// ignore: unused_element
Widget _getAnimationPreviewWidget(String animationName, bool isSelected) {
  final color = isSelected ? AppColors.primary : Colors.grey.shade700;

  switch (animationName) {
    case '4 Bubbles':
      return Wrap(
        spacing: 6,
        children: List.generate(
          4,
          (index) => Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color.withAlpha((100 + index * 50).clamp(0, 255)),
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    case 'Bubbles':
      return Stack(
        alignment: Alignment.center,
        children: List.generate(
          3,
          (index) => Container(
            width: 14 + index * 10,
            height: 14 + index * 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withAlpha(120), width: 1.5),
            ),
          ),
        ),
      );
    case 'Line Heart':
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [Icon(Icons.show_chart_rounded, color: color, size: 24)],
      );
    case 'Orbit':
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withAlpha(120), width: 1.5),
            ),
          ),
          Transform.translate(
            offset: const Offset(14, -14),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        ],
      );
    default:
      return const SizedBox();
  }
}
