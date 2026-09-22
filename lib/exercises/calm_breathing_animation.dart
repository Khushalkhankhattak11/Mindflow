// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../constants/app_colors.dart';
import '../repositories/auth_repository.dart';
import '../services/service_locator.dart';
import '../services/audio_cache_service.dart';

class ClamBreathingScreen extends StatefulWidget {
  final int durationSeconds;
  final String backgroundImageUrl;
  final String backgroundSound;
  final String voiceGender;

  const ClamBreathingScreen({
    super.key,
    this.durationSeconds = 240, // Default 4 minutes
    this.backgroundImageUrl = '',
    this.backgroundSound = 'Silent',
    this.voiceGender = 'Female',
  });

  @override
  State<ClamBreathingScreen> createState() => _ClamBreathingScreenState();
}

class _ClamBreathingScreenState extends State<ClamBreathingScreen>
    with TickerProviderStateMixin {
  late final AudioPlayer _audioPlayer;
  late final FlutterTts _flutterTts;
  late final AnimationController _animationController;
  late final AnimationController _bubbleController;

  // Session state variables
  bool _isPlaying = true;
  bool _isMuted = false;
  bool _isVoiceEnabled = true;
  late int _secondsRemaining;
  int _breathCount = 0;
  Timer? _sessionTimer;

  // Sound options
  final List<String> _soundOptions = [
    'Silent',
    'Rain',
    'Wind',
    'Breeze',
    'Beach',
    'Fire',
  ];
  late String _currentSound;

  // Bubbles
  final List<BubbleModel> _bubbles = [];
  final double _shellSize = 220.0;

  // Animation values
  String? _lastSpokenPhase;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.durationSeconds;
    _currentSound = widget.backgroundSound;

    // Initialize TTS
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage('en-US');

    // Initialize background audio player
    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _playBackgroundSound();

    // 16-second breathing cycle: 4s inhale, 4s hold, 4s exhale, 4s hold
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );

    _animationController.addListener(() {
      setState(() {
        _handlePhaseTransitions();
      });
    });

    // Bubbles background animation controller
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _generateBubbles();

    if (_isPlaying) {
      _animationController.repeat();
      _startSessionTimer();
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _animationController.dispose();
    _bubbleController.dispose();
    _audioPlayer.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _generateBubbles() {
    final random = math.Random();
    for (int i = 0; i < 25; i++) {
      _bubbles.add(
        BubbleModel(
          left: random.nextDouble(),
          size: random.nextDouble() * 12 + 6,
          speed: random.nextDouble() * 6 + 4,
          depthFactor: random.nextDouble() * 0.5 + 0.5,
        ),
      );
    }
  }

  // Handle playing ambient sounds
  void _playBackgroundSound() {
    if (_currentSound == 'Silent') {
      _audioPlayer.stop();
      return;
    }
    final path = _getSoundAssetPath(_currentSound);
    if (path.isNotEmpty) {
      _audioPlayer.play(locator<AudioCacheService>().getAudioSource(path)).catchError((e) {
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

  // Handle phase transitions and Text-To-Speech (TTS)
  void _handlePhaseTransitions() {
    final phase = _getCurrentPhase();
    if (phase != _lastSpokenPhase) {
      _lastSpokenPhase = phase;

      // Calculate breath count (completed full 16-second cycle when transitioning back to Inhale)
      if (phase == 'Inhale') {
        _breathCount++;
      }

      if (_isVoiceEnabled) {
        _speakInstruction(
          phase == 'Inhale'
              ? 'Breathe In'
              : (phase == 'Exhale' ? 'Breathe Out' : 'Hold'),
        );
      }
    }
  }

  String _getCurrentPhase() {
    final t = _animationController.value;
    if (t < 0.25) return 'Inhale';
    if (t < 0.50) return 'Hold';
    if (t < 0.75) return 'Exhale';
    return 'Hold';
  }

  double _getShellRotationAngle() {
    final t = _animationController.value;
    if (t < 0.25) {
      // Inhale: shell opens from 0 to -0.75 radians
      final p = t / 0.25;
      return p * -0.75;
    } else if (t < 0.50) {
      // Hold full: shell stays open at -0.75 radians
      return -0.75;
    } else if (t < 0.75) {
      // Exhale: shell closes from -0.75 to 0 radians
      final p = (t - 0.50) / 0.25;
      return -0.75 + (p * 0.75);
    } else {
      // Hold empty: shell stays closed at 0 radians
      return 0.0;
    }
  }

  double _getPearlScale() {
    final t = _animationController.value;
    if (t < 0.25) {
      // Inhale: pearl scales from 0.95 to 1.15 and glows
      final p = t / 0.25;
      return 0.95 + 0.20 * p;
    } else if (t < 0.50) {
      // Hold full: stays at 1.15
      return 1.15;
    } else if (t < 0.75) {
      // Exhale: scales back down from 1.15 to 0.95
      final p = (t - 0.50) / 0.25;
      return 1.15 - 0.20 * p;
    } else {
      // Hold empty: stays at 0.95
      return 0.95;
    }
  }

  int _getPhaseCountdown() {
    final t = _animationController.value;
    final secondsInCycle = t * 16;
    final secondsInPhase = secondsInCycle % 4;
    return 4 - secondsInPhase.floor();
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

  // Session timer logic
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPlaying) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _isPlaying = false;
            _sessionTimer?.cancel();
            _animationController.stop();
            _audioPlayer.stop();
            _saveReportAndExit();
          }
        });
      }
    });
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _animationController.repeat();
        _bubbleController.repeat();
        _startSessionTimer();
        _audioPlayer.resume();
      } else {
        _animationController.stop();
        _bubbleController.stop();
        _sessionTimer?.cancel();
        _audioPlayer.pause();
      }
    });
  }

  void _resetExercise() {
    setState(() {
      _animationController.reset();
      _secondsRemaining = widget.durationSeconds;
      _breathCount = 0;
      _lastSpokenPhase = null;
      if (_isPlaying) {
        _animationController.repeat();
        _playBackgroundSound();
      }
    });
  }

  void _saveReportAndExit() {
    locator<AuthRepository>()
        .saveQuickExerciseReport(
          exerciseName: 'Calm Breath',
          durationSeconds: widget.durationSeconds - _secondsRemaining,
          breathCount: _breathCount,
        )
        .catchError((e) {
          debugPrint('Failed to save exercise report: $e');
        });

    Navigator.of(context).pop();
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

  String _formatTime(int totalSeconds) {
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final String currentInstruction = _getCurrentPhase();
    final String labelInstruction = currentInstruction == 'Inhale'
        ? 'Breathe In'
        : (currentInstruction == 'Exhale' ? 'Breathe Out' : 'Hold');
    final int countdown = _getPhaseCountdown();

    return Scaffold(
      body: Stack(
        children: [
          // 1. Calming Deep Ocean/Midnight Gradient Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Color(0xFF0F2C59), // Ocean deep blue
                    Color(0xFF051329), // Mid midnight
                    Color(0xFF020710), // Midnight black
                  ],
                  center: Alignment.center,
                  radius: 1.1,
                ),
              ),
            ),
          ),

          // Ambient Background Image (if configured)
          if (widget.backgroundImageUrl.isNotEmpty)
            Positioned.fill(
              child: widget.backgroundImageUrl == 'animated_lotus_night'
                  ? AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) => CustomPaint(
                        painter: _BackgroundPainter(glow: _animationController.value),
                        size: Size.infinite,
                      ),
                    )
                  : Image.network(
                      widget.backgroundImageUrl,
                      fit: BoxFit.cover,
                    ),
            ),
          // Dark tint overlay for readability when image is present
          if (widget.backgroundImageUrl.isNotEmpty && widget.backgroundImageUrl != 'animated_lotus_night')
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.55)),
            ),

          // 2. Animated floating bubbles in background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bubbleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _UnderwaterBubblesPainter(
                    bubbles: _bubbles,
                    animationValue: _bubbleController.value,
                  ),
                );
              },
            ),
          ),

          // 3. Central Clam Shell and Pearl CustomPaint Animation
          Positioned.fill(
            child: Center(
              child: Container(
                width: _shellSize + 60,
                height: _shellSize + 100,
                alignment: Alignment.center,
                child: CustomPaint(
                  size: Size(_shellSize, _shellSize),
                  painter: ClamShellPainter(
                    rotationAngle: _getShellRotationAngle(),
                    pearlScale: _getPearlScale(),
                  ),
                ),
              ),
            ),
          ),

          // 4. Safe Area HUD Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _saveReportAndExit,
                        icon: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
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
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                        child: Text(
                          'CALM BREATH',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _isVoiceEnabled = !_isVoiceEnabled;
                              });
                            },
                            icon: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _isVoiceEnabled
                                    ? AppColors.primary.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                ),
                              ),
                              child: Icon(
                                _isVoiceEnabled
                                    ? Icons.record_voice_over
                                    : Icons.voice_over_off,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _toggleMute,
                            icon: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                ),
                              ),
                              child: Icon(
                                _isMuted ? Icons.volume_off : Icons.volume_up,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Central glassmorphic banner for instructions (Shifted slightly upward to not overlap shell)
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E3A8A).withOpacity(0.15),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          labelInstruction.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$countdown',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF93C5FD),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sound selector & footer controls
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
                              dropdownColor: const Color(0xFF051329),
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
                        _formatTime(_secondsRemaining),
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
                                (widget.durationSeconds - _secondsRemaining) /
                                widget.durationSeconds,
                            minHeight: 10,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(
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
                            onTap: _togglePlayPause,
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
                                _isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          glassButton(Icons.done_rounded, _saveReportAndExit),
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
  }
}

