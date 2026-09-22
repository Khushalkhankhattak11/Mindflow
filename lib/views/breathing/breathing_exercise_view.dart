// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../viewmodels/breathing_exercise_viewmodel.dart';
import 'breathing_result_view.dart';
import '../../repositories/auth_repository.dart';
import '../../services/service_locator.dart';
import '../../services/audio_cache_service.dart';

class BreathingExerciseView extends StatefulWidget {
  final String exerciseTitle;
  final int durationSeconds;
  final String backgroundImageUrl;
  final String backgroundSound;
  final String soundEffect;
  final String voiceGender;

  const BreathingExerciseView({
    super.key,
    this.exerciseTitle = 'Box Breathing',
    this.durationSeconds = 285,
    this.backgroundImageUrl = '',
    this.backgroundSound = 'Silent',
    this.soundEffect = 'None',
    this.voiceGender = 'Female',
  });

  @override
  State<BreathingExerciseView> createState() => _BreathingExerciseViewState();
}

class _BreathingExerciseViewState extends State<BreathingExerciseView>
    with TickerProviderStateMixin {
  BreathingExerciseViewModel? _viewModel;
  late final AudioPlayer _audioPlayer;
  late final FlutterTts _flutterTts;
  String? _lastInstruction;
  bool _isMuted = false;
  final List<String> _soundOptions = [
    'Silent',
    'Rain',
    'Wind',
    'Breeze',
    'Beach',
    'Fire',
  ];
  late String _currentSound;

  // Breathing pulse controller
  late final AnimationController _breathController;
  late final Animation<double> _breathScale;
  late final Animation<double> _breathOpacity;

  // Orbiting orb controller
  late final AnimationController _orbitController;

  @override
  void initState() {
    super.initState();
    _currentSound = widget.backgroundSound;

    _flutterTts = FlutterTts();
    _flutterTts.setLanguage('en-US');

    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _playBackgroundSound();

    // 8-second breathing animation cycle (4s inhale/swell, 4s exhale/shrink)
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _breathScale = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _breathOpacity = Tween<double>(begin: 0.7, end: 0.9).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    // 16-second orbit cycle (synchronized with full 16s breathing cycle)
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  void _playBackgroundSound() {
    if (_currentSound == 'Silent') {
      try {
        _audioPlayer.stop();
      } catch (_) {}
      return;
    }
    final path = _getSoundAssetPath(_currentSound);
    if (path.isNotEmpty) {
      _audioPlayer
          .play(locator<AudioCacheService>().getAudioSource(path))
          .catchError((e) {
            debugPrint('Error playing background sound: $e');
          });
    }
  }

  String _getSoundAssetPath(String soundName) {
    switch (soundName) {
      case 'Rain':
        return 'voice/rain.mp3';
      case 'Wind':
        return 'voice/wind.mp3';
      case 'Breeze':
        return 'voice/slowwind.mp3';
      case 'Beach':
        return 'voice/beach.mp3';
      case 'Fire':
        return 'voice/fire.mp3';
      default:
        return '';
    }
  }

  bool _hasNavigatedToResult = false;

  void _onStateChanged() {
    final vm = _viewModel;
    if (vm == null) return;
    if (vm.secondsRemaining == 0 && !_hasNavigatedToResult) {
      _hasNavigatedToResult = true;
      try {
        _audioPlayer.stop();
      } catch (e) {
        debugPrint('Error stopping background audio: $e');
      }
      _navigateToResultScreen();
      return;
    }

    if (vm.isPlaying) {
      final newInstruction = vm.currentInstruction;
      if (newInstruction != _lastInstruction) {
        _lastInstruction = newInstruction;
        _speakInstruction(newInstruction);
      }
    }

    if (!vm.isPlaying) {
      _breathController.stop();
      _orbitController.stop();
      try {
        _audioPlayer.pause();
      } catch (e) {
        debugPrint('Error pausing background audio: $e');
      }
    } else {
      if (!_breathController.isAnimating) {
        _breathController.repeat(reverse: true);
      }
      if (!_orbitController.isAnimating) {
        _orbitController.repeat();
      }
      try {
        _audioPlayer.resume();
      } catch (e) {
        debugPrint('Error resuming background audio: $e');
      }
    }
  }

  void _navigateToResultScreen() {
    locator<AuthRepository>()
        .saveQuickExerciseReport(
          exerciseName: widget.exerciseTitle,
          durationSeconds: widget.durationSeconds,
          breathCount: _viewModel?.breathCount ?? 0,
        )
        .catchError((e) {
          debugPrint('Failed to save exercise report: $e');
        });

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => BreathingResultView(
          exerciseTitle: widget.exerciseTitle,
          durationSeconds: widget.durationSeconds,
          backgroundSound: widget.backgroundSound,
          soundEffect: widget.soundEffect,
          voiceGender: widget.voiceGender,
        ),
      ),
    );
  }

  void _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });
    try {
      await _audioPlayer.setVolume(_isMuted ? 0.0 : 1.0);
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  Widget glassButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  void _resetExercise() {
    final vm = _viewModel;
    if (vm == null) return;
    setState(() {
      vm.reset(widget.durationSeconds);
      _breathController.reset();
      _orbitController.reset();
      _lastInstruction = null;
      if (vm.isPlaying) {
        _breathController.repeat(reverse: true);
        _orbitController.repeat();
        _playBackgroundSound();
      }
    });
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_onStateChanged);
    _breathController.dispose();
    _orbitController.dispose();
    _audioPlayer.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _speakInstruction(String instruction) async {
    if (_isMuted) return;

    double pitch = 1.0;
    double rate = 0.45;

    switch (widget.voiceGender) {
      case 'Warm':
        pitch = 0.95;
        rate = 0.45;
        break;
      case 'Clear':
        pitch = 1.05;
        rate = 0.5;
        break;
      case 'Deep':
        pitch = 0.75;
        rate = 0.4;
        break;
      case 'Whisper':
        pitch = 1.15;
        rate = 0.35;
        break;
      case 'Soft':
        pitch = 1.1;
        rate = 0.42;
        break;
    }

    try {
      await _flutterTts.setPitch(pitch);
      await _flutterTts.setSpeechRate(rate);
      await _flutterTts.speak(instruction);
    } catch (e) {
      debugPrint('Error speaking instruction: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.primary;

    return ChangeNotifierProvider<BreathingExerciseViewModel>(
      create: (_) {
        final vm = BreathingExerciseViewModel(
          durationSeconds: widget.durationSeconds,
        );
        _viewModel?.removeListener(_onStateChanged);
        _viewModel = vm;
        _viewModel!.addListener(_onStateChanged);
        return vm;
      },
      child: Builder(
        builder: (context) {
          final viewModel = context.watch<BreathingExerciseViewModel>();

          return Scaffold(
            body: Stack(
              children: [
                // Ambient Background Image (if configured)
                if (widget.backgroundImageUrl.isNotEmpty)
                  Positioned.fill(
                    child: widget.backgroundImageUrl == 'animated_lotus_night'
                        ? AnimatedBuilder(
                            animation: _breathController,
                            builder: (context, child) => CustomPaint(
                              painter: _BackgroundPainter(
                                glow: _breathController.value,
                              ),
                              size: Size.infinite,
                            ),
                          )
                        : Image.network(
                            widget.backgroundImageUrl,
                            fit: BoxFit.cover,
                          ),
                  ),
                // Dark tint overlay for readability when image is present
                if (widget.backgroundImageUrl.isNotEmpty &&
                    widget.backgroundImageUrl != 'animated_lotus_night')
                  Positioned.fill(
                    child: Container(color: Colors.black.withAlpha(128)),
                  ),

                // 1. Ambient Background Shader (Pulsing Gradient representation)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _breathScale,
                    builder: (context, child) {
                      final progress =
                          (_breathScale.value - 1.0) / 0.4; // 0.0 to 1.0

                      return Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF8B5CF6).withAlpha(
                                (widget.backgroundImageUrl.isNotEmpty
                                        ? 40
                                        : 102) +
                                    (progress * 50).toInt(),
                              ), // color1
                              const Color(0xFFF4EAFF).withAlpha(
                                (widget.backgroundImageUrl.isNotEmpty
                                        ? 30
                                        : 153) -
                                    (progress * 50).toInt(),
                              ), // color2
                              const Color(0xFF1E004A).withAlpha(
                                widget.backgroundImageUrl.isNotEmpty
                                    ? 120
                                    : 255,
                              ), // color3 (Deep Indigo background)
                            ],
                            center: Alignment.center,
                            radius: 0.8 + progress * 0.2,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Noise texture overlay
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.02,
                    child: Image.network(
                      'https://grainy-gradients.vercel.app/noise.svg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(),
                    ),
                  ),
                ),

                // Main Canvas
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Header Row
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(51),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withAlpha(102),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(38),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withAlpha(51),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    widget.exerciseTitle.toUpperCase(),
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _toggleMute,
                                  icon: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(51),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withAlpha(102),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      _isMuted
                                          ? Icons.volume_off
                                          : Icons.volume_up,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Active Settings Indicators
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                _buildGlassBadge(
                                  Icons.waves_rounded,
                                  widget.backgroundSound,
                                ),
                                _buildGlassBadge(
                                  Icons.notifications_active_outlined,
                                  widget.soundEffect,
                                ),
                                _buildGlassBadge(
                                  widget.voiceGender == 'Female'
                                      ? Icons.female_rounded
                                      : Icons.male_rounded,
                                  widget.voiceGender,
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Central breathing anchor
                        Expanded(
                          child: Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // 1. Concentric Bubbles rings (Default)
                                if (widget.soundEffect == 'Bubbles' ||
                                    widget.soundEffect == 'None') ...[
                                  ScaleTransition(
                                    scale: _breathScale,
                                    child: Container(
                                      width: 280,
                                      height: 280,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withAlpha(26),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  ScaleTransition(
                                    scale: _breathScale,
                                    child: Container(
                                      width: 240,
                                      height: 240,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withAlpha(51),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],

                                // 4. Orbit layout (from HTML style)
                                if (widget.soundEffect == 'Orbit') ...[
                                  // Static Atmospheric Ring 1 (400px)
                                  Container(
                                    width: 400,
                                    height: 400,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withAlpha(
                                          26,
                                        ), // border-white/10
                                        width: 1.0,
                                      ),
                                    ),
                                  ),
                                  // Static Atmospheric Ring 2 (320px)
                                  Container(
                                    width: 320,
                                    height: 320,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withAlpha(
                                          77,
                                        ), // border-white/30
                                        width: 1.0,
                                      ),
                                    ),
                                  ),
                                  // Dynamic Breathing Circle (270px)
                                  ScaleTransition(
                                    scale: _breathScale,
                                    child: Container(
                                      width: 270,
                                      height: 270,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFcae6ff)
                                              .withAlpha(
                                                153,
                                              ), // primary-fixed / 60%
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFa8d8ff)
                                                .withAlpha(
                                                  51,
                                                ), // primary-container / 20%
                                            blurRadius: 40,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],

                                // 2. 4 Bubbles layout
                                if (widget.soundEffect == '4 Bubbles')
                                  AnimatedBuilder(
                                    animation: _breathScale,
                                    builder: (context, child) {
                                      final scaleVal = _breathScale.value;
                                      final offsetDist = 95.0 * scaleVal;
                                      return Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Transform.translate(
                                            offset: Offset(
                                              -offsetDist,
                                              -offsetDist,
                                            ),
                                            child: _buildPulsingBubble(
                                              24,
                                              scaleVal,
                                            ),
                                          ),
                                          Transform.translate(
                                            offset: Offset(
                                              offsetDist,
                                              -offsetDist,
                                            ),
                                            child: _buildPulsingBubble(
                                              24,
                                              scaleVal,
                                            ),
                                          ),
                                          Transform.translate(
                                            offset: Offset(
                                              -offsetDist,
                                              offsetDist,
                                            ),
                                            child: _buildPulsingBubble(
                                              24,
                                              scaleVal,
                                            ),
                                          ),
                                          Transform.translate(
                                            offset: Offset(
                                              offsetDist,
                                              offsetDist,
                                            ),
                                            child: _buildPulsingBubble(
                                              24,
                                              scaleVal,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),

                                // 3. Line Heart ECG wave layout
                                if (widget.soundEffect == 'Line Heart')
                                  AnimatedBuilder(
                                    animation: _breathController,
                                    builder: (context, child) {
                                      return SizedBox(
                                        width: 320,
                                        height: 140,
                                        child: CustomPaint(
                                          painter: HeartbeatPainter(
                                            animationValue:
                                                _breathController.value,
                                            color: Colors.white.withAlpha(120),
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                // Central glassmorphic orb (Shared for all animations)
                                AnimatedBuilder(
                                  animation: _breathScale,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _breathScale.value,
                                      child: Opacity(
                                        opacity: _breathOpacity.value,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 180,
                                    height: 180,
                                    decoration: widget.soundEffect == 'Orbit'
                                        ? const BoxDecoration()
                                        : BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withAlpha(51),
                                            border: Border.all(
                                              color: Colors.white.withAlpha(
                                                102,
                                              ),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFF8B5CF6,
                                                ).withAlpha(51),
                                                blurRadius: 32,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          viewModel.currentInstruction,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w800,
                                            color: primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          width: 32,
                                          height: 3,
                                          decoration: BoxDecoration(
                                            color: primaryColor.withAlpha(51),
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // 4. Orbiting Orb animation (loops continuously around the circle)
                                if (widget.soundEffect == 'Orbit')
                                  RotationTransition(
                                    turns: _orbitController,
                                    child: Transform.translate(
                                      offset: const Offset(
                                        0,
                                        -135,
                                      ), // Orbit radius matching translateX(135px)
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.white.withAlpha(
                                                204,
                                              ),
                                              blurRadius: 12,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Footer timer & play controls
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Sound selector pill (with music note on left, dropdown arrow on right)
                            Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.music_note,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Ambient: ',
                                    style: GoogleFonts.manrope(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  DropdownButton<String>(
                                    dropdownColor: const Color(0xFF1E004A),
                                    value: _currentSound,
                                    underline: const SizedBox(),
                                    icon: const Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.white,
                                    ),
                                    style: GoogleFonts.manrope(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    items: _soundOptions.map((String sound) {
                                      return DropdownMenuItem<String>(
                                        value: sound,
                                        child: Text(sound),
                                      );
                                    }).toList(),
                                    onChanged: (String? newSound) {
                                      if (newSound != null) {
                                        setState(() {
                                          _currentSound = newSound;
                                          _playBackgroundSound();
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // Session timer display
                            Text(
                              viewModel.formatTimeRemaining(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                            Text(
                              'TIME REMAINING',
                              style: GoogleFonts.manrope(
                                color: Colors.white54,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Session completion progress bar
                            SizedBox(
                              width: 220,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: LinearProgressIndicator(
                                  value:
                                      (widget.durationSeconds -
                                          viewModel.secondsRemaining) /
                                      widget.durationSeconds,
                                  minHeight: 10,
                                  backgroundColor: Colors.white12,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Play/Pause & Reset Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                glassButton(Icons.refresh, _resetExercise),
                                const SizedBox(width: 24),
                                GestureDetector(
                                  onTap: viewModel.togglePlayPause,
                                  child: Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF7F56D9,
                                      ), // Vibrant Purple Button
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF7F56D9,
                                          ).withOpacity(0.4),
                                          blurRadius: 20,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      viewModel.isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 36,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                glassButton(
                                  Icons.done_rounded,
                                  _navigateToResultScreen,
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

  Widget _buildGlassBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(51), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withAlpha(204), size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulsingBubble(double size, double scale) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withAlpha(100),
        border: Border.all(color: Colors.white.withAlpha(180), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withAlpha(40),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }
}

class HeartbeatPainter extends CustomPainter {
  final double animationValue; // 0.0 to 1.0
  final Color color;

  HeartbeatPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Draw a standard heartbeat (ECG) wave in the center
    path.moveTo(0, h / 2);
    path.lineTo(w * 0.3, h / 2);

    // P wave (small bump)
    path.lineTo(w * 0.34, h / 2 - 8 * animationValue);
    path.lineTo(w * 0.38, h / 2);
    path.lineTo(w * 0.42, h / 2);

    // QRS complex (sharp spike down, then very high up, then deep down)
    path.lineTo(w * 0.45, h / 2 + 10 * animationValue);
    path.lineTo(w * 0.49, h / 2 - 50 * animationValue);
    path.lineTo(w * 0.53, h / 2 + 40 * animationValue);
    path.lineTo(w * 0.56, h / 2 - 5 * animationValue);
    path.lineTo(w * 0.59, h / 2);

    // T wave (medium bump)
    path.lineTo(w * 0.65, h / 2 - 16 * animationValue);
    path.lineTo(w * 0.7, h / 2);

    path.lineTo(w, h / 2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HeartbeatPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class _BackgroundPainter extends CustomPainter {
  final double glow;
  _BackgroundPainter({required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // sky -> water gradient
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF050815),
          Color(0xFF0B1130),
          Color(0xFF150F30),
          Color(0xFF1B1440),
        ],
        stops: [0.0, 0.45, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), sky);

    // stars
    final starRng = math.Random(42);
    for (int i = 0; i < 90; i++) {
      final dx = starRng.nextDouble() * w;
      final dy = starRng.nextDouble() * h * 0.55;
      final r = starRng.nextDouble() * 1.3 + 0.2;
      final tw = (0.4 + 0.6 * ((math.sin(dx + glow * 6) + 1) / 2));
      canvas.drawCircle(
        Offset(dx, dy),
        r,
        Paint()..color = Colors.white.withOpacity(tw),
      );
    }

    // crescent moon, top right
    final moonCenter = Offset(w * 0.86, h * 0.09);
    final moonR = w * 0.06;
    final moonGlow = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, moonR * 1.4);
    canvas.drawCircle(moonCenter, moonR * 1.6, moonGlow);
    canvas.drawCircle(moonCenter, moonR, Paint()..color = Colors.white70);
    canvas.drawCircle(
      Offset(moonCenter.dx + moonR * 0.45, moonCenter.dy - moonR * 0.15),
      moonR * 0.92,
      Paint()..color = const Color(0xFF0B1130),
    );

    // distant mountains
    final mtnPath = Path()
      ..moveTo(0, h * 0.55)
      ..lineTo(w * 0.15, h * 0.48)
      ..lineTo(w * 0.32, h * 0.56)
      ..lineTo(w * 0.5, h * 0.47)
      ..lineTo(w * 0.68, h * 0.55)
      ..lineTo(w * 0.85, h * 0.49)
      ..lineTo(w, h * 0.54)
      ..lineTo(w, h * 0.6)
      ..lineTo(0, h * 0.6)
      ..close();
    canvas.drawPath(
      mtnPath,
      Paint()..color = const Color(0xFF120E28).withOpacity(0.8),
    );

    // water body
    final waterRect = Rect.fromLTWH(0, h * 0.6, w, h * 0.4);
    canvas.drawRect(
      waterRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF171240), Color(0xFF0A0820)],
        ).createShader(waterRect),
    );

    // floating lantern lights on the water
    final lanternRng = math.Random(11);
    for (int i = 0; i < 6; i++) {
      final dx = lanternRng.nextDouble() * w;
      final dy = h * 0.68 + lanternRng.nextDouble() * h * 0.26;
      final flicker = 0.5 + 0.5 * math.sin(glow * 6 + i);
      final c = Paint()
        ..color = const Color(0xFFFFB870).withOpacity(0.35 + flicker * 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset(dx, dy), 6, c);
      canvas.drawCircle(
        Offset(dx, dy),
        2.4,
        Paint()..color = const Color(0xFFFFD9A0),
      );
    }

    // a few drifting petal shapes
    final petalRng = math.Random(3);
    for (int i = 0; i < 8; i++) {
      final dx = petalRng.nextDouble() * w;
      final dy = petalRng.nextDouble() * h;
      final rot = petalRng.nextDouble() * math.pi;
      final s = petalRng.nextDouble() * 10 + 8;
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(rot);
      final petalPaint = Paint()
        ..color = const Color(0xFF8C6FE6).withOpacity(0.18);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: s, height: s * 0.55),
        petalPaint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) => true;
}
