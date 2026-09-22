import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../widgets/scale_pressed_button.dart';
import '../auth/welcome/welcome_view.dart';
import '../progress/progress_view.dart';
import 'notification_settings_view.dart';
import 'privacy_policy_view.dart';
import 'download_manager_view.dart';
import 'favorites_view.dart';

class ProfileContent extends StatefulWidget {
  const ProfileContent({super.key});

  @override
  State<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent> {
  ProfileViewModel? _viewModel;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = context.read<ProfileViewModel>();
    if (_viewModel != vm) {
      _viewModel?.removeListener(_onStateChanged);
      _viewModel = vm;
      _viewModel?.addListener(_onStateChanged);
    }
  }

  void _onStateChanged() {
    if (_viewModel?.loggedOut == true && mounted) {
      // Clear logged out status and redirect to WelcomeView onboarding screen
      _viewModel?.clearLoggedOut();
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const WelcomeView(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
        (route) => false,
      );
    }
  }

  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Delete Account?',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete your account? This action is permanent and cannot be undone.',
            style: GoogleFonts.manrope(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _viewModel?.deleteAccount();
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_onStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();
    final profile = viewModel.profile;
    final secondaryTextColor = AppColors.assessmentTextSecondary;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: Center(
              child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 1. Profile Photo Header with premium verified badge
                        Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF8455EF),
                                    Color(0xFF6860EF),
                                  ],
                                ),
                              ),
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  image: DecorationImage(
                                    image: _getAvatarImageProvider(
                                      profile.photoUrl,
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            // Verified premium badge
                            if (profile.isPremium)
                              Transform.translate(
                                offset: const Offset(0, 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF8455EF),
                                        Color(0xFF6860EF),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.verified,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Premium',
                                        style: GoogleFonts.manrope(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          profile.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.assessmentTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.email,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // 2. Bento Stats Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                profile.dayStreak.toString(),
                                'Day Streak',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                profile.sessionsCount.toString(),
                                'Sessions',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                profile.mindfulHours,
                                'Mindful',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // 3. Settings Card List
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(153),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: Colors.white.withAlpha(77),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Edit Profile
                              _buildSettingItem(
                                label: 'Edit Profile',
                                desc: 'Update your display name',
                                icon: Icons.person_outline_rounded,
                                onTap: _showEditProfileDialog,
                              ),
                              // My Favorites
                              _buildSettingItem(
                                label: 'My Favorites',
                                desc: 'Saved meditation sessions & exercises',
                                icon: Icons.favorite_border_rounded,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const FavoritesView(),
                                    ),
                                  );
                                },
                              ),
                              // Change Password
                              _buildSettingItem(
                                label: 'Change Password',
                                desc: 'Secure your account password',
                                icon: Icons.vpn_key_outlined,
                                onTap: _showChangePasswordDialog,
                              ),
                              // Notifications
                              _buildSettingItem(
                                label: 'Notifications',
                                desc: 'Manage alerts and reminders',
                                icon: Icons.notifications_none_outlined,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const NotificationSettingsView(),
                                    ),
                                  );
                                },
                              ),
                              // Privacy & Security
                              _buildSettingItem(
                                label: 'Privacy & Security',
                                desc: 'Biometrics and data control',
                                icon: Icons.lock_outline_rounded,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const PrivacyPolicyView(),
                                    ),
                                  );
                                },
                              ),

                              // Offline Downloads
                              _buildSettingItem(
                                label: 'Offline Downloads',
                                desc: 'Manage saved audio & sessions',
                                icon: Icons.download_done_rounded,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const DownloadManagerView(),
                                    ),
                                  );
                                },
                              ),

                              // Terms & Conditions
                              _buildSettingItem(
                                label: 'Terms & Conditions',
                                desc: 'User agreement and policies',
                                icon: Icons.description_outlined,
                                onTap: _showTermsDialog,
                              ),

                              // Help & Support
                              _buildSettingItem(
                                label: 'Help & Support',
                                desc: 'FAQ and contact center',
                                icon: Icons.help_outline_rounded,
                              ),

                              // About Us
                              _buildSettingItem(
                                label: 'About Us',
                                desc: 'Version info and details',
                                icon: Icons.info_outline_rounded,
                                onTap: _showAboutUsDialog,
                              ),
                              // Feedback
                              _buildSettingItem(
                                label: 'Send Feedback',
                                desc: 'Tell us about your experience',
                                icon: Icons.feedback_outlined,
                                onTap: _showFeedbackDialog,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 4. Logout Action Button
                        GestureDetector(
                          onTap: viewModel.isLoggingOut
                              ? null
                              : viewModel.logout,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFDAD6).withAlpha(128),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: const Color(0xFFBA1A1A).withAlpha(26),
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: viewModel.isLoggingOut
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFBA1A1A),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.logout,
                                        color: Color(0xFFBA1A1A),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Logout',
                                        style: GoogleFonts.manrope(
                                          color: const Color(0xFFBA1A1A),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 4b. Delete Account Action Button
                        GestureDetector(
                          onTap: viewModel.isDeleting
                              ? null
                              : _showDeleteAccountConfirmation,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: const Color(0xFFBA1A1A).withAlpha(51),
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: viewModel.isDeleting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFBA1A1A),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.delete_forever_outlined,
                                        color: Color(0xFFBA1A1A),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Delete Account',
                                        style: GoogleFonts.manrope(
                                          color: const Color(0xFFBA1A1A),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 5. Subscription Info Card
                        _buildSubscriptionCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
  }

  // Bento Statistic Indicator
  Widget _buildStatCard(String count, String label) {
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const ProgressView()));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(153),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withAlpha(77), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4B0082).withAlpha(5),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              count,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppColors.assessmentTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final viewModel = context.read<ProfileViewModel>();
    final TextEditingController nameController = TextEditingController(
      text: viewModel.profile.name,
    );
    final TextEditingController emailController = TextEditingController(
      text: viewModel.profile.email,
    );
    final TextEditingController phoneController = TextEditingController(
      text: viewModel.profile.phone ?? '',
    );
    bool biometricVal = viewModel.profile.biometricEnabled;
    String? selectedPhotoBase64 = viewModel.profile.photoUrl;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.assessmentTextPrimary,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Edit Profile',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: AppColors.assessmentTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      _showImageSourceBottomSheet(context, (photoBase64) {
                        setState(() {
                          selectedPhotoBase64 = photoBase64;
                        });
                      });
                    },
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(26),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: selectedPhotoBase64 != null
                                ? Image.memory(
                                    base64Decode(selectedPhotoBase64!),
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: AppColors.primary
                                                  .withAlpha(26),
                                              child: const Icon(
                                                Icons.person,
                                                color: AppColors.primary,
                                                size: 40,
                                              ),
                                            ),
                                  )
                                : Image.network(
                                    'https://lh3.googleusercontent.com/aida-public/AB6AXuA_ZM1DN2uxGGbouCreGZ4Ou-mXawU59UvLV0B3V1AuqDxRPyoKSa4VoYJbsie8GE_PgUC17KE6HWqvyAcZ9KAUQZoCgva3bRbeWGAe0UKdTt_ymLbmjxE-V6f-c-fhFjLnbgPx8wP8JYh7mcVJJ0XV308TxEbnFlPKBVBbTaUBSm_XqGCzI8MZWNdwI9zf6PkWV-c636CXrtjzV1yuqZbUPMT8g46YUdpuWWRYOlUKFJWr75jYLOcO2Q',
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: AppColors.primary
                                                  .withAlpha(26),
                                              child: const Icon(
                                                Icons.person,
                                                color: AppColors.primary,
                                                size: 40,
                                              ),
                                            ),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF6B38D4), Color(0xFF8455EF)],
                              ),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      'Full Name',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.assessmentTextSecondary,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F4).withAlpha(153),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: Colors.grey.shade500,
                      ),
                      hintText: 'Enter your full name',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppColors.assessmentTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      'Email Address',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.assessmentTextSecondary,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F4).withAlpha(153),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.mail_outline,
                        color: Colors.grey.shade500,
                      ),
                      hintText: 'Enter your email address',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppColors.assessmentTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      'Phone Number',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.assessmentTextSecondary,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F4).withAlpha(153),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        color: Colors.grey.shade500,
                      ),
                      hintText: 'Enter your phone number',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppColors.assessmentTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withAlpha(26),
                        ),
                        child: const Icon(
                          Icons.fingerprint_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Enable Biometric Login',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.assessmentTextPrimary,
                              ),
                            ),
                            Text(
                              'Use FaceID or TouchID for faster access',
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                color: AppColors.assessmentTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: biometricVal,
                        onChanged: (val) {
                          setState(() {
                            biometricVal = val;
                          });
                        },
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B38D4), Color(0xFF8455EF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(51),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      final newName = nameController.text.trim();
                      final newEmail = emailController.text.trim();
                      final newPhone = phoneController.text.trim();

                      if (newName.isEmpty || newEmail.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Name and Email cannot be empty.',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: const Color(0xFFBA1A1A),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        );
                        return;
                      }

                      Navigator.of(context).pop();
                      try {
                        await context.read<ProfileViewModel>().updateProfile(
                          name: newName,
                          email: newEmail,
                          phone: newPhone.isNotEmpty ? newPhone : null,
                          biometricEnabled: biometricVal,
                          photoUrl: selectedPhotoBase64,
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Profile updated successfully!',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        String errMsg = e.toString();
                        if (errMsg.contains('requires-recent-login')) {
                          errMsg =
                              'This action requires recent login. Please log out and log back in to update your email.';
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to update profile: $errMsg',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: const Color(0xFFBA1A1A),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Save Changes',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    int strengthScore = 0;
    String strengthLabel = 'Empty';

    void checkStrength(String val, StateSetter setState) {
      int score = 0;
      if (val.isNotEmpty) score++;
      if (val.length >= 8) score++;
      if (val.contains(RegExp(r'[A-Z]')) && val.contains(RegExp(r'[0-9]'))) {
        score++;
      }
      if (val.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

      final labels = ['Empty', 'Weak', 'Fair', 'Strong', 'Excellent'];
      setState(() {
        strengthScore = score;
        strengthLabel = labels[score];
      });
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.assessmentTextPrimary,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Update Security',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: AppColors.assessmentTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withAlpha(26),
                    ),
                    child: const Icon(
                      Icons.lock_open_rounded,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Enhance your account safety by creating a strong, unique password.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColors.assessmentTextSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      'Current Password',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.assessmentTextSecondary,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F4).withAlpha(153),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: currentPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Colors.grey.shade500,
                      ),
                      hintText: 'Enter current password',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppColors.assessmentTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      'New Password',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.assessmentTextSecondary,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F4).withAlpha(153),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    onChanged: (val) => checkStrength(val, setState),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Colors.grey.shade500,
                      ),
                      hintText: 'Create new password',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppColors.assessmentTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(4, (index) {
                          Color barColor = Colors.grey.shade200;
                          if (index < strengthScore) {
                            if (strengthScore == 1) {
                              barColor = Colors.red;
                            } else if (strengthScore == 2) {
                              barColor = Colors.orange;
                            } else if (strengthScore == 3) {
                              barColor = Colors.amber;
                            } else {
                              barColor = Colors.green;
                            }
                          }
                          return Expanded(
                            child: Container(
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Security level: $strengthLabel',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: strengthScore > 2
                              ? AppColors.primary
                              : AppColors.assessmentTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      'Confirm New Password',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.assessmentTextSecondary,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F4).withAlpha(153),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Colors.grey.shade500,
                      ),
                      hintText: 'Repeat new password',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppColors.assessmentTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(13),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppColors.primary,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Min. 8 characters',
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              color: AppColors.assessmentTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(13),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppColors.primary,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Uppercase & numbers',
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              color: AppColors.assessmentTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B38D4), Color(0xFF8455EF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(51),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      final currentPass = currentPasswordController.text;
                      final newPass = newPasswordController.text;
                      final confirmPass = confirmPasswordController.text;

                      if (currentPass.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Please enter your current password.',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: const Color(0xFFBA1A1A),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        );
                        return;
                      }

                      if (newPass.length < 8) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Password must be at least 8 characters.',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: const Color(0xFFBA1A1A),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        );
                        return;
                      }

                      if (newPass != confirmPass) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Passwords do not match.',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: const Color(0xFFBA1A1A),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        );
                        return;
                      }

                      Navigator.of(context).pop();
                      try {
                        await context.read<ProfileViewModel>().changePassword(currentPass, newPass);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Password updated successfully!',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        String errMsg = e.toString();
                        if (errMsg.contains('wrong-password') ||
                            errMsg.contains('invalid-credential')) {
                          errMsg = 'Incorrect current password.';
                        } else if (errMsg.contains('requires-recent-login')) {
                          errMsg =
                              'This action requires recent login. Please log out and log back in to change your password.';
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to change password: $errMsg',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: const Color(0xFFBA1A1A),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Update Password',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.key, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: Text(
          'Terms & Conditions',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppColors.assessmentTextPrimary,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                'Welcome to MindFlow. By accessing and using this application, you agree to be bound by the following Terms & Conditions:\n\n'
                '1. Use of Service: MindFlow provides mindfulness guidance, breathing practices, and wellness tools. These services are for personal and non-commercial wellness purposes only.\n\n'
                '2. Health Disclaimer: The content, exercises, and audio tracks provided are not medical advice and should not replace professional healthcare services.\n\n'
                '3. Premium Accounts: Optional subscription packages unlock premium features. Payments are handled via Google Play Console Billing, and auto-renewals can be cancelled at any time.\n\n'
                '4. Data & Privacy: We respect your privacy. All personalized data like mood history and streak milestones are secured in accordance with our Privacy Policy.\n\n'
                '5. Updates to Terms: We may periodically update these terms to reflect feature changes or legal amendments. Continued use signifies your acceptance.',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppColors.assessmentTextSecondary,
                  height: 1.6,
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    final TextEditingController feedbackController = TextEditingController();
    int rating = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.spa, color: AppColors.primary, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'MindFlow',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.assessmentTextSecondary,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withAlpha(26),
                    ),
                    child: const Icon(
                      Icons.volunteer_activism,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'How was your journey?',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: AppColors.assessmentTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your feedback helps us create a more mindful space for everyone.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColors.assessmentTextSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'RATE YOUR EXPERIENCE',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 1.5,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final currentStarValue = index + 1;
                    final isFilled = currentStarValue <= rating;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          rating = currentStarValue;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          isFilled
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: isFilled
                              ? AppColors.primary
                              : Colors.grey.shade300,
                          size: 40,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      'Your Thoughts',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.assessmentTextSecondary,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F4).withAlpha(153),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: feedbackController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'Tell us what you loved or how we can improve...',
                      hintStyle: GoogleFonts.manrope(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(top: 40, right: 12),
                        child: Icon(
                          Icons.edit_note,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppColors.assessmentTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.network(
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuDkO5e1RRSVmCrRx99kDcAF24CwkSy9KqSAiCrkPLs2MKm1_E5xzmz0UbNGmmsDzS2by0a_cimujxJheF93gsVa48CDkEq3s7aUWwYDICStKxA7sbLurowz_FGi1F0sgCmK1rbuRqMunbDT4PZibMRrsQSnc4SxXkcJS18tldKrgOE0a8tfRBmj6qzbAlYalvDi9WUtM_IBLi4wa1953KGeXve_Ml8WVhB8PcsJOrZpulg7nVp2vGADyQ',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: AppColors.primary.withAlpha(26),
                                  child: const Icon(
                                    Icons.spa,
                                    color: AppColors.primary,
                                    size: 30,
                                  ),
                                ),
                          ),
                        ),
                        Container(color: AppColors.primary.withAlpha(26)),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(204),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'EVERY BREATH COUNTS',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 1.5,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B38D4), Color(0xFF8455EF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(51),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (rating == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Please select a rating before submitting.',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: const Color(0xFFBA1A1A),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        );
                        return;
                      }

                      final text = feedbackController.text.trim();
                      Navigator.of(context).pop();

                      try {
                        await context.read<ProfileViewModel>().submitFeedback(
                          rating: rating,
                          thoughts: text,
                        );

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Thank you for your feedback!',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        );

                        if (rating >= 3) {
                          final String url = Platform.isAndroid
                              ? 'https://play.google.com/store/apps/details?id=com.khushalkhan.mindflow'
                              : 'https://apps.apple.com/app/mindflow/id123456789';
                          final Uri uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to submit feedback: $e',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: const Color(0xFFBA1A1A),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Submit Feedback',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'By submitting, you agree to our Community Guidelines.',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    color: AppColors.assessmentTextSecondary.withAlpha(153),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAboutUsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withAlpha(26),
              ),
              child: const Icon(
                Icons.spa_rounded,
                color: AppColors.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'MindFlow',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w900,
                fontSize: 24,
                color: AppColors.assessmentTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppColors.assessmentTextSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'MindFlow is your mindful companion helping you cultivate inner peace, focus, and energy. We combine science-backed breathing patterns and high-quality soundscapes to elevate your daily routine.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppColors.assessmentTextSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '© 2026 MindFlow. All rights reserved.',
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.only(bottom: 12, right: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Setting navigation list row
  Widget _buildSettingItem({
    required String label,
    required String desc,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.assessmentTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: AppColors.assessmentTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.welcomeOutline,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Subscription Info & Renewal Card
  Widget _buildSubscriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(102),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withAlpha(77), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Ambient decorative gradient circle
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8455EF).withAlpha(26),
                    const Color(0xFF6860EF).withAlpha(13),
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Premium Member',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.assessmentTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your subscription renews on Nov 24, 2024. Thank you for being part of the flow.',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppColors.assessmentTextSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8455EF), Color(0xFF6860EF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8455EF).withAlpha(51),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ScalePressedButton(
                  onTap: () {},
                  paddingVertical: 14,
                  child: Text(
                    'Manage Subscription',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ImageProvider _getAvatarImageProvider(String? photoUrl) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('http')) {
        return NetworkImage(photoUrl);
      }
      try {
        return MemoryImage(base64Decode(photoUrl));
      } catch (_) {}
    }
    return const NetworkImage(
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDjP1tmAsFpCatjWU9v_EfORXcMryAFLBpX4d5CXaXyTWLlO2ba2fiO1GZTYB2D-qzhfvbND7tjCrY027AfGGUJQuZVJZz9b98hYsZuc6DIB4HW9DBVkHJkVw2mHraHlxntc_Y9_22BZmfaTSukHuT6B5ITVO0NuBS0KU7NWpJpifuB0sG2pDGmkHrX2Z8-SfXqidLZ6qTUlXJL6UqkIQFafrCH5B1JWuxi-0621ARF8deon8vht_-Uzw',
    );
  }

  void _showImageSourceBottomSheet(
    BuildContext context,
    Function(String) onImagePicked,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Change Profile Photo',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.assessmentTextPrimary,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withAlpha(26),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  'Camera',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    color: AppColors.assessmentTextPrimary,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  try {
                    final pickedFile = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 50,
                      maxWidth: 200,
                      maxHeight: 200,
                    );
                    if (pickedFile != null) {
                      final bytes = await pickedFile.readAsBytes();
                      final base64String = base64Encode(bytes);
                      onImagePicked(base64String);
                    }
                  } catch (e) {
                    debugPrint('Error picking image from camera: $e');
                  }
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withAlpha(26),
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  'Gallery',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    color: AppColors.assessmentTextPrimary,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  try {
                    final pickedFile = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 50,
                      maxWidth: 200,
                      maxHeight: 200,
                    );
                    if (pickedFile != null) {
                      final bytes = await pickedFile.readAsBytes();
                      final base64String = base64Encode(bytes);
                      onImagePicked(base64String);
                    }
                  } catch (e) {
                    debugPrint('Error picking image from gallery: $e');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