class ClamShellPainter extends CustomPainter {
  final double rotationAngle; // radians, e.g. 0 to -0.75
  final double pearlScale; // scale factor, e.g. 0.95 to 1.15

  ClamShellPainter({required this.rotationAngle, required this.pearlScale});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2 + 20);

    // Hinge/pivot point at the bottom of the clam shell
    final pivot = Offset(w / 2, h / 2 + 70);

    // Draw the glowing background aura
    final auraPaint = Paint()
      ..color = const Color(0xFF60A5FA).withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawCircle(center, 90.0, auraPaint);

    // 1. Draw Static Bottom Shell
    final bottomShellPaint = Paint()..style = PaintingStyle.fill;

    final bottomGradient = const RadialGradient(
      colors: [
        Color(0xFFC3DAF9),
        Color(0xFF6393D7),
        Color(0xFF285494),
      ],
      center: Alignment.bottomCenter,
      radius: 1.0,
    );
    bottomShellPaint.shader = bottomGradient.createShader(
      Rect.fromLTWH(0, h / 2, w, h / 2),
    );

    final bottomPath = Path();
    bottomPath.moveTo(pivot.dx - 30, pivot.dy);
    bottomPath.cubicTo(
      pivot.dx - 120,
      pivot.dy - 10,
      pivot.dx - 100,
      pivot.dy + 60,
      pivot.dx,
      pivot.dy + 65,
    );
    bottomPath.cubicTo(
      pivot.dx + 100,
      pivot.dy + 60,
      pivot.dx + 120,
      pivot.dy - 10,
      pivot.dx + 30,
      pivot.dy,
    );
    bottomPath.close();
    canvas.drawPath(bottomPath, bottomShellPaint);

    // Draw bottom shell ridges
    final ridgePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(bottomPath, ridgePaint);

    // 2. Draw Pulsing Pearl inside
    final pearlPos = Offset(w / 2, pivot.dy - 20);
    final pearlRadius = 24.0 * pearlScale;

    // Draw pearl glow
    final pearlGlow = Paint()
      ..color = const Color(0xFFFEE2E2).withOpacity(0.6 * (pearlScale - 0.8))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(pearlPos, pearlRadius * 1.5, pearlGlow);

    // Draw pearl body
    final pearlPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Colors.white, Color(0xFFFFF1F2), Color(0xFFFCA5A5)],
        stops: [0.0, 0.4, 1.0],
        center: Alignment(-0.3, -0.3),
      ).createShader(Rect.fromCircle(center: pearlPos, radius: pearlRadius));
    canvas.drawCircle(pearlPos, pearlRadius, pearlPaint);

    // Pearl outer shine stroke
    final pearlStroke = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(pearlPos, pearlRadius, pearlStroke);

    // 3. Draw Rotating Top Shell
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(rotationAngle);
    canvas.translate(-pivot.dx, -pivot.dy);

    final topShellPaint = Paint()..style = PaintingStyle.fill;

    final topGradient = const RadialGradient(
      colors: [
        Color(0xFFFBE8EB),
        Color(0xFFFFAEC1),
        Color(0xFFD64A72),
      ],
      center: Alignment.topCenter,
      radius: 1.1,
    );
    topShellPaint.shader = topGradient.createShader(
      Rect.fromLTWH(0, h / 2 - 120, w, h / 2),
    );

    final topPath = Path();
    topPath.moveTo(pivot.dx - 30, pivot.dy);
    topPath.cubicTo(
      pivot.dx - 130,
      pivot.dy - 10,
      pivot.dx - 120,
      pivot.dy - 110,
      pivot.dx,
      pivot.dy - 120,
    );
    topPath.cubicTo(
      pivot.dx + 120,
      pivot.dy - 110,
      pivot.dx + 130,
      pivot.dy - 10,
      pivot.dx + 30,
      pivot.dy,
    );
    topPath.close();
    canvas.drawPath(topPath, topShellPaint);

    // Draw top shell ridges and shell border
    final topRidgePaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(topPath, topRidgePaint);

    // Draw fan-like ridge lines from hinge to edge
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int angle = -45; angle <= 45; angle += 15) {
      final rad = angle * math.pi / 180;
      final targetX = pivot.dx + math.sin(rad) * 120;
      final targetY = pivot.dy - math.cos(rad) * 120;
      canvas.drawLine(pivot, Offset(targetX, targetY), linePaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ClamShellPainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.pearlScale != pearlScale;
  }
}

