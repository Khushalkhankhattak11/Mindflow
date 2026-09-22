// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBg,
      body: Stack(
        children: [
          // Background Gradient Glow Decorative Elements
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryContainer.withOpacity(0.08),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Custom Navigation Bar
                _buildAppBar(context),

                // Content Body
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 12.0,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Hero Banner
                            _buildHeroHeader(),

                            const SizedBox(height: 24),

                            // Section 1: Information We Collect
                            _buildSectionCard(
                              icon: Icons.shield_outlined,
                              iconColor: const Color(0xFF6B38D4),
                              title: 'Information We Collect',
                              children: [
                                _buildParagraph(
                                  'We collect information that helps us personalize your journey toward mindfulness. This includes basic account details such as your name and email address, which allow us to sync your progress across devices.',
                                ),
                                const SizedBox(height: 12),
                                _buildParagraph(
                                  'Additionally, we process session data—such as meditation duration, preferred ambient sounds, and frequency of use—to refine our recommendations and ensure your experience remains deeply relevant to your personal needs.',
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Section 2: How We Use Your Data
                            _buildSectionCard(
                              icon: Icons.auto_awesome_outlined,
                              iconColor: const Color(0xFF8455EF),
                              title: 'How We Use Your Data',
                              children: [
                                _buildParagraph(
                                  'Your data is used exclusively to enhance the MindFlow ecosystem. We analyze aggregated, de-identified session metrics to understand which meditations are most effective at reducing stress levels across our community.',
                                ),
                                const SizedBox(height: 16),
                                _buildCheckItem(
                                  'Personalizing your daily meditation path based on time of day and history.',
                                ),
                                const SizedBox(height: 10),
                                _buildCheckItem(
                                  'Communicating mindfulness tips and system updates via occasional notifications.',
                                ),
                                const SizedBox(height: 10),
                                _buildCheckItem(
                                  "Improving our audio engine's performance on your specific device hardware.",
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Section 3: Your Choices
                            _buildSectionCard(
                              icon: Icons.tune_rounded,
                              iconColor: const Color(0xFF2E0052),
                              title: 'Your Choices',
                              children: [
                                _buildParagraph(
                                  "Control over your digital footprint is essential to peace of mind. You have the right to access, export, or request the deletion of your personal data at any time through the 'Privacy' tab in your user profile settings.",
                                ),
                                const SizedBox(height: 16),
                                // Highlighted Note Card
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF8E1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFFFE082),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.info_outline_rounded,
                                        color: Color(0xFFF57F17),
                                        size: 22,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'Note: ',
                                                style: GoogleFonts.manrope(
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(
                                                    0xFF5D4037,
                                                  ),
                                                  fontSize: 13.5,
                                                ),
                                              ),
                                              TextSpan(
                                                text:
                                                    'Opting out of data collection may limit the effectiveness of our personalized recommendation engine, as the app will not be able to learn from your specific meditation patterns.',
                                                style: GoogleFonts.manrope(
                                                  color: const Color(
                                                    0xFF5D4037,
                                                  ),
                                                  fontSize: 13.5,
                                                  height: 1.45,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Section 4: Data Security
                            _buildSectionCard(
                              icon: Icons.lock_outline_rounded,
                              iconColor: const Color(0xFF27AE60),
                              title: 'Data Security',
                              children: [
                                _buildParagraph(
                                  'While we strive for transparency, the architecture of MindFlow is designed with silent protection in mind. We employ industry-standard encryption protocols for all data in transit and at rest. Access to user information is strictly limited to essential personnel committed to our privacy standards.',
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Acknowledgment Banner
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withOpacity(0.08),
                                    AppColors.primaryContainer.withOpacity(
                                      0.04,
                                    ),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.verified_outlined,
                                      color: AppColors.primary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      'By continuing to use MindFlow, you acknowledge that you have read and understood this policy.',
                                      style: GoogleFonts.manrope(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.assessmentTextPrimary,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Bottom Buttons
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'I Understand',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Copyright Footer
                            Center(
                              child: Text(
                                '© 2023 MindFlow Inc. All rights reserved.',
                                style: GoogleFonts.manrope(
                                  fontSize: 12.5,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(10),
              elevation: 2,
              shadowColor: Colors.black12,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Privacy Policy',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.assessmentTextPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_person_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Secure',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E0052), Color(0xFF6B38D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B38D4).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'Last Updated: July 08, 2026',
                  style: GoogleFonts.manrope(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.privacy_tip_rounded,
                color: Colors.white70,
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'MindFlow Privacy Policy',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Our Commitment to Your Stillness',
            style: GoogleFonts.manrope(
              fontSize: 15,
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFE9DEF5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.assessmentTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0E8FA)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 14.5,
        color: AppColors.assessmentTextSecondary,
        height: 1.6,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2.0),
          child: Icon(
            Icons.check_circle,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AppColors.assessmentTextPrimary,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
