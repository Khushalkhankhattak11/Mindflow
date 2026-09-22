class UserProfile {
  final String name;
  final String email;
  final int dayStreak;
  final int sessionsCount;
  final String mindfulHours;
  final bool isPremium;
  final String? phone;
  final bool biometricEnabled;
  final String? photoUrl;
  final DateTime? premiumExpirationDate;
  final String? subscriptionStatus;
  final String? subscriptionPlan;

  const UserProfile({
    required this.name,
    required this.email,
    required this.dayStreak,
    required this.sessionsCount,
    required this.mindfulHours,
    required this.isPremium,
    this.phone,
    this.biometricEnabled = false,
    this.photoUrl,
    this.premiumExpirationDate,
    this.subscriptionStatus,
    this.subscriptionPlan,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    int? dayStreak,
    int? sessionsCount,
    String? mindfulHours,
    bool? isPremium,
    String? phone,
    bool? biometricEnabled,
    String? photoUrl,
    DateTime? premiumExpirationDate,
    String? subscriptionStatus,
    String? subscriptionPlan,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      dayStreak: dayStreak ?? this.dayStreak,
      sessionsCount: sessionsCount ?? this.sessionsCount,
      mindfulHours: mindfulHours ?? this.mindfulHours,
      isPremium: isPremium ?? this.isPremium,
      phone: phone ?? this.phone,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      photoUrl: photoUrl ?? this.photoUrl,
      premiumExpirationDate: premiumExpirationDate ?? this.premiumExpirationDate,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
    );
  }
}
