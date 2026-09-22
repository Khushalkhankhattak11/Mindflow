import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';

class BreathingResultView extends StatelessWidget {
  final String exerciseTitle;
  final int durationSeconds;
  final String backgroundSound;
  final String soundEffect;
  final String voiceGender;

  const BreathingResultView({
    super.key,
    required this.exerciseTitle,
    required this.durationSeconds,
    required this.backgroundSound,
    required this.soundEffect,
    required this.voiceGender,
  });

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')} min';
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.primary;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Ambient Calming Radial Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Color(0xFF4C2A9E), // Inner warm purple
                    Color(0xFF23005C), // Deep Indigo background
                  ],
                  center: Alignment.center,
                  radius: 1.1,
                ),
              ),
            ),
          ),

          // Noise texture overlay for premium feel
          Positioned.fill(
            child: Opacity(
              opacity: 0.015,
              child: Image.network(
                'https://grainy-gradients.vercel.app/noise.svg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ),

          // Main Canvas
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 16),

                  // Header checkmark & title
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Glowing checkmark container
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha(20),
                          border: Border.all(
                            color: Colors.white.withAlpha(80),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withAlpha(100),
                              blurRadius: 36,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Completion Titles
                      Text(
                        'Beautifully Done',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You successfully completed your breathing exercise.',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: Colors.white.withAlpha(180),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),

                  // Session Stats Summary Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'SESSION SUMMARY',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withAlpha(120),
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                label: 'Exercise Focus',
                                value: exerciseTitle,
                                icon: Icons.spa_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                  label: 'Duration',
                                  value: _formatDuration(durationSeconds),
                                  icon: Icons.timer_outlined),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                label: 'Sound Ambient',
                                value: backgroundSound,
                                icon: Icons.waves_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                label: 'Guide Voice',
                                value: '$voiceGender Voice',
                                icon: Icons.mic_none_rounded,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Closing motivational message & button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Quote
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '"Mindfulness is not a destination, it is a way of being. Carry this calmness into the rest of your day."',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: Colors.white.withAlpha(150),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Back to Home Button
                      GestureDetector(
                        onTap: () {
                          // Pop back to the main home screen (pops exercise view and result view)
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        child: Container(
                          width: double.infinity,
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
                            'Back to Home',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
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

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withAlpha(26),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white.withAlpha(150), size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: GoogleFonts.manrope(
                    color: Colors.white.withAlpha(130),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
