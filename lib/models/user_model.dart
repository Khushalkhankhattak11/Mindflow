import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? fcmToken;
  final DateTime createdAt;
  final int dayStreak;
  final int sessionsCount;
  final double mindfulHours;
  final bool isPremium;
  final String? phone;
  final bool biometricEnabled;
  final String? photoUrl;
  final DateTime? lastActiveDate;
  final List<DateTime> streakMissed;
  final int streakSaverPasses;
  final DateTime? premiumPurchaseDate;
  final DateTime? premiumExpirationDate;
  final String? subscriptionStatus; // 'active', 'expired', 'none'
  final String? subscriptionPlan; // e.g. 'weekly', 'yearly'
  final String? subscriptionStore; // e.g. 'play_store', 'app_store'
  final bool? subscriptionWillRenew;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.fcmToken,
    required this.createdAt,
    this.dayStreak = 0,
    this.sessionsCount = 0,
    this.mindfulHours = 0.0,
    this.isPremium = false,
    this.phone,
    this.biometricEnabled = false,
    this.photoUrl,
    this.lastActiveDate,
    this.streakMissed = const [],
    this.streakSaverPasses = 2,
    this.premiumPurchaseDate,
    this.premiumExpirationDate,
    this.subscriptionStatus,
    this.subscriptionPlan,
    this.subscriptionStore,
    this.subscriptionWillRenew,
  });

  /// Validates whether the user currently possesses valid, active premium access.
  /// If the subscription has reached or passed its expiration date, returns false.
  bool get isSubscriptionActive {
    if (!isPremium) return false;
    if (premiumExpirationDate != null && DateTime.now().isAfter(premiumExpirationDate!)) {
      return false;
    }
    return true;
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? fcmToken,
    DateTime? createdAt,
    int? dayStreak,
    int? sessionsCount,
    double? mindfulHours,
    bool? isPremium,
    String? phone,
    bool? biometricEnabled,
    String? photoUrl,
    DateTime? lastActiveDate,
    List<DateTime>? streakMissed,
    int? streakSaverPasses,
    DateTime? premiumPurchaseDate,
    DateTime? premiumExpirationDate,
    String? subscriptionStatus,
    String? subscriptionPlan,
    String? subscriptionStore,
    bool? subscriptionWillRenew,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      dayStreak: dayStreak ?? this.dayStreak,
      sessionsCount: sessionsCount ?? this.sessionsCount,
      mindfulHours: mindfulHours ?? this.mindfulHours,
      isPremium: isPremium ?? this.isPremium,
      phone: phone ?? this.phone,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      photoUrl: photoUrl ?? this.photoUrl,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      streakMissed: streakMissed ?? this.streakMissed,
      streakSaverPasses: streakSaverPasses ?? this.streakSaverPasses,
      premiumPurchaseDate: premiumPurchaseDate ?? this.premiumPurchaseDate,
      premiumExpirationDate: premiumExpirationDate ?? this.premiumExpirationDate,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionStore: subscriptionStore ?? this.subscriptionStore,
      subscriptionWillRenew: subscriptionWillRenew ?? this.subscriptionWillRenew,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'dayStreak': dayStreak,
      'sessionsCount': sessionsCount,
      'mindfulHours': mindfulHours,
      'isPremium': isPremium,
      'phone': phone,
      'biometricEnabled': biometricEnabled,
      'photoUrl': photoUrl,
      'lastActiveDate': lastActiveDate != null ? Timestamp.fromDate(lastActiveDate!) : null,
      'streakMissed': streakMissed.map((d) => Timestamp.fromDate(d)).toList(),
      'streakSaverPasses': streakSaverPasses,
      'premiumPurchaseDate': premiumPurchaseDate != null ? Timestamp.fromDate(premiumPurchaseDate!) : null,
      'premiumExpirationDate': premiumExpirationDate != null ? Timestamp.fromDate(premiumExpirationDate!) : null,
      'subscriptionStatus': subscriptionStatus,
      'subscriptionPlan': subscriptionPlan,
      'subscriptionStore': subscriptionStore,
      'subscriptionWillRenew': subscriptionWillRenew,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    if (map['createdAt'] is Timestamp) {
      parsedDate = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      parsedDate = DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    DateTime? lastActiveParsed;
    if (map['lastActiveDate'] is Timestamp) {
      lastActiveParsed = (map['lastActiveDate'] as Timestamp).toDate();
    } else if (map['lastActiveDate'] is String) {
      lastActiveParsed = DateTime.tryParse(map['lastActiveDate'] as String);
    }

    DateTime? premiumPurchaseParsed;
    if (map['premiumPurchaseDate'] is Timestamp) {
      premiumPurchaseParsed = (map['premiumPurchaseDate'] as Timestamp).toDate();
    } else if (map['premiumPurchaseDate'] is String) {
      premiumPurchaseParsed = DateTime.tryParse(map['premiumPurchaseDate'] as String);
    }

    DateTime? premiumExpirationParsed;
    if (map['premiumExpirationDate'] is Timestamp) {
      premiumExpirationParsed = (map['premiumExpirationDate'] as Timestamp).toDate();
    } else if (map['premiumExpirationDate'] is String) {
      premiumExpirationParsed = DateTime.tryParse(map['premiumExpirationDate'] as String);
    }

    final streakMissedList = <DateTime>[];
    if (map['streakMissed'] is List) {
      for (final item in map['streakMissed'] as List) {
        if (item is Timestamp) {
          streakMissedList.add(item.toDate());
        } else if (item is String) {
          final parsed = DateTime.tryParse(item);
          if (parsed != null) {
            streakMissedList.add(parsed);
          }
        }
      }
    }

    return UserModel(
      uid: map['uid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      fcmToken: map['fcmToken'] as String?,
      createdAt: parsedDate,
      dayStreak: map['dayStreak'] as int? ?? 0,
      sessionsCount: map['sessionsCount'] as int? ?? 0,
      mindfulHours: (map['mindfulHours'] as num?)?.toDouble() ?? 0.0,
      isPremium: map['isPremium'] as bool? ?? false,
      phone: map['phone'] as String?,
      biometricEnabled: map['biometricEnabled'] as bool? ?? false,
      photoUrl: map['photoUrl'] as String?,
      lastActiveDate: lastActiveParsed,
      streakMissed: streakMissedList,
      streakSaverPasses: map['streakSaverPasses'] as int? ?? 2,
      premiumPurchaseDate: premiumPurchaseParsed,
      premiumExpirationDate: premiumExpirationParsed,
      subscriptionStatus: map['subscriptionStatus'] as String?,
      subscriptionPlan: map['subscriptionPlan'] as String?,
      subscriptionStore: map['subscriptionStore'] as String?,
      subscriptionWillRenew: map['subscriptionWillRenew'] as bool?,
    );
  }
}
