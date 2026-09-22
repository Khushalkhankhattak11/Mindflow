// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../repositories/auth_repository.dart';
import '../services/service_locator.dart';
import '../services/audio_cache_service.dart';
import '../constants/app_colors.dart';

// ---------------------------------------------------------------------------
// Colours
// ---------------------------------------------------------------------------
const kInhale = Color(0xFF54C7F2); // cyan-blue
const kHold = Color(0xFFE84FEF); // magenta / pink
const kExhale = Color(0xFF9B7BEA); // purple
const kTextSoft = Color(0xFFC7CCE0);

enum Phase { inhale, hold, exhale }

class BreathCyle extends StatefulWidget {
  final int durationSeconds;
  final String backgroundImageUrl;
  final String backgroundSound;
  final String voiceGender;

  const BreathCyle({
    super.key,
    this.durationSeconds = 300,
    this.backgroundImageUrl = '',
    this.backgroundSound = 'Silent',
    this.voiceGender = 'Female',
  });

  @override
  State<BreathCyle> createState() => _BreathCyleState();
}

class _BreathCyleState extends State<BreathCyle> with TickerProviderStateMixin {
  static const int phaseSeconds = 4;
  static const int cycleSeconds = phaseSeconds * 3; // 12s full loop

  late final AnimationController _cycleController;
  late final AnimationController _pulseController;

  Timer? _timer;
  late int _remaining;
  bool _playing = true;

  //---------------------------------------------------
  // Audio & TTS
  //---------------------------------------------------
  late final AudioPlayer _audioPlayer;
  late final FlutterTts _flutterTts;
  bool _isMuted = false;
  bool _isVoiceEnabled = true;
  late String _currentSound;
  final List<String> _soundOptions = [
    'Silent',
    'Rain',
    'Wind',
    'Breeze',
    'Beach',
    'Fire',
  ];
  String? _lastSpokenPhase;
  int _breathCount = 0;

  @override
  void initState() {
    super.initState();
    _remaining = widget.durationSeconds;
    _currentSound = widget.backgroundSound;

    // Initialize TTS
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage('en-US');

    // Initialize AudioPlayer
    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _playBackgroundSound();

    _cycleController =
        AnimationController(
            vsync: this,
            duration: const Duration(seconds: cycleSeconds),
          )
          ..addListener(() {
            final value = _cycleController.value;
            final idx = (value * 3).floor() % 3;
            final currentPhase = Phase.values[idx];
            String phrase;
            if (currentPhase == Phase.inhale) {
              phrase = 'Breathe In';
            } else if (currentPhase == Phase.hold) {
              phrase = 'Hold';
            } else {
              phrase = 'Breathe Out';
            }

            if (phrase != _lastSpokenPhase) {
              if (_lastSpokenPhase == 'Breathe Out' && phrase == 'Breathe In') {
                _breathCount++;
              }
              _lastSpokenPhase = phrase;
              if (_playing && _isVoiceEnabled) {
                _speakInstruction(phrase);
              }
            }
          })
          ..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_playing) return;
      if (_remaining <= 0) {
        t.cancel();
        _saveReportAndExit();
        return;
      }
      setState(() => _remaining--);
    });
  }

  void _togglePlay() {
    setState(() {
      _playing = !_playing;
      if (_playing) {
        if (_remaining > 0) _startTimer();
        _cycleController.repeat();
        _pulseController.repeat(reverse: true);
        _audioPlayer.resume();
      } else {
        _cycleController.stop();
        _pulseController.stop();
        _audioPlayer.pause();
      }
    });
  }

  void _restart() {
    setState(() {
      _remaining = widget.durationSeconds;
      _playing = true;
      _breathCount = 0;
      _lastSpokenPhase = null;
      _cycleController
        ..reset()
        ..repeat();
      _pulseController.repeat(reverse: true);
      _playBackgroundSound();
    });
    _startTimer();
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
          exerciseName: 'Awake Breath',
          durationSeconds: widget.durationSeconds - _remaining,
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

  @override
  void dispose() {
    _cycleController.dispose();
    _pulseController.dispose();
    _timer?.cancel();
    _audioPlayer.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  String _fmt(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
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

  @override
  Widget build(BuildContext context) {
    final elapsed = widget.durationSeconds - _remaining;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ---- animated night background ----
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) => CustomPaint(
              painter: _BackgroundPainter(glow: _pulseController.value),
              size: Size.infinite,
            ),
          ),
          // Ambient Background Image (if configured)
          if (widget.backgroundImageUrl.isNotEmpty)
            Positioned.fill(
              child: Image.network(
                widget.backgroundImageUrl,
                fit: BoxFit.cover,
              ),
            ),
          // Dark tint overlay for readability when image is present
          if (widget.backgroundImageUrl.isNotEmpty)
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.55)),
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
                          'AWAKE BREATH',
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
                ),
                Expanded(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _cycleController,
                      _pulseController,
                    ]),
                    builder: (context, _) {
                      return _BreathingCircle(
                        cycleValue: _cycleController.value,
                        pulseValue: _pulseController.value,
                      );
                    },
                  ),
                ),
                // Standardized Footer Controls Block
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                            dropdownColor: const Color(0xFF150F30),
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
                      _fmt(_remaining),
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
                          value: elapsed / widget.durationSeconds,
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
                        glassButton(Icons.refresh, _restart),
                        const SizedBox(width: 24),
                        GestureDetector(
                          onTap: _togglePlay,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7F56D9), // Vibrant purple
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
                              _playing
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
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Breathing circle + lotus
// ---------------------------------------------------------------------------
class _BreathingCircle extends StatelessWidget {
  final double cycleValue; // 0..1 over full 12s loop
  final double pulseValue; // 0..1 slow pulse

