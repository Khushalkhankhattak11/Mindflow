// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../repositories/auth_repository.dart';
import '../services/service_locator.dart';
import '../services/audio_cache_service.dart';
import '../constants/app_colors.dart';

class BubbleBreathingScreen extends StatefulWidget {
  final int durationSeconds;
  final String backgroundImageUrl;
  final String backgroundSound;
  final String voiceGender;

  const BubbleBreathingScreen({
    super.key,
    this.durationSeconds = 300,
    this.backgroundImageUrl = '',
    this.backgroundSound = 'Silent',
    this.voiceGender = 'Female',
  });

  @override
  State<BubbleBreathingScreen> createState() => _BubbleBreathingScreenState();
}

enum BreathPhase { inhale, hold, exhale }

class BubbleParticle {
  Offset position;
  double radius;
  double speed;
  double opacity;

  BubbleParticle({
    required this.position,
    required this.radius,
    required this.speed,
    required this.opacity,
  });
}

class _BubbleBreathingScreenState extends State<BubbleBreathingScreen>
    with TickerProviderStateMixin {
  //---------------------------------------------------
  // Audio & TTS
  //---------------------------------------------------
  late final AudioPlayer _audioPlayer;
  late final FlutterTts _flutterTts;
  bool _isMuted = false;
  bool _isVoiceEnabled = true;
  final List<String> _soundOptions = [
    'Silent',
    'Rain',
    'Wind',
    'Breeze',
    'Beach',
    'Fire',
  ];
  late String _currentSound;
  String? _lastSpokenPhase;
  int _breathCount = 0;

  //---------------------------------------------------
  // Animation Controllers
  //---------------------------------------------------
  late AnimationController orbController;
  late AnimationController backgroundController;
  late AnimationController particleController;

  late Animation<double> orbScale;

  //---------------------------------------------------
  // Breathing
  //---------------------------------------------------
  BreathPhase phase = BreathPhase.inhale;
  int countdown = 4;
  Timer? timer;
  bool playing = true;

  //---------------------------------------------------
  // Session
  //---------------------------------------------------
  late int totalSeconds;
  late int remainingSeconds;

  //---------------------------------------------------
  // Bubble Particles
  //---------------------------------------------------
  final Random random = Random();
  final List<BubbleParticle> particles = [];

  //---------------------------------------------------
  // Colors
  //---------------------------------------------------
  static const Color topColor = Color(0xff081B33);
  static const Color middleColor = Color(0xff103E65);
  static const Color bottomColor = Color(0xff1F7CFF);

  //---------------------------------------------------
  // Init
  //---------------------------------------------------
  @override
  void initState() {
    super.initState();
    totalSeconds = widget.durationSeconds;
    remainingSeconds = widget.durationSeconds;
    _currentSound = widget.backgroundSound;

    // Initialize TTS
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage('en-US');

    // Initialize background audio player
    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _playBackgroundSound();

    orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    particleController =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..addListener(updateParticles)
          ..repeat();

    orbScale = Tween<double>(
      begin: .75,
      end: 1.15,
    ).animate(CurvedAnimation(parent: orbController, curve: Curves.easeInOut));

    createParticles();
    startBreathing();
  }

  //---------------------------------------------------
  // Dispose
  //---------------------------------------------------
  @override
  void dispose() {
    timer?.cancel();
    orbController.dispose();
    backgroundController.dispose();
    particleController.dispose();
    _audioPlayer.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  //---------------------------------------------------
  // Create bubbles
  //---------------------------------------------------
  void createParticles() {
    particles.clear();
    for (int i = 0; i < 45; i++) {
      particles.add(
        BubbleParticle(
          position: Offset(
            random.nextDouble() * 400,
            random.nextDouble() * 900,
          ),
          radius: random.nextDouble() * 8 + 3,
          speed: random.nextDouble() * 1.3 + .3,
          opacity: random.nextDouble() * .5 + .2,
        ),
      );
    }
  }

  //---------------------------------------------------
  // Update particles
  //---------------------------------------------------
  void updateParticles() {
    if (!playing) return;
    for (final bubble in particles) {
      bubble.position = Offset(
        bubble.position.dx,
        bubble.position.dy - bubble.speed,
      );

      if (bubble.position.dy < -30) {
        bubble.position = Offset(random.nextDouble() * 400, 900);
      }
    }
    setState(() {});
  }

  //---------------------------------------------------
  // Audio Handling
  //---------------------------------------------------
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

  //---------------------------------------------------
  // Breathing Cycle
  //---------------------------------------------------
  void startBreathing() {
    orbController.forward();
    _handleSpeechGuide();

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!playing) return;

      setState(() {
        if (remainingSeconds > 0) {
          remainingSeconds--;
        } else {
          timer?.cancel();
          _saveReportAndExit();
          return;
        }

        countdown--;

        if (countdown <= 0) {
          switch (phase) {
            case BreathPhase.inhale:
              phase = BreathPhase.hold;
              countdown = 4;
              break;

            case BreathPhase.hold:
              phase = BreathPhase.exhale;
              countdown = 4;
              orbController.reverse();
              break;

            case BreathPhase.exhale:
              phase = BreathPhase.inhale;
              countdown = 4;
              _breathCount++;
              orbController.forward();
              break;
          }
          _handleSpeechGuide();
        }
      });
    });
  }

  void _handleSpeechGuide() {
    final currentPhaseStr = phaseText();
    if (currentPhaseStr != _lastSpokenPhase) {
      _lastSpokenPhase = currentPhaseStr;
      if (_isVoiceEnabled) {
        _speakInstruction(currentPhaseStr);
      }
    }
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

  void _saveReportAndExit() {
    locator<AuthRepository>()
        .saveQuickExerciseReport(
          exerciseName: 'Bubble Breathing',
          durationSeconds: widget.durationSeconds - remainingSeconds,
          breathCount: _breathCount,
        )
        .catchError((e) {
          debugPrint('Failed to save exercise report: $e');
        });

    Navigator.of(context).pop();
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

  void _togglePlayPause() {
    setState(() {
      playing = !playing;
      if (playing) {
        if (phase == BreathPhase.exhale) {
          orbController.reverse();
        } else {
          orbController.forward();
        }
        _audioPlayer.resume();
      } else {
        orbController.stop();
        _audioPlayer.pause();
      }
    });
  }

  //---------------------------------------------------
  // Text
  //---------------------------------------------------
  String phaseText() {
    switch (phase) {
      case BreathPhase.inhale:
        return 'Breathe In';

      case BreathPhase.hold:
        return 'Hold';

      case BreathPhase.exhale:
        return 'Breathe Out';
    }
  }

  String _formatTime(int totalSecs) {
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  //---------------------------------------------------
  // UI Widgets
  //---------------------------------------------------
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: backgroundController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  topColor,
                  Color.lerp(
                    middleColor,
                    Colors.indigo,
                    backgroundController.value,
                  )!,
                  bottomColor,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Ambient Background Image (if configured)
                if (widget.backgroundImageUrl.isNotEmpty)
                  Positioned.fill(
                    child: widget.backgroundImageUrl == 'animated_lotus_night'
                        ? AnimatedBuilder(
                            animation: backgroundController,
                            builder: (context, child) => CustomPaint(
                              painter: _BackgroundPainter(
                                glow: backgroundController.value,
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
                    child: Container(color: Colors.black.withOpacity(0.55)),
                  ),

                // Floating bubbles
                ...particles.map(
                  (bubble) => Positioned(
                    left: bubble.position.dx,
                    top: bubble.position.dy,
                    child: Container(
                      width: bubble.radius * 2,
                      height: bubble.radius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(bubble.opacity),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(.15),
                            blurRadius: 20,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SafeArea(
                  child: Column(
                    children: [
                      // Header Row
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Row(
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
                                'BUBBLE BREATHING',
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
                          ],
                        ),
                      ),

                      const Spacer(),

                      AnimatedBuilder(
                        animation: orbScale,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: orbScale.value,
                            child: Container(
                              width: 240,
                              height: 240,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withOpacity(.95),
                                    Colors.lightBlueAccent,
                                    Colors.blue.shade700,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(.5),
                                    blurRadius: 60,
                                    spreadRadius: 20,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(.2),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              // child: BackdropFilter(
                              //   filter: ImageFilter.blur(
                              //     sigmaX: 6,
                              //     sigmaY: 6,
                              //   ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      phaseText().toUpperCase(),
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 04),
                                    Text(
                                      '$countdown',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 64,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Ambient Selector Dropdown Pill
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
                              dropdownColor: const Color(0xFF081B33),
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

                      // Time Display
                      Text(
                        _formatTime(remainingSeconds),
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

                      // Progress Bar
                      SizedBox(
                        width: 220,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value:
                                (totalSeconds - remainingSeconds) /
                                totalSeconds,
                            minHeight: 10,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Control Buttons Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          glassButton(Icons.refresh, () {
                            setState(() {
                              remainingSeconds = totalSeconds;
                              countdown = 4;
                              phase = BreathPhase.inhale;
                              _breathCount = 0;
                              _lastSpokenPhase = null;
                              if (playing) {
                                orbController.forward();
                                _playBackgroundSound();
                              }
                            });
                          }),
                          const SizedBox(width: 24),
                          GestureDetector(
                            onTap: _togglePlayPause,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF7F56D9,
                                ), // Vibrant purple
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
                                playing
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

                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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
