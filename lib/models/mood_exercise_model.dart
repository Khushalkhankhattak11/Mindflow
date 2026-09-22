class MoodRecommendation {
  final String goal;
  final List<MoodExercise> exercises;

  const MoodRecommendation({required this.goal, required this.exercises});
}

class MoodExercise {
  final String title;
  final String duration;
  final String emoji;

  const MoodExercise({
    required this.title,
    required this.duration,
    required this.emoji,
  });
}

const Map<String, MoodRecommendation> moodRecommendations = {
  'happy': MoodRecommendation(
    goal: 'Maintain happiness and positivity',
    exercises: [
      MoodExercise(emoji: '😊', title: 'Smile Breathing', duration: '5 min'),
      MoodExercise(emoji: '🌸', title: 'Gratitude Journey', duration: '5 min'),
      MoodExercise(emoji: '✨', title: 'Positive Affirmations', duration: '3 min'),
      MoodExercise(emoji: '🌅', title: 'A Walk Through Happiness', duration: '10 min'),
      MoodExercise(emoji: '🤸', title: 'Happy Body Stretch', duration: '8 min'),
      MoodExercise(emoji: '😂', title: 'Laughter & Joy', duration: '5 min'),
      MoodExercise(emoji: '☀️', title: 'Morning Energy Reset', duration: '5 min'),
      MoodExercise(emoji: '💛', title: 'Choose Happiness', duration: '5 min'),
    ],
  ),
  'calm': MoodRecommendation(
    goal: 'Maintain inner peace',
    exercises: [
      MoodExercise(emoji: '🌿', title: 'Mindful Breathing', duration: '5 min'),
      MoodExercise(
        emoji: '🌊',
        title: 'Inner Peace Meditation',
        duration: '10 min',
      ),
      MoodExercise(
        emoji: '🍃',
        title: 'Body Scan Relaxation',
        duration: '12 min',
      ),
      MoodExercise(
        emoji: '🪷',
        title: 'Silent Mindfulness',
        duration: '15 min',
      ),
      MoodExercise(emoji: '☁️', title: 'Gentle Relaxation', duration: '8 min'),
    ],
  ),
  'grateful': MoodRecommendation(
    goal: 'Deepen gratitude',
    exercises: [
      MoodExercise(
        emoji: '🙏',
        title: 'Gratitude Meditation',
        duration: '5 min',
      ),
      MoodExercise(emoji: '🌅', title: 'Thankful Heart', duration: '10 min'),
      MoodExercise(emoji: '💖', title: 'Loving Kindness', duration: '12 min'),
      MoodExercise(
        emoji: '🌸',
        title: 'Appreciation Practice',
        duration: '8 min',
      ),
      MoodExercise(emoji: '🌞', title: 'Daily Blessings', duration: '15 min'),
    ],
  ),
  'motivated': MoodRecommendation(
    goal: 'Improve focus and productivity',
    exercises: [
      MoodExercise(emoji: '🚀', title: 'Morning Motivation', duration: '5 min'),
      MoodExercise(
        emoji: '🎯',
        title: 'Deep Focus Meditation',
        duration: '10 min',
      ),
      MoodExercise(emoji: '💡', title: 'Mental Clarity', duration: '12 min'),
      MoodExercise(emoji: '⚡', title: 'Energy Boost', duration: '8 min'),
      MoodExercise(
        emoji: '📚',
        title: 'Productivity Session',
        duration: '15 min',
      ),
    ],
  ),
  'tired': MoodRecommendation(
    goal: 'Recharge energy',
    exercises: [
      MoodExercise(emoji: '🌞', title: 'Morning Energy', duration: '5 min'),
      MoodExercise(emoji: '🌬', title: 'Energizing Breath', duration: '3 min'),
      MoodExercise(
        emoji: '☀️',
        title: 'Fresh Start Meditation',
        duration: '8 min',
      ),
      MoodExercise(emoji: '⚡', title: 'Recharge Mind', duration: '10 min'),
      MoodExercise(emoji: '💪', title: 'Energy Reset', duration: '12 min'),
    ],
  ),
  'distracted': MoodRecommendation(
    goal: 'Improve concentration',
    exercises: [
      MoodExercise(emoji: '🎯', title: 'Deep Focus', duration: '10 min'),
      MoodExercise(emoji: '🌿', title: 'Mindful Attention', duration: '8 min'),
      MoodExercise(emoji: '📖', title: 'Study Focus', duration: '15 min'),
      MoodExercise(
        emoji: '🧠',
        title: 'Concentration Training',
        duration: '12 min',
      ),
      MoodExercise(emoji: '✨', title: 'Clear Thinking', duration: '10 min'),
    ],
  ),
  'stressed': MoodRecommendation(
    goal: 'Reduce stress',
    exercises: [
      MoodExercise(
        emoji: '🌬',
        title: 'Instant Calm Breathing',
        duration: '3 min',
      ),
      MoodExercise(
        emoji: '🌊',
        title: 'Deep Calm Meditation',
        duration: '5 min',
      ),
      MoodExercise(emoji: '🍃', title: 'Release Tension', duration: '10 min'),
      MoodExercise(emoji: '🌅', title: 'Stress Reset', duration: '15 min'),
      MoodExercise(
        emoji: '🪷',
        title: 'Progressive Relaxation',
        duration: '12 min',
      ),
    ],
  ),
  'anxious': MoodRecommendation(
    goal: 'Calm anxiety',
    exercises: [
      MoodExercise(emoji: '🌬', title: '4-7-8 Breathing', duration: '5 min'),
      MoodExercise(
        emoji: '🌲',
        title: 'Anxiety Relief Meditation',
        duration: '10 min',
      ),
      MoodExercise(
        emoji: '💙',
        title: 'Safe Space Visualization',
        duration: '12 min',
      ),
      MoodExercise(emoji: '🌿', title: 'Ground Yourself', duration: '8 min'),
      MoodExercise(
        emoji: '🕊',
        title: 'Inner Peace Journey',
        duration: '15 min',
      ),
    ],
  ),
  'overwhelmed': MoodRecommendation(
    goal: 'Slow down and reset',
    exercises: [
      MoodExercise(
        emoji: '🌬',
        title: 'One Breath at a Time',
        duration: '3 min',
      ),
      MoodExercise(emoji: '🪷', title: 'Mental Reset', duration: '8 min'),
      MoodExercise(emoji: '🌊', title: 'Quiet the Mind', duration: '10 min'),
      MoodExercise(emoji: '⚖️', title: 'Find Your Balance', duration: '12 min'),
      MoodExercise(
        emoji: '🌿',
        title: 'Slow Down Meditation',
        duration: '15 min',
      ),
    ],
  ),
  'sad': MoodRecommendation(
    goal: 'Emotional healing',
    exercises: [
      MoodExercise(
        emoji: '💙',
        title: 'Self-Compassion Meditation',
        duration: '10 min',
      ),
      MoodExercise(emoji: '🌸', title: 'Healing the Heart', duration: '12 min'),
      MoodExercise(emoji: '🌈', title: 'Finding Hope', duration: '10 min'),
      MoodExercise(emoji: '🤲', title: 'Gentle Acceptance', duration: '15 min'),
      MoodExercise(emoji: '💖', title: 'Loving Kindness', duration: '12 min'),
    ],
  ),
  'angry': MoodRecommendation(
    goal: 'Release anger peacefully',
    exercises: [
      MoodExercise(
        emoji: '🌬',
        title: 'Cool Down Breathing',
        duration: '5 min',
      ),
      MoodExercise(
        emoji: '🌊',
        title: 'Release Anger Meditation',
        duration: '10 min',
      ),
      MoodExercise(emoji: '🍃', title: 'Let Go Practice', duration: '12 min'),
      MoodExercise(
        emoji: '🤍',
        title: 'Forgiveness Meditation',
        duration: '15 min',
      ),
      MoodExercise(
        emoji: '🪷',
        title: 'Inner Peace Journey',
        duration: '10 min',
      ),
    ],
  ),
  'lonely': MoodRecommendation(
    goal: 'Build self-love and connection',
    exercises: [
      MoodExercise(
        emoji: '💖',
        title: 'Self-Love Meditation',
        duration: '10 min',
      ),
      MoodExercise(emoji: '🤲', title: 'Loving Kindness', duration: '15 min'),
      MoodExercise(emoji: '🌸', title: 'Open Your Heart', duration: '12 min'),
      MoodExercise(
        emoji: '🌍',
        title: 'Connection Meditation',
        duration: '10 min',
      ),
      MoodExercise(emoji: '😊', title: 'You Are Enough', duration: '8 min'),
    ],
  ),
};
