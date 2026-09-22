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

class WaveAnimationScreen extends StatefulWidget {
  final int durationSeconds;
  final String backgroundImageUrl;
  final String backgroundSound;
  final String voiceGender;

  const WaveAnimationScreen({
    super.key,
    this.durationSeconds = 300, // Default 5 minutes
    this.backgroundImageUrl = '',
    this.backgroundSound = 'Silent',
    this.voiceGender = 'Female',
  });

  @override
  State<WaveAnimationScreen> createState() => _WaveAnimationScreenState();
}

class _WaveAnimationScreenState extends State<WaveAnimationScreen>
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

    // 10-second wave breathing cycle: 5s inhale (rising), 5s exhale (falling)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
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

      // Increment breath count when starting a new Inhale
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
    return t < 0.50 ? 'Inhale' : 'Exhale';
  }

  int _getPhaseCountdown() {
    final t = _animationController.value;
    final phaseTime = t < 0.50 ? t : t - 0.50;
    final progress = phaseTime / 0.50;
    return 5 - (progress * 5).floor();
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
          exerciseName: 'Wave Breathing',
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

    return Scaffold(
      body: Stack(
        children: [
          // 1. Beautiful Deep Ocean Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0F3B46), // Deep ocean teal
                    Color(0xFF071F26), // Mid deep teal
                    Color(0xFF020B0D), // Dark marine black
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
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

          // Noise texture overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.02,
              child: Image.network(
                'https://grainy-gradients.vercel.app/noise.svg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ),

          // 2. Animated Custom Paint for Waves and Guided Path
          Positioned.fill(
            child: CustomPaint(
              painter: WaveBreathingPainter(
                animationValue: _animationController.value,
                activePhase: currentInstruction,
              ),
            ),
          ),

          // 3. UI Control Overlay
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
                          'WAVE BREATHING',
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

                  // Central glassmorphic badge for instructions (Elevated in the middle)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0E7490).withOpacity(0.15),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentInstruction.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$countdown',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF22D3EE),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sound Selector & Controls
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
                              dropdownColor: const Color(0xFF071F26),
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

class WaveBreathingPainter extends CustomPainter {
  final double animationValue; // 0.0 to 1.0 (over 10 seconds)
  final String activePhase;

  WaveBreathingPainter({
    required this.animationValue,
    required this.activePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw central guide scrolling wave
    final centerY = h * 0.45;
    final waveAmplitude = h * 0.08;
    final wavelength = w * 1.0;

    final guidePaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final guidePath = Path();
    for (double x = 0; x <= w; x += 2) {
      // Guide path equation (scrolling wave)
      final angle =
          (animationValue * 2 * math.pi) +
          ((x - w / 2) / wavelength * 2 * math.pi);
      final y = centerY - math.cos(angle) * waveAmplitude;
      if (x == 0) {
        guidePath.moveTo(x, y);
      } else {
        guidePath.lineTo(x, y);
      }
    }
    canvas.drawPath(guidePath, guidePaint);

    // Draw vertical centerline indicator
    final centerPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw dashed vertical line
    const dashHeight = 6.0;
    const dashGap = 6.0;
    double currentY = centerY - waveAmplitude - 30;
    final targetY = centerY + waveAmplitude + 30;
    while (currentY < targetY) {
      canvas.drawLine(
        Offset(w / 2, currentY),
        Offset(w / 2, currentY + dashHeight),
        centerPaint,
      );
      currentY += dashHeight + dashGap;
    }

    // Calculate breath guide particle/orb position (at x = center_x)
    final particleAngle = animationValue * 2 * math.pi;
    final particleY = centerY - math.cos(particleAngle) * waveAmplitude;
    final particlePos = Offset(w / 2, particleY);

    // Draw particle glowing shadow
    final particleGlow = Paint()
      ..color = const Color(0xFF22D3EE).withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(particlePos, 18.0, particleGlow);

    // Draw particle core
    final particleCore = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(particlePos, 8.0, particleCore);

    // DRAW OVERLAPPING BOTTOM FLUID WAVES
    // Dynamic swell/tide height based on breathing progress (swells during Inhale, recedes during Exhale)
    // swell factor: goes from 0.0 (trough) to 1.0 (crest)
    final double swellFactor =
        (-math.cos(animationValue * 2 * math.pi) + 1.0) / 2.0;
    final double baseTideHeight = h * 0.76;
    final double activeTideHeight = baseTideHeight - (swellFactor * 50.0);

    // We draw 3 bottom fluid waves with different speeds, frequencies, and colors
    _drawFluidWave(
      canvas: canvas,
      width: w,
      height: h,
      tideHeight: activeTideHeight + 10,
      amplitude: 15.0,
      phaseShift: animationValue * 3 * math.pi,
      frequencyMultiplier: 1.2,
      color: const Color(0xFF0891B2).withOpacity(0.25), // Lighter Cyan Wave
    );

    _drawFluidWave(
      canvas: canvas,
      width: w,
      height: h,
      tideHeight: activeTideHeight - 5,
      amplitude: 18.0,
      phaseShift: -animationValue * 2.5 * math.pi + 1.5,
      frequencyMultiplier: 0.9,
      color: const Color(0xFF06B6D4).withOpacity(0.18), // Cyan wave
    );

    _drawFluidWave(
      canvas: canvas,
      width: w,
      height: h,
      tideHeight: activeTideHeight + 5,
      amplitude: 12.0,
      phaseShift: animationValue * 1.8 * math.pi + 3.0,
      frequencyMultiplier: 1.5,
      color: const Color(0xFF0E7490).withOpacity(0.35), // Deeper Ocean Wave
    );
  }

  void _drawFluidWave({
    required Canvas canvas,
    required double width,
    required double height,
    required double tideHeight,
    required double amplitude,
    required double phaseShift,
    required double frequencyMultiplier,
    required Color color,
  }) {
    final wavePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, height);
    path.lineTo(0, tideHeight);

    for (double x = 0; x <= width; x += 4) {
      final angle =
          phaseShift + (x / width * 2 * math.pi * frequencyMultiplier);
      final y = tideHeight - math.sin(angle) * amplitude;
      path.lineTo(x, y);
    }

    path.lineTo(width, height);
    path.close();

    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant WaveBreathingPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.activePhase != activePhase;
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
