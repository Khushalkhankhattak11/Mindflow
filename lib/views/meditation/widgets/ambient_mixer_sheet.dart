// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_colors.dart';

class AmbientSoundTrack {
  final String id;
  final String title;
  final IconData icon;
  final String audioAsset;
  final Color color;

  AmbientSoundTrack({
    required this.id,
    required this.title,
    required this.icon,
    required this.audioAsset,
    required this.color,
  });
}

class AmbientMixerSheet extends StatefulWidget {
  final double voiceVolume;
  final double ambientVolume;
  final ValueChanged<double> onVoiceVolumeChanged;
  final ValueChanged<double> onAmbientVolumeChanged;
  final ValueChanged<String> onAmbientTrackSelected;
  final String selectedAmbientTrack;

  const AmbientMixerSheet({
    super.key,
    required this.voiceVolume,
    required this.ambientVolume,
    required this.onVoiceVolumeChanged,
    required this.onAmbientVolumeChanged,
    required this.onAmbientTrackSelected,
    required this.selectedAmbientTrack,
  });

  @override
  State<AmbientMixerSheet> createState() => _AmbientMixerSheetState();
}

class _AmbientMixerSheetState extends State<AmbientMixerSheet> {
  late double _voiceVol;
  late double _ambientVol;
  late String _currentTrackId;

  final List<AmbientSoundTrack> _tracks = [
    AmbientSoundTrack(
      id: 'rain',
      title: 'Soft Rain',
      icon: Icons.water_drop_rounded,
      audioAsset: 'rain.mp3',
      color: const Color(0xFF3F51B5),
    ),
    AmbientSoundTrack(
      id: 'ocean',
      title: 'Ocean Waves',
      icon: Icons.waves_rounded,
      audioAsset: 'beach.mp3',
      color: const Color(0xFF00ACC1),
    ),
    AmbientSoundTrack(
      id: 'breeze',
      title: 'Forest Wind',
      icon: Icons.air_rounded,
      audioAsset: 'breeze.mp3',
      color: const Color(0xFF27AE60),
    ),
    AmbientSoundTrack(
      id: 'fire',
      title: 'Cozy Fire',
      icon: Icons.local_fire_department_rounded,
      audioAsset: 'fire.mp3',
      color: const Color(0xFFE67E22),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _voiceVol = widget.voiceVolume;
    _ambientVol = widget.ambientVolume;
    _currentTrackId = widget.selectedAmbientTrack.isEmpty ? 'rain' : widget.selectedAmbientTrack;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle Bar
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ambient Sound Mixer',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.assessmentTextPrimary,
                      ),
                    ),
                    Text(
                      'Blend background soundscapes beneath voice guided sessions',
                      style: GoogleFonts.manrope(
                        fontSize: 12.5,
                        color: AppColors.assessmentTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFF0E8FA)),
          const SizedBox(height: 24),

          // Track selector grid
          Text(
            'Select Background Soundscape',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.assessmentTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _tracks.map((track) {
              final isSelected = _currentTrackId == track.id;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentTrackId = track.id;
                    });
                    widget.onAmbientTrackSelected(track.id);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? track.color : const Color(0xFFF5F3F8),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? track.color : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: track.color.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          track.icon,
                          color: isSelected ? Colors.white : AppColors.assessmentTextSecondary,
                          size: 24,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          track.title,
                          style: GoogleFonts.manrope(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.assessmentTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          // Sliders Section
          // 1. Voice Guide Volume
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.record_voice_over_rounded, size: 20, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    'Voice Guide Volume',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.assessmentTextPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '${(_voiceVol * 100).toInt()}%',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withOpacity(0.15),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.2),
            ),
            child: Slider(
              value: _voiceVol,
              min: 0.0,
              max: 1.0,
              onChanged: (val) {
                setState(() => _voiceVol = val);
                widget.onVoiceVolumeChanged(val);
              },
            ),
          ),

          const SizedBox(height: 16),

          // 2. Ambient Layer Volume
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.blur_on_rounded, size: 20, color: Color(0xFF00ACC1)),
                  const SizedBox(width: 10),
                  Text(
                    'Ambient Soundscape Volume',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.assessmentTextPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '${(_ambientVol * 100).toInt()}%',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00ACC1),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF00ACC1),
              inactiveTrackColor: const Color(0xFF00ACC1).withOpacity(0.15),
              thumbColor: const Color(0xFF00ACC1),
              overlayColor: const Color(0xFF00ACC1).withOpacity(0.2),
            ),
            child: Slider(
              value: _ambientVol,
              min: 0.0,
              max: 1.0,
              onChanged: (val) {
                setState(() => _ambientVol = val);
                widget.onAmbientVolumeChanged(val);
              },
            ),
          ),

          const SizedBox(height: 24),

          // Done Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Apply Mixer Settings',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
