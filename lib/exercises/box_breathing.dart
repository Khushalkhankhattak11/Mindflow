// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../constants/app_colors.dart';
import '../repositories/auth_repository.dart';
import '../services/service_locator.dart';
import '../services/audio_cache_service.dart';

class BoxBreathingScreen extends StatefulWidget {
  final int durationSeconds;
  final String backgroundImageUrl;
  final String backgroundSound;
  final String voiceGender;

  const BoxBreathingScreen({
    super.key,
    this.durationSeconds = 240, // Default 4 minutes
    this.backgroundImageUrl = '',
    this.backgroundSound = 'Silent',
    this.voiceGender = 'Female',
  });

  @override
  State<BoxBreathingScreen> createState() => _BoxBreathingScreenState();
}

class _BoxBreathingScreenState extends State<BoxBreathingScreen>
    with TickerProviderStateMixin {
  late final AudioPlayer _audioPlayer;
  late final FlutterTts _flutterTts;
  late final AnimationController _animationController;

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

  // Animation values
  String? _lastSpokenPhase;
  final double _boxSize = 250.0;

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

    // 16-second box breathing cycle: 4s inhale, 4s hold, 4s exhale, 4s hold
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );

    _animationController.addListener(() {
      setState(() {
        _handlePhaseTransitions();
      });
    });

    if (_isPlaying) {
      _animationController.repeat();
      _startSessionTimer();
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _animationController.dispose();
    _audioPlayer.dispose();
    _flutterTts.stop();
    super.dispose();
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
      HapticFeedback.lightImpact();

      // Calculate breath count (completed full 16-second cycle when transitioning back to Inhale)
      if (phase == 'Inhale') {
        _breathCount++;
      }

      if (_isVoiceEnabled) {
        _speakInstruction(phase);
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

  double _getCentralCircleScale() {
    final t = _animationController.value;
    if (t < 0.25) {
      // Inhale: swells from 1.0 to 1.4
      final p = t / 0.25;
      return 1.0 + 0.4 * p;
    } else if (t < 0.50) {
      // Hold full: stays at 1.4
      return 1.4;
    } else if (t < 0.75) {
      // Exhale: shrinks from 1.4 to 1.0
      final p = (t - 0.50) / 0.25;
      return 1.4 - 0.4 * p;
    } else {
      // Hold empty: stays at 1.0
      return 1.0;
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
        _startSessionTimer();
        _audioPlayer.resume();
      } else {
        _animationController.stop();
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
          exerciseName: 'Box Breathing',
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
    final double completedProgress =
        1.0 - (_secondsRemaining / widget.durationSeconds);
    final String currentInstruction = _getCurrentPhase();
    final int countdown = _getPhaseCountdown();
    final double circleScale = _getCentralCircleScale();

    return Scaffold(
      body: Stack(
        children: [
          // 1. Calming Gradient Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Color(0xFF2E0F5B), // Deep Purple
                    Color(0xFF140728), // Dark Indigo
                    Color(0xFF070210), // Rich Midnight Black
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
                        painter: _BackgroundPainter(
                          glow: _animationController.value,
                        ),
                        size: Size.infinite,
                      ),
                    )
                  : Image.network(widget.backgroundImageUrl, fit: BoxFit.cover),
            ),
          // Dark tint overlay for readability when image is present
          if (widget.backgroundImageUrl.isNotEmpty &&
              widget.backgroundImageUrl != 'animated_lotus_night')
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.55)),
            ),

          // Background particles (subtle grain/stars)
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: Image.network(
                'https://grainy-gradients.vercel.app/noise.svg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ),

          // 2. Safe Area Content
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
                          'BOX BREATHING',
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

                  // Central Animation Canvas
                  Expanded(
                    child: Center(
                      child: Container(
                        width: _boxSize + 60,
                        height: _boxSize + 60,
                        alignment: Alignment.center,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // The Box & Dot Custom Paint
                            SizedBox(
                              width: _boxSize,
                              height: _boxSize,
                              child: CustomPaint(
                                painter: BoxBreathingPainter(
                                  animationValue: _animationController.value,
                                  boxSize: _boxSize,
                                  activePhase: currentInstruction,
                                ),
                              ),
                            ),

                            // Central Pulsing Breathing Guide Circle
                            Transform.scale(
                              scale: circleScale,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.08),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF8B5CF6,
                                      ).withOpacity(0.2),
                                      blurRadius: 24,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      currentInstruction,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$countdown',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFC084FC),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Sound selector & settings
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
                              dropdownColor: const Color(0xFF140728),
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
                            value: completedProgress,
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

class BoxBreathingPainter extends CustomPainter {
  final double animationValue; // 0.0 to 1.0
  final double boxSize;
  final String activePhase;

  BoxBreathingPainter({
    required this.animationValue,
    required this.boxSize,
    required this.activePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final half = boxSize / 2;

    // Define the 4 corners of the box
    final topLeft = Offset(center.dx - half, center.dy - half);
    final topRight = Offset(center.dx + half, center.dy - half);
    final bottomRight = Offset(center.dx + half, center.dy + half);
    final bottomLeft = Offset(center.dx - half, center.dy + half);

    // Paints for different phases
    final inactiveLinePaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final activeLinePaint = Paint()
      ..color =
          const Color(0xFFC084FC) // Lavender glow for active line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Draw background (inactive) lines
    canvas.drawLine(topLeft, topRight, inactiveLinePaint);
    canvas.drawLine(topRight, bottomRight, inactiveLinePaint);
    canvas.drawLine(bottomRight, bottomLeft, inactiveLinePaint);
    canvas.drawLine(bottomLeft, topLeft, inactiveLinePaint);

    // Highlight active phase line
    if (activePhase == 'Inhale') {
      canvas.drawLine(topLeft, topRight, activeLinePaint);
    } else if (activePhase == 'Hold' &&
        animationValue >= 0.25 &&
        animationValue < 0.50) {
      canvas.drawLine(topRight, bottomRight, activeLinePaint);
    } else if (activePhase == 'Exhale') {
      canvas.drawLine(bottomRight, bottomLeft, activeLinePaint);
    } else {
      canvas.drawLine(bottomLeft, topLeft, activeLinePaint);
    }

    // Calculate moving orb position
    late Offset orbPosition;
    final t = animationValue;
    if (t < 0.25) {
      // Inhale: Top edge (Left to Right)
      final p = t / 0.25;
      orbPosition = Offset.lerp(topLeft, topRight, p)!;
    } else if (t < 0.50) {
      // Hold: Right edge (Top to Bottom)
      final p = (t - 0.25) / 0.25;
      orbPosition = Offset.lerp(topRight, bottomRight, p)!;
    } else if (t < 0.75) {
      // Exhale: Bottom edge (Right to Left)
      final p = (t - 0.50) / 0.25;
      orbPosition = Offset.lerp(bottomRight, bottomLeft, p)!;
    } else {
      // Hold: Left edge (Bottom to Top)
      final p = (t - 0.75) / 0.25;
      orbPosition = Offset.lerp(bottomLeft, topLeft, p)!;
    }

    // Draw glowing moving orb
    final glowPaint = Paint()
      ..color = const Color(0xFFD8B4FE).withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(orbPosition, 16.0, glowPaint);

    final orbPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(orbPosition, 8.0, orbPaint);
  }

  @override
  bool shouldRepaint(covariant BoxBreathingPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.activePhase != activePhase ||
        oldDelegate.boxSize != boxSize;
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