  const _BreathingCircle({required this.cycleValue, required this.pulseValue});

  Phase get _phase {
    final idx = (cycleValue * 3).floor() % 3;
    return Phase.values[idx];
  }

  double get _phaseProgress => (cycleValue * 3) % 1.0;

  int get _countdown => 4 - (_phaseProgress * 4).floor();

  Color get _phaseColor {
    switch (_phase) {
      case Phase.inhale:
        return kInhale;
      case Phase.hold:
        return kHold;
      case Phase.exhale:
        return kExhale;
    }
  }

  String get _centerLabel {
    switch (_phase) {
      case Phase.inhale:
        return 'BREATHE IN';
      case Phase.hold:
        return 'HOLD';
      case Phase.exhale:
        return 'BREATHE OUT';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side =
            math.min(constraints.maxWidth, constraints.maxHeight) * 0.92;
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Lotus sits lower half, glowing on the water
                Positioned(
                  bottom: side * 0.02,
                  child: _Lotus(size: side * 0.6, pulse: pulseValue),
                ),
                // Ring track + moving dot + labels
                CustomPaint(
                  size: Size(side, side),
                  painter: _RingPainter(
                    cycleValue: cycleValue,
                    phaseColor: _phaseColor,
                  ),
                ),
                _RingLabel(
                  alignment: Alignment.topCenter,
                  offset: const Offset(0, 34),
                  title: 'INHALE',
                  subtitle: '4 SEC',
                  color: kInhale,
                  active: _phase == Phase.inhale,
                ),
                _RingLabel(
                  alignment: Alignment.centerRight,
                  offset: const Offset(-14, 6),
                  title: 'HOLD',
                  subtitle: '4 SEC',
                  color: kHold,
                  active: _phase == Phase.hold,
                  crossAxisAlignment: CrossAxisAlignment.end,
                ),
                _RingLabel(
                  alignment: Alignment.centerLeft,
                  offset: const Offset(14, 6),
                  title: 'EXHALE',
                  subtitle: '4 SEC',
                  color: kExhale,
                  active: _phase == Phase.exhale,
                  crossAxisAlignment: CrossAxisAlignment.start,
                ),
                // Center text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _centerLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_countdown',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 64,
                        fontWeight: FontWeight.w300,
                        shadows: [
                          Shadow(
                            color: _phaseColor.withOpacity(.8),
                            blurRadius: 30,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RingLabel extends StatelessWidget {
  final Alignment alignment;
  final Offset offset;
  final String title;
  final String subtitle;
  final Color color;
  final bool active;
  final CrossAxisAlignment crossAxisAlignment;

  const _RingLabel({
    required this.alignment,
    required this.offset,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.active,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: offset,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: active ? 1 : 0.55,
          child: Column(
            crossAxisAlignment: crossAxisAlignment,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  letterSpacing: 1.5,
                  shadows: active
                      ? [Shadow(color: color.withOpacity(.8), blurRadius: 12)]
                      : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: kTextSoft, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ring painter — gradient track, static anchor dots, moving glow indicator
// ---------------------------------------------------------------------------
class _RingPainter extends CustomPainter {
  final double cycleValue;
  final Color phaseColor;

  _RingPainter({required this.cycleValue, required this.phaseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // gradient track
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [kInhale, kHold, kExhale, kInhale],
        stops: [0.0, 0.34, 0.67, 1.0],
        transform: GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawCircle(center, radius, trackPaint);

    // faint outer glow ring
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
      ..shader = SweepGradient(
        colors: [
          kInhale.withOpacity(.25),
          kHold.withOpacity(.25),
          kExhale.withOpacity(.25),
          kInhale.withOpacity(.25),
        ],
        stops: const [0.0, 0.34, 0.67, 1.0],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawCircle(center, radius, glowPaint);

    // three anchor dots at -90°, 30°, 150°
    _drawAnchor(canvas, center, radius, -math.pi / 2, kInhale, true);
    _drawAnchor(canvas, center, radius, math.pi / 6, kHold, false);
    _drawAnchor(canvas, center, radius, 5 * math.pi / 6, kExhale, false);

    // moving indicator dot
    final angle = -math.pi / 2 + cycleValue * 2 * math.pi;
    final dotCenter = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    final dotGlow = Paint()
      ..color = phaseColor.withOpacity(.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(dotCenter, 14, dotGlow);
    final dotCore = Paint()..color = Colors.white;
    canvas.drawCircle(dotCenter, 6, dotCore);
    final dotRing = Paint()
      ..color = phaseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(dotCenter, 9, dotRing);
  }

  void _drawAnchor(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
    Color color,
    bool filled,
  ) {
    final p = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    final glow = Paint()
      ..color = color.withOpacity(.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(p, 8, glow);
    final ring = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(p, 6, ring);
    if (filled) {
      canvas.drawCircle(p, 2.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.cycleValue != cycleValue ||
      oldDelegate.phaseColor != phaseColor;
}

// ---------------------------------------------------------------------------
// Glowing lotus flower (fully painted, no image assets needed)
// ---------------------------------------------------------------------------
class _Lotus extends StatelessWidget {
  final double size;
  final double pulse; // 0..1

  const _Lotus({required this.size, required this.pulse});

  @override
  Widget build(BuildContext context) {
    final scale = 0.96 + pulse * 0.06;
    return Transform.scale(
      scale: scale,
      child: CustomPaint(
        size: Size(size, size),
        painter: _LotusPainter(glow: pulse),
      ),
    );
  }
}

class _LotusPainter extends CustomPainter {
  final double glow;
  _LotusPainter({required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.62);
    final rng = math.Random(7);

    // soft ambient glow behind flower
    final ambient = Paint()
      ..color = const Color(0xFFC59CFF).withOpacity(0.18 + glow * 0.1)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.18);
    canvas.drawCircle(center, size.width * 0.42, ambient);

    void petalRing(
      int count,
      double lenFactor,
      double widthFactor,
      double angleOffset,
      List<Color> colors,
    ) {
      for (int i = 0; i < count; i++) {
        final angle = angleOffset + (2 * math.pi / count) * i - math.pi / 2;
        final len = size.width * lenFactor;
        final wid = size.width * widthFactor;
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(angle);

        final path = Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(wid, -len * 0.55, 0, -len)
          ..quadraticBezierTo(-wid, -len * 0.55, 0, 0)
          ..close();

        final gradient = Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: colors,
          ).createShader(Rect.fromLTWH(-wid, -len, wid * 2, len));
        canvas.drawPath(path, gradient);

        final edge = Paint()
          ..color = Colors.white.withOpacity(0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawPath(path, edge);
        canvas.restore();
      }
    }

    // outer ring - larger, deep purple-blue petals
    petalRing(9, 0.5, 0.16, 0.0, [
      const Color(0xFF6E4FD9).withOpacity(0.9),
      const Color(0xFFB58BFF).withOpacity(0.95),
    ]);

    // mid ring
    petalRing(8, 0.38, 0.13, math.pi / 8, [
      const Color(0xFF9A6BEF).withOpacity(0.9),
      const Color(0xFFE6B9FF).withOpacity(0.95),
    ]);

    // inner ring - bright pink/white petals
    petalRing(7, 0.24, 0.1, math.pi / 6, [
      const Color(0xFFE79BFF).withOpacity(0.95),
      Colors.white.withOpacity(0.98),
    ]);

    // glowing core
    final core = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withOpacity(0.95 + glow * 0.05),
              const Color(0xFFFFD9A0).withOpacity(0.6),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: center,
              radius: size.width * (0.14 + glow * 0.02),
            ),
          );
    canvas.drawCircle(center, size.width * (0.14 + glow * 0.02), core);

    // sparkles
    for (int i = 0; i < 26; i++) {
      final a = rng.nextDouble() * 2 * math.pi;
      final r = rng.nextDouble() * size.width * 0.32;
      final p = Offset(
        center.dx + r * math.cos(a),
        center.dy + r * math.sin(a) * 0.7 - size.width * 0.1,
      );
      final rawOpacity = 0.3 + 0.5 * ((math.sin(a * 3 + glow * 6) + 1) / 2);
      final opacity = rawOpacity < 0.0
          ? 0.0
          : (rawOpacity > 1.0 ? 1.0 : rawOpacity);
      canvas.drawCircle(
        p,
        rng.nextDouble() * 1.4 + 0.4,
        Paint()..color = Colors.white.withOpacity(opacity),
      );
    }

    // gentle water ripples under the flower
    final rippleY = size.height * 0.88;
    for (int i = 0; i < 3; i++) {
      final rp = Paint()
        ..color = const Color(0xFFB58BFF).withOpacity(0.12 - i * 0.03)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx, rippleY),
          width: size.width * (0.55 + i * 0.22),
          height: size.height * (0.05 + i * 0.015),
        ),
        rp,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LotusPainter oldDelegate) =>
      oldDelegate.glow != glow;
}

// ---------------------------------------------------------------------------
// Night sky / water background
// ---------------------------------------------------------------------------
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
