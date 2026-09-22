import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/auth_repository.dart';
import '../repositories/onboarding_repository.dart';
import '../services/service_locator.dart';
import '../models/assessment_model.dart';

class DynamicNotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String category; // 'Mindfulness', 'Reminder', 'System'
  final String iconType; // 'spa', 'fire', 'moon', 'shield', 'goal'
  bool isRead;

  DynamicNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.category,
    required this.iconType,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'category': category,
      'iconType': iconType,
      'isRead': isRead,
    };
  }

  factory DynamicNotificationItem.fromMap(Map<String, dynamic> map) {
    return DynamicNotificationItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      category: map['category'] ?? 'Mindfulness',
      iconType: map['iconType'] ?? 'spa',
      isRead: map['isRead'] ?? false,
    );
  }
}

class NotificationsViewModel extends ChangeNotifier {
  final AuthRepository _authRepository = locator<AuthRepository>();
  final OnboardingRepository _onboardingRepository = locator<OnboardingRepository>();

  List<DynamicNotificationItem> _notifications = [];
  String _selectedCategory = 'All';
  bool _isLoading = true;

  List<DynamicNotificationItem> get notifications => _notifications;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  List<DynamicNotificationItem> get filteredNotifications {
    if (_selectedCategory == 'All') return _notifications;
    return _notifications.where((n) => n.category == _selectedCategory).toList();
  }

  NotificationsViewModel() {
    loadNotifications();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('user_dynamic_notifications');

      if (savedJson != null && savedJson.isNotEmpty) {
        final List decoded = jsonDecode(savedJson);
        _notifications = decoded.map((e) => DynamicNotificationItem.fromMap(Map<String, dynamic>.from(e))).toList();
      } else {
        // Generate dynamic initial notifications based on real user state & time
        _notifications = await _generateDynamicNotifications();
        await _saveToPrefs();
      }
    } catch (e) {
      _notifications = await _generateDynamicNotifications();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<DynamicNotificationItem>> _generateDynamicNotifications() async {
    final List<DynamicNotificationItem> generated = [];
    final now = DateTime.now();

    // 1. Fetch user model & onboarding goals
    final userModel = _authRepository.currentUserModel;
    final userName = userModel?.name.isNotEmpty == true ? userModel!.name.split(' ').first : 'MindFlow User';
    final assessment = await _onboardingRepository.fetchUserAssessment();

    // 2. Dynamic Time of Day Notification
    final hour = now.hour;
    if (hour >= 5 && hour < 12) {
      generated.add(
        DynamicNotificationItem(
          id: 'time_morning',
          title: '🌅 Good Morning, $userName!',
          body: 'Start your morning with 5 minutes of mindful breathing to set a calm tone for the day.',
          timestamp: now.subtract(const Duration(minutes: 20)),
          category: 'Mindfulness',
          iconType: 'spa',
          isRead: false,
        ),
      );
    } else if (hour >= 12 && hour < 17) {
      generated.add(
        DynamicNotificationItem(
          id: 'time_afternoon',
          title: '☀️ Afternoon Mental Reset',
          body: 'Take a 3-minute breath break to reset your focus and lower cortisol levels.',
          timestamp: now.subtract(const Duration(minutes: 15)),
          category: 'Mindfulness',
          iconType: 'spa',
          isRead: false,
        ),
      );
    } else if (hour >= 17 && hour < 21) {
      generated.add(
        DynamicNotificationItem(
          id: 'time_evening',
          title: '🌇 Evening Wind Down',
          body: 'Unwind your mind after a busy day with a soothing evening meditation.',
          timestamp: now.subtract(const Duration(minutes: 30)),
          category: 'Mindfulness',
          iconType: 'spa',
          isRead: false,
        ),
      );
    } else {
      generated.add(
        DynamicNotificationItem(
          id: 'time_night',
          title: '🌙 Nighttime Sleep Soundscape',
          body: 'Try "Ocean Waves & Deep Rain" to ease into restorative sleep tonight.',
          timestamp: now.subtract(const Duration(minutes: 10)),
          category: 'Mindfulness',
          iconType: 'moon',
          isRead: false,
        ),
      );
    }

    // 3. Dynamic Onboarding Goal Notification
    if (assessment?.goal != null) {
      final goalName = _getGoalLabel(assessment!.goal!);
      generated.add(
        DynamicNotificationItem(
          id: 'goal_personalized',
          title: '🎯 Personal Goal Match: $goalName',
          body: '3 new exercises matching your onboarding goal to "$goalName" are now ready in your Meditate tab.',
          timestamp: now.subtract(const Duration(hours: 2)),
          category: 'Mindfulness',
          iconType: 'goal',
          isRead: false,
        ),
      );
    } else {
      generated.add(
        DynamicNotificationItem(
          id: 'goal_default',
          title: '🎯 Recommended Sessions Ready',
          body: 'Explore tailored meditations designed to reduce stress and improve daily focus.',
          timestamp: now.subtract(const Duration(hours: 2)),
          category: 'Mindfulness',
          iconType: 'goal',
          isRead: false,
        ),
      );
    }

    // 4. Dynamic Streak Notification
    final streak = userModel?.dayStreak ?? 0;
    if (streak > 0) {
      generated.add(
        DynamicNotificationItem(
          id: 'streak_active',
          title: '🔥 $streak-Day Streak Active!',
          body: 'You are building a great habit. Complete a session today to keep your streak glowing!',
          timestamp: now.subtract(const Duration(hours: 14)),
          category: 'Reminder',
          iconType: 'fire',
          isRead: false,
        ),
      );
    } else {
      generated.add(
        DynamicNotificationItem(
          id: 'streak_start',
          title: '🌱 Start Your Mindfulness Streak',
          body: 'Complete your first meditation session today to ignite your daily streak flame.',
          timestamp: now.subtract(const Duration(hours: 12)),
          category: 'Reminder',
          iconType: 'fire',
          isRead: true,
        ),
      );
    }

    // 5. Dynamic System & Privacy Notification
    generated.add(
      DynamicNotificationItem(
        id: 'system_privacy',
        title: '🛡️ Privacy & Encryption Active',
        body: 'Your meditation data and personal progress are encrypted and stored securely.',
        timestamp: now.subtract(const Duration(days: 1)),
        category: 'System',
        iconType: 'shield',
        isRead: true,
      ),
    );

    return generated;
  }

  String _getGoalLabel(MindGoal goal) {
    switch (goal) {
      case MindGoal.reduceStress:
        return 'Reduce Stress';
      case MindGoal.sleepBetter:
        return 'Sleep Better';
      case MindGoal.focusMore:
        return 'Improve Focus';
      case MindGoal.buildHabit:
        return 'Build Daily Habit';
    }
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      notifyListeners();
      _saveToPrefs();
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
    _saveToPrefs();
  }

  void removeNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
    _saveToPrefs();
  }

  void addNotification({
    required String title,
    required String body,
    required String category,
    required String iconType,
  }) {
    final newItem = DynamicNotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      category: category,
      iconType: iconType,
      isRead: false,
    );
    _notifications.insert(0, newItem);
    notifyListeners();
    _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _notifications.map((n) => n.toMap()).toList();
      await prefs.setString('user_dynamic_notifications', jsonEncode(jsonList));
    } catch (_) {}
  }
}
