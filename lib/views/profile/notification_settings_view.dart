// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';
import '../../services/service_locator.dart';

class NotificationSettingsView extends StatefulWidget {
  const NotificationSettingsView({super.key});

  @override
  State<NotificationSettingsView> createState() => _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView> {
  bool _pushNotifications = true;
  bool _dailyReminders = true;
  bool _meditationSessions = false;
  bool _appUpdates = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('push_notifications_enabled') ?? true;
      _dailyReminders = prefs.getBool('daily_reminders_enabled') ?? true;
      _meditationSessions = prefs.getBool('meditation_reminders_enabled') ?? false;
      _appUpdates = prefs.getBool('app_updates_enabled') ?? true;
    });
  }

  void _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications_enabled', _pushNotifications);
    await prefs.setBool('daily_reminders_enabled', _dailyReminders);
    await prefs.setBool('meditation_reminders_enabled', _meditationSessions);
    await prefs.setBool('app_updates_enabled', _appUpdates);

    // Save daily reminder notification registration based on toggle status
    final notificationService = locator<NotificationService>();
    if (_dailyReminders) {
      await notificationService.scheduleDailyTenAMNotification();
    } else {
      await notificationService.cancelDailyReminder();
    }

    if (_meditationSessions) {
      await notificationService.scheduleDailyMeditationReminder();
    } else {
      await notificationService.cancelMeditationReminder();
    }

    if (!mounted) return;

    // Show a beautiful premium success snackbar/toast
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              'Notification preferences saved successfully',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF6B38D4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(24),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _restoreDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications_enabled', true);
    await prefs.setBool('daily_reminders_enabled', true);
    await prefs.setBool('meditation_reminders_enabled', false);
    await prefs.setBool('app_updates_enabled', true);

    final notificationService = locator<NotificationService>();
    await notificationService.scheduleDailyTenAMNotification();
    await notificationService.cancelMeditationReminder();

    setState(() {
      _pushNotifications = true;
      _dailyReminders = true;
      _meditationSessions = false;
      _appUpdates = true;
    });
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.refresh_rounded, color: Color(0xFF6B38D4)),
            const SizedBox(width: 12),
            Text(
              'Default preferences restored',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6B38D4),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE9DEF5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(24),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF7FF),
      body: Stack(
        children: [
          // 1. Shifting background radial gradients
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.5,
                  colors: [
                    const Color(0xFF6B38D4).withOpacity(0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.bottomRight,
                  radius: 1.5,
                  colors: [
                    const Color(0xFF4E45D5).withOpacity(0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: Column(
              children: [
                // Top Custom App Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF7FF).withOpacity(0.8),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: Color(0xFF6B38D4),
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Settings',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF6B38D4),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Icon(
                          Icons.spa_outlined,
                          color: Color(0xFF6B38D4),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Section
                            Text(
                              'Mindful Moments',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E1929),
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Customize how you want to be reminded of your wellness journey. Stay connected without feeling overwhelmed.',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                color: const Color(0xFF494454),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Decorative Illustration Card
                            Container(
                              height: 192,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(32),
                                image: const DecorationImage(
                                  image: NetworkImage(
                                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDVf6zYNZ18CyHsLtZunAnQOcw4ZSgfmiI0XYLykjs1JF6srIVyJqoswKYFEb8udhAfbqIreHL7c_gG8_2-TFQXHa-qm6v2IbFGxOso0_MoLHBJrvK6zg7VzUFBBR4XSt4kXwjUHhxvdxHw_xWispDz6qfU6q-Tmuxu9C-KOG4BuX1ccyUuHOHfmlEd7ngnNfU23oaZkBfLfaAy7f4WY3U6lq2oRmnfyxDmRsTQzekKeYP0qKMdNLS71A',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(32),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black.withOpacity(0.4),
                                          Colors.transparent,
                                        ],
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 24,
                                    left: 24,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(100),
                                          ),
                                          child: Text(
                                            'ATMOSPHERE',
                                            style: GoogleFonts.manrope(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Find your flow',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Preferences Group Header
                            Row(
                              children: [
                                const Icon(
                                  Icons.notifications_active_outlined,
                                  color: Color(0xFF6B38D4),
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Notification Preferences',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF6B38D4),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Preferences List
                            _buildGlassCardSettingItem(
                              title: 'Push Notifications',
                              subtitle: 'Global alerts for all activity',
                              icon: Icons.send_rounded,
                              iconColor: const Color(0xFF6B38D4),
                              iconBgColor: const Color(0xFF6B38D4).withOpacity(0.1),
                              value: _pushNotifications,
                              onChanged: (val) => setState(() => _pushNotifications = val),
                            ),
                            _buildGlassCardSettingItem(
                              title: 'Daily Reminders',
                              subtitle: 'A gentle nudge to check in daily',
                              icon: Icons.calendar_today_rounded,
                              iconColor: const Color(0xFF6F5092),
                              iconBgColor: const Color(0xFF6F5092).withOpacity(0.1),
                              value: _dailyReminders,
                              onChanged: (val) => setState(() => _dailyReminders = val),
                            ),
                            _buildGlassCardSettingItem(
                              title: 'Meditation Sessions',
                              subtitle: 'Live session starts and recommendations',
                              icon: Icons.self_improvement_rounded,
                              iconColor: const Color(0xFF4E45D5),
                              iconBgColor: const Color(0xFF4E45D5).withOpacity(0.1),
                              value: _meditationSessions,
                              onChanged: (val) => setState(() => _meditationSessions = val),
                            ),
                            _buildGlassCardSettingItem(
                              title: 'App Updates',
                              subtitle: 'News on features and improvements',
                              icon: Icons.update_rounded,
                              iconColor: const Color(0xFF7B7486),
                              iconBgColor: const Color(0xFF7B7486).withOpacity(0.1),
                              value: _appUpdates,
                              onChanged: (val) => setState(() => _appUpdates = val),
                            ),
                            const SizedBox(height: 24),

                            // Action Section
                            GestureDetector(
                              onTap: _savePreferences,
                              child: Container(
                                alignment: Alignment.center,
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6B38D4),
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6B38D4).withOpacity(0.2),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Save Preferences',
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _restoreDefaults,
                              child: Container(
                                alignment: Alignment.center,
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: const Color(0xFF6B38D4).withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Restore Defaults',
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: const Color(0xFF6B38D4),
                                  ),
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

  Widget _buildGlassCardSettingItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: const Color(0xFF1E1929),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: const Color(0xFF494454).withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CustomToggleSwitch(
                  value: value,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const CustomToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: value ? const Color(0xFF6B38D4) : const Color(0xFFE9DEF5),
        ),
        padding: const EdgeInsets.all(2),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
