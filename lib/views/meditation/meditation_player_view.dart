import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../constants/app_colors.dart';
import '../../models/meditation_model.dart';
import '../../viewmodels/meditation_player_viewmodel.dart';
import '../../widgets/app_cached_image.dart';
import 'widgets/ambient_mixer_sheet.dart';

class MeditationPlayerView extends StatefulWidget {
  final MeditationSession session;

  const MeditationPlayerView({super.key, required this.session});

  @override
  State<MeditationPlayerView> createState() => _MeditationPlayerViewState();
}

class _MeditationPlayerViewState extends State<MeditationPlayerView> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  // Ambient mixer state variables
  double _voiceVolume = 1.0;
  double _ambientVolume = 0.5;
  String _selectedAmbientTrack = 'rain';

  void _showAmbientMixerBottomSheet() {
    _resetControlsTimer(seconds: 15);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AmbientMixerSheet(
        voiceVolume: _voiceVolume,
        ambientVolume: _ambientVolume,
        selectedAmbientTrack: _selectedAmbientTrack,
        onVoiceVolumeChanged: (val) {
          setState(() => _voiceVolume = val);
        },
        onAmbientVolumeChanged: (val) {
          setState(() => _ambientVolume = val);
        },
        onAmbientTrackSelected: (trackId) {
          setState(() => _selectedAmbientTrack = trackId);
        },
      ),
    );
  }

  // Immersive media controls auto-hide variables
  bool _showControls = true;
  Timer? _controlsTimer;

  bool get _isVideoSession {
    return widget.session.imageUrl.contains('m9.png') ||
        widget.session.imageUrl.contains('m10.png');
  }

  @override
  void initState() {
    super.initState();
    if (_isVideoSession) {
      _initVideoPlayer();
    }
    _resetControlsTimer(seconds: 5);
  }

  void _resetControlsTimer({int seconds = 5}) {
    _controlsTimer?.cancel();
    if (_showControls) {
      _controlsTimer = Timer(Duration(seconds: seconds), () {
        if (mounted) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _resetControlsTimer();
    } else {
      _controlsTimer?.cancel();
    }
  }

  void _initVideoPlayer() {
    final assetPath = _getVideoAssetPath(widget.session.title);
    debugPrint('Loading background video from asset: $assetPath');
    _videoController = VideoPlayerController.asset(assetPath);

    _videoController
        ?.initialize()
        .then((_) {
          if (mounted) {
            setState(() {
              _isVideoInitialized = true;
            });
            _videoController?.setLooping(true);
            _videoController?.setVolume(0.0);
            _videoController?.play();
          }
        })
        .catchError((error) {
          debugPrint(
            'Error initializing video background asset ($assetPath): $error',
          );
        });
  }

  String _getVideoAssetPath(String title) {
    // Always use the bundled video background v1.mp4
    return 'assets/video/v1.mp4';
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.primary;

    return ChangeNotifierProvider<MeditationPlayerViewModel>(
      create: (_) => MeditationPlayerViewModel(session: widget.session),
      child: Builder(
        builder: (context) {
          final viewModel = context.watch<MeditationPlayerViewModel>();

          return Scaffold(
            backgroundColor: const Color(0xFF1E1929),
            body: GestureDetector(
              onTap: _toggleControls,
              behavior: HitTestBehavior.opaque,
              child: Stack(
              children: [
                // 1. Full-screen Looping Video Background (Only for last 2 sessions m9 & m10)
                if (_isVideoSession && _isVideoInitialized && _videoController != null)
                  Positioned.fill(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: VideoPlayer(_videoController!),
                      ),
                    ),
                  )
                else
                  // Calming deep image background with local cache & shimmer skeleton while video is loading
                  Positioned.fill(
                    child: AppCachedImage(
                      imageUrl: widget.session.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),

                // 2. Translucent Dark Mask for content readability (gets darker when controls are visible)
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withAlpha(_showControls ? 160 : 40),
                          Colors.black.withAlpha(_showControls ? 90 : 20),
                          Colors.black.withAlpha(_showControls ? 180 : 60),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                // 3. Immersive Control Overlays (fades in/out on touch)
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: IgnorePointer(
                      ignoring: !_showControls,
                      child: Stack(
                        children: [
                          // Sticky Header navigation (White icons and text)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              child: SafeArea(
                                bottom: false,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    Text(
                                      'MindFlow',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                     IconButton(
                                       onPressed: _showAmbientMixerBottomSheet,
                                       icon: const Icon(
                                         Icons.tune_rounded,
                                         color: Colors.white,
                                       ),
                                       tooltip: 'Ambient Sound Mixer',
                                     ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Main player layout content
                          // Playback Controls Glass Card (Glassmorphic) positioned at the bottom of the screen
                          Positioned(
                            bottom: 48,
                            left: 24,
                            right: 24,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(
                                  30,
                                ), // premium glass-surface
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: Colors.white.withAlpha(51),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Main transport controls (replay, play/pause, forward)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          _resetControlsTimer();
                                          viewModel.replay10();
                                        },
                                        icon: const Icon(
                                          Icons.replay_10,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      ),
                                      // Large Play/Pause floating circle
                                      GestureDetector(
                                        onTap: () {
                                          _resetControlsTimer();
                                          viewModel.togglePlayPause();
                                        },
                                        child: Container(
                                          width: 76,
                                          height: 76,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 16,
                                                offset: Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            viewModel.isPlaying
                                                ? Icons.pause
                                                : Icons.play_arrow_rounded,
                                            color: primaryColor,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          _resetControlsTimer();
                                          viewModel.forward10();
                                        },
                                        icon: const Icon(
                                          Icons.forward_10,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),
                                  // Progress bar slider
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 4,
                                      activeTrackColor: Colors.white,
                                      inactiveTrackColor: Colors.white
                                          .withAlpha(51),
                                      thumbColor: Colors.white,
                                      overlayColor: Colors.white.withAlpha(30),
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 7,
                                      ),
                                    ),
                                    child: Slider(
                                      value: viewModel.progressPercentage,
                                      onChanged: (val) {
                                        _resetControlsTimer();
                                        viewModel.seekToPercentage(val);
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          viewModel.formatDuration(
                                            viewModel.currentSeconds,
                                          ),
                                          style: GoogleFonts.manrope(
                                            color: Colors.white.withAlpha(204),
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          viewModel.formatDuration(
                                            viewModel.totalSeconds,
                                          ),
                                          style: GoogleFonts.manrope(
                                            color: Colors.white.withAlpha(204),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
}
