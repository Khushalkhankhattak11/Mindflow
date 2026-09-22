import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_colors.dart';
import '../../../viewmodels/home_viewmodel.dart';

class MoodTrackerCard extends StatelessWidget {
  final HomeViewModel viewModel;

  const MoodTrackerCard({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final activeFeeling = viewModel.data.activeFeeling;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(102),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withAlpha(77), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(10),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How are you feeling today?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.assessmentTextPrimary,
            ),
          ),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
            children: [
              _buildFeelingBtn(
                'happy',
                '😊',
                'Happy',
                activeFeeling == 'happy',
              ),
              _buildFeelingBtn('calm', '😌', 'Calm', activeFeeling == 'calm'),
              _buildFeelingBtn(
                'grateful',
                '❤️',
                'Grateful',
                activeFeeling == 'grateful',
              ),
              _buildFeelingBtn(
                'motivated',
                '🎯',
                'Motivated',
                activeFeeling == 'motivated',
              ),
              _buildFeelingBtn(
                'tired',
                '😴',
                'Tired',
                activeFeeling == 'tired',
              ),
              _buildFeelingBtn(
                'distracted',
                '😶',
                'Distracted',
                activeFeeling == 'distracted',
              ),
              _buildFeelingBtn(
                'stressed',
                '😰',
                'Stressed',
                activeFeeling == 'stressed',
              ),
              _buildFeelingBtn(
                'anxious',
                '😟',
                'Anxious',
                activeFeeling == 'anxious',
              ),
              _buildFeelingBtn(
                'overwhelmed',
                '🤯',
                'Overwhelmed',
                activeFeeling == 'overwhelmed',
              ),
              _buildFeelingBtn('sad', '😔', 'Sad', activeFeeling == 'sad'),
              _buildFeelingBtn(
                'angry',
                '😡',
                'Angry',
                activeFeeling == 'angry',
              ),
              _buildFeelingBtn(
                'lonely',
                '🤍',
                'Lonely',
                activeFeeling == 'lonely',
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFF3F3F4), height: 1),
          const SizedBox(height: 16),
          Text(
            '"Happiness is not something ready-made. It comes from your own actions."',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppColors.assessmentTextSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeelingBtn(
    String feelingName,
    String emoji,
    String label,
    bool isSelected,
  ) {
    final primaryColor = AppColors.primary;

    return GestureDetector(
      onTap: () => viewModel.selectFeeling(feelingName),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withAlpha(26) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor.withAlpha(51) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? primaryColor
                    : AppColors.assessmentTextSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
