class MeditationSession {
  final String title;
  final String description;
  final String durationLabel; // e.g., "10m"
  final String difficulty; // "Beginner", "Intermediate", "Expert", "All Levels"
  final String imageUrl;
  final String instructorName;
  final List<String> instructorAvatars; // List of overlapping avatars (supports 1 or 2)
  final List<String> categories; // ["Stress", "Sleep", "Focus", "Morning", "Evening", "Anxiety"]
  final bool isFavorited;

  const MeditationSession({
    required this.title,
    required this.description,
    required this.durationLabel,
    required this.difficulty,
    required this.imageUrl,
    required this.instructorName,
    required this.instructorAvatars,
    required this.categories,
    this.isFavorited = false,
  });

  MeditationSession copyWith({
    String? title,
    String? description,
    String? durationLabel,
    String? difficulty,
    String? imageUrl,
    String? instructorName,
    List<String>? instructorAvatars,
    List<String>? categories,
    bool? isFavorited,
  }) {
    return MeditationSession(
      title: title ?? this.title,
      description: description ?? this.description,
      durationLabel: durationLabel ?? this.durationLabel,
      difficulty: difficulty ?? this.difficulty,
      imageUrl: imageUrl ?? this.imageUrl,
      instructorName: instructorName ?? this.instructorName,
      instructorAvatars: instructorAvatars ?? this.instructorAvatars,
      categories: categories ?? this.categories,
      isFavorited: isFavorited ?? this.isFavorited,
    );
  }
}
