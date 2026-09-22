// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/sleep_model.dart';
import '../../viewmodels/sleep_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../repositories/auth_repository.dart';
import '../../services/service_locator.dart';
import '../../services/audio_cache_service.dart';
import '../../widgets/app_cached_image.dart';
import '../subscription/subscription_view.dart';

import 'package:provider/provider.dart';

class SleepSoundsContent extends StatefulWidget {
  final HomeViewModel? homeViewModel;
  const SleepSoundsContent({super.key, this.homeViewModel});

  @override
  State<SleepSoundsContent> createState() => _SleepSoundsContentState();
}

class _SleepSoundsContentState extends State<SleepSoundsContent>
    with TickerProviderStateMixin {
  SleepSoundsViewModel? _viewModel;
  late final AudioPlayer _audioPlayer;
  bool _isRepeating = true;

  // Equalizer pulse controller
  late final AnimationController _equalizerController;
  late final Animation<double> _equalizerScale;

  @override
  void initState() {
    super.initState();

    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);

    // Equalizer pulsing
    _equalizerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _equalizerScale = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _equalizerController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = context.read<SleepSoundsViewModel>();
    if (_viewModel != vm) {
      _viewModel?.removeListener(_onViewModelChanged);
      _viewModel = vm;
      _viewModel?.addListener(_onViewModelChanged);

      final homeVM = widget.homeViewModel ?? context.read<HomeViewModel>();
      final initialSoundTitle = homeVM.selectedSleepSoundTitle;
      if (initialSoundTitle != null) {
        final index = vm.soundscapes.indexWhere((sound) => sound.title == initialSoundTitle);
        if (index != -1) {
          final isLocked = index >= 2 && !homeVM.isPremium;
          if (!isLocked) {
            vm.selectSound(vm.soundscapes[index]);
          }
        }
        homeVM.selectedSleepSoundTitle = null; // Consume it
      }
    }
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_onViewModelChanged);
    _equalizerController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onViewModelChanged() async {
    final vm = _viewModel;
    if (vm != null && vm.playingSound != null) {
      if (vm.isPlaying) {
        final path = _getSoundAssetPath(vm.playingSound!.title);
        if (path.isNotEmpty) {
          try {
            await _audioPlayer.setReleaseMode(
              _isRepeating ? ReleaseMode.loop : ReleaseMode.release,
            );
            await _audioPlayer.play(locator<AudioCacheService>().getAudioSource(path));
          } catch (e) {
            debugPrint('Error playing sleep sound: $e');
          }
        }
      } else {
        await _audioPlayer.pause();
      }
    } else {
      await _audioPlayer.stop();
    }
  }

  String _getSoundAssetPath(String title) {
    switch (title) {
      case 'Waterfall':
        return 'sleep/waterfall.mp3';
      case 'Deep Forest':
        return 'sleep/deepforest.mp3';
      case 'Forest Rain':
        return 'sleep/rain.mp3';
      case 'Water':
        return 'sleep/water.mp3';
      case 'Night Crickets':
        return 'sleep/circket.mp3';
      case 'Ocean Waves':
        return 'sleep/occenwave.mp3';
      case 'Pink Waterfall':
        return 'sleep/pinkwaterfall.mp3';
      default:
        return '';
    }
  }

  void _toggleRepeat() async {
    setState(() {
      _isRepeating = !_isRepeating;
    });
    try {
      await _audioPlayer.setReleaseMode(
        _isRepeating ? ReleaseMode.loop : ReleaseMode.release,
      );
    } catch (e) {
      debugPrint('Error setting loop mode: $e');
    }
  }

  void _playPrevious() {
    final vm = context.read<SleepSoundsViewModel>();
    final current = vm.playingSound;
    if (current == null) return;
    final homeVM = widget.homeViewModel ?? context.read<HomeViewModel>();
    final isPremium = homeVM.isPremium;
    final list = isPremium
        ? vm.soundscapes
        : vm.soundscapes.take(2).toList();
    final currentIndex = list.indexWhere((item) => item.title == current.title);
    if (currentIndex == -1) {
      vm.selectSound(list[0]);
      return;
    }
    if (currentIndex > 0) {
      vm.selectSound(list[currentIndex - 1]);
    } else {
      vm.selectSound(list[list.length - 1]); // Loop to end
    }
  }

  void _playNext() {
    final vm = context.read<SleepSoundsViewModel>();
    final current = vm.playingSound;
    if (current == null) return;
    final homeVM = widget.homeViewModel ?? context.read<HomeViewModel>();
    final isPremium = homeVM.isPremium;
    final list = isPremium
        ? vm.soundscapes
        : vm.soundscapes.take(2).toList();
    final currentIndex = list.indexWhere((item) => item.title == current.title);
    if (currentIndex == -1) {
      vm.selectSound(list[0]);
      return;
    }
    if (currentIndex < list.length - 1) {
      vm.selectSound(list[currentIndex + 1]);
    } else {
      vm.selectSound(list[0]); // Loop to start
    }
  }

  void _showSubscriptionView() async {
    final homeVM = widget.homeViewModel ?? context.read<HomeViewModel>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubscriptionView(viewModel: homeVM),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  void _showTimerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Set Sleep Timer',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTimerOption(15),
            _buildTimerOption(30),
            _buildTimerOption(45),
            _buildTimerOption(60),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SleepSoundsViewModel>();
    final primaryColor = const Color(0xFF4F55AE);
    final userName =
        locator<AuthRepository>().currentUserModel?.name ?? 'Khushal';

    return Stack(
      children: [
        // Main Content Layout
        Column(
          children: [
            Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(
                          left: 24,
                          right: 24,
                          top: 12,
                          bottom: 120,
                        ),
                        physics: const BouncingScrollPhysics(),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 1. Sleep Greeting Header
                                Text(
                                  'Good Evening, $userName',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1C1B1B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text('🌙', style: TextStyle(fontSize: 32)),
                                const SizedBox(height: 6),
                                Text(
                                  'Prepare your mind for peaceful sleep.',
                                  style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    color: const Color(0xFF464652),
                                  ),
                                ),
                                const SizedBox(height: 2),

                                // 2. Hero Premium Sleep Journey Card
                                _buildHeroSleepCard(context),
                                const SizedBox(height: 28),

                                // 3. Grid of Sleep Soundscape Cards
                                Text(
                                  'Sleep Sounds',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1C1B1B),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                viewModel.isLoading
                                    ? GridView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: 6,
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 16,
                                          mainAxisSpacing: 16,
                                          childAspectRatio: 1.05,
                                        ),
                                        itemBuilder: (context, index) =>
                                            _buildSoundscapeCardSkeleton(),
                                      )
                                    : GridView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: viewModel.soundscapes.length,
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 16,
                                          mainAxisSpacing: 16,
                                          childAspectRatio: 1.05,
                                        ),
                                        itemBuilder: (context, index) {
                                          final soundItem =
                                              viewModel.soundscapes[index];
                                          final isSelected =
                                              viewModel.playingSound?.title ==
                                                  soundItem.title;
                                          return _buildSoundscapeCard(
                                            context,
                                            soundItem,
                                            isSelected,
                                            index,
                                          );
                                        },
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // 4. Current Player Capsule Card Floating at the bottom
                if (viewModel.playingSound != null)
                  _buildPlayerCapsuleCard(primaryColor),
              ],
            );
  }

  // Hero Card layout matching mockup design
  Widget _buildHeroSleepCard(BuildContext context) {
    const heroBg =
        'https://images.unsplash.com/photo-1506318137071-a8e063b4bec0?auto=format&fit=crop&w=800&q=80';

    final homeVM = widget.homeViewModel ?? context.watch<HomeViewModel>();
    final viewModel = context.watch<SleepSoundsViewModel>();
    final isPremium = homeVM.isPremium;
    final playingSound = viewModel.playingSound;
    final isPlaying = viewModel.isPlaying;

    final bgImage = playingSound != null ? playingSound.bgImage : heroBg;
    final title = playingSound != null ? playingSound.title : 'Deep Sleep Journey';
    final duration = playingSound != null ? '${viewModel.remainingMinutes} min' : '45 min';
    final badgeText = playingSound != null
        ? (isPlaying ? 'Now Playing' : 'Paused')
        : 'Premium Session';
    final buttonText = playingSound != null
        ? (isPlaying ? 'Pause' : 'Resume')
        : (isPremium ? 'Start\nSession' : 'Unlock\nNow');

    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AppCachedImage(
              imageUrl: bgImage,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(32),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (playingSound == null && !isPremium) ...[
                                    const Icon(
                                      Icons.lock_rounded,
                                      color: Colors.white,
                                      size: 11,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    badgeText,
                                    style: GoogleFonts.manrope(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.schedule_rounded,
                                  color: Colors.white70,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  duration,
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (playingSound == null) {
                            if (!isPremium) {
                              _showSubscriptionView();
                              return;
                            }
                            // Trigger default sleep playlist
                            final vm = context.read<SleepSoundsViewModel>();
                            if (vm.soundscapes.isNotEmpty) {
                              vm.selectSound(vm.soundscapes[0]);
                            }
                          } else {
                            context.read<SleepSoundsViewModel>().togglePlayback();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F55AE),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          buttonText,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Grid Soundscape Card matching mockup style
  Widget _buildSoundscapeCard(
    BuildContext context,
    SleepSoundItem item,
    bool isSelected,
    int index,
  ) {
    final homeVM = widget.homeViewModel ?? context.watch<HomeViewModel>();
    final isLocked = index >= 2 && !homeVM.isPremium;

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          _showSubscriptionView();
        } else {
          context.read<SleepSoundsViewModel>().selectSound(item);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4F55AE)
                : Colors.white.withOpacity(0.2),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: AppCachedImage(
                imageUrl: item.bgImage,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            // Dark gradient overlay to make text highly readable
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    isLocked
                        ? Colors.black.withOpacity(0.7)
                        : Colors.black.withOpacity(0.6),
                    isLocked
                        ? Colors.black.withOpacity(0.3)
                        : Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Text(
                item.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
              )
            else if (isSelected)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF4F55AE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundscapeCardSkeleton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AppShimmer(
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: AppShimmer(
              width: 100,
              height: 16,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  // Floating Player Capsule Card
  Widget _buildPlayerCapsuleCard(Color primaryColor) {
    final viewModel = context.watch<SleepSoundsViewModel>();
    final isPlaying = viewModel.isPlaying;
    final soundTitle = viewModel.playingSound?.title ?? 'Waterfall';
    final remainingMinutes = viewModel.remainingMinutes;

    return Positioned(
      bottom: 120, // Show above the floating bottom navbar
      left: 16,
      right: 16,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9), // frosted-glass effect
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: primaryColor.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Pulse Equalizer container
                ScaleTransition(
                  scale: isPlaying
                      ? _equalizerScale
                      : const AlwaysStoppedAnimation(1.0),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.equalizer,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Details Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        soundTitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1C1B1B),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$remainingMinutes mins remaining',
                        style: GoogleFonts.manrope(
                          color: const Color(0xFF464652),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Controls (Repeat, Prev, Play/Pause, Next, Timer)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Repeat Button
                    IconButton(
                      onPressed: _toggleRepeat,
                      icon: Icon(
                        _isRepeating
                            ? Icons.repeat_one_rounded
                            : Icons.repeat_rounded,
                        color: _isRepeating
                            ? const Color(0xFF4F55AE)
                            : const Color(0xFF464652),
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),

                    // Reverse Button (Previous)
                    IconButton(
                      onPressed: _playPrevious,
                      icon: const Icon(
                        Icons.skip_previous_rounded,
                        color: Color(0xFF1C1B1B),
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),

                    // Play/Pause Button
                    IconButton(
                      onPressed: viewModel.togglePlayback,
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: const Color(0xFF1C1B1B),
                        size: 28,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),

                    // Forward Button (Next)
                    IconButton(
                      onPressed: _playNext,
                      icon: const Icon(
                        Icons.skip_next_rounded,
                        color: Color(0xFF1C1B1B),
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),

                    // Timer Button
                    IconButton(
                      onPressed: _showTimerDialog,
                      icon: const Icon(
                        Icons.timer_outlined,
                        color: Color(0xFF1C1B1B),
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerOption(int minutes) {
    return ListTile(
      title: Text('$minutes Minutes', style: GoogleFonts.manrope()),
      onTap: () {
        context.read<SleepSoundsViewModel>().setTimer(minutes);
        Navigator.pop(context);
      },
    );
  }
}