class _UnderwaterBubblesPainter extends CustomPainter {
  final List<BubbleModel> bubbles;
  final double animationValue;

  _UnderwaterBubblesPainter({
    required this.bubbles,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()..style = PaintingStyle.fill;

    for (final bubble in bubbles) {
      // Calculate animated vertical position
      final double totalMove = h + bubble.size * 2;
      final double progress = (animationValue * bubble.speed / 10.0) % 1.0;
      final double y = h + bubble.size - (progress * totalMove);
      final double x = bubble.left * w + math.sin(progress * 4 * math.pi) * 12;

      paint.shader =
          RadialGradient(
            colors: [
              Colors.white.withOpacity(0.4 * bubble.depthFactor),
              Colors.white.withOpacity(0.08 * bubble.depthFactor),
              Colors.white.withOpacity(0.0),
            ],
            stops: const [0.0, 0.7, 1.0],
          ).createShader(
            Rect.fromCircle(center: Offset(x, y), radius: bubble.size),
          );

      canvas.drawCircle(Offset(x, y), bubble.size, paint);

      // Draw bubble thin border
      final strokePaint = Paint()
        ..color = Colors.white.withOpacity(0.25 * bubble.depthFactor)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      canvas.drawCircle(Offset(x, y), bubble.size, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _UnderwaterBubblesPainter oldDelegate) => true;
}

class BubbleModel {
  final double left;
  final double size;
  final double speed;
  final double depthFactor;

  BubbleModel({
    required this.left,
    required this.size,
    required this.speed,
    required this.depthFactor,
  });
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
