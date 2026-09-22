import 'package:flutter/material.dart';
import '../models/sleep_model.dart';

class SleepSoundsViewModel extends ChangeNotifier {
  static const List<SleepSoundItem> defaultSoundscapes = [
    SleepSoundItem(
      title: 'Waterfall',
      subtitle: 'Waterfall stream',
      icon: Icons.water,
      color: Color(0xFF4E45D5),
      bgImage:
          'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=500&q=80',
    ),
    SleepSoundItem(
      title: 'Deep Forest',
      subtitle: 'Quiet woodlands',
      icon: Icons.forest,
      color: Color(0xFF6F5092),
      bgImage:
          'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=500&q=80',
    ),
    SleepSoundItem(
      title: 'Forest Rain',
      subtitle: 'Rain on canopy',
      icon: Icons.thunderstorm,
      color: Color(0xFF6B38D4),
      bgImage:
          'https://media.istockphoto.com/id/1044134410/video/tropical-rain-forest-trees-birth-of-cloud.jpg?b=1&s=640x640&k=20&c=WAa7pa90TxsKRwBFMofcmEJTKdcC5l8p3w2TJ9Bf_0E=',
    ),
    SleepSoundItem(
      title: 'Water',
      subtitle: 'Gentle flow',
      icon: Icons.waves,
      color: Color(0xFF3A637C),
      bgImage:
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=500&q=80',
    ),
    SleepSoundItem(
      title: 'Night Crickets',
      subtitle: 'Bedtime ambience',
      icon: Icons.nights_stay,
      color: Color(0xFF573878),
      bgImage:
          'https://images.unsplash.com/photo-1506318137071-a8e063b4bec0?auto=format&fit=crop&w=500&q=80',
    ),
    SleepSoundItem(
      title: 'Ocean Waves',
      subtitle: 'Soothing tides',
      icon: Icons.waves_rounded,
      color: Color(0xFF2E5B88),
      bgImage:
          'https://images.unsplash.com/photo-1518837695005-2083093ee35b?auto=format&fit=crop&w=500&q=80',
    ),
    SleepSoundItem(
      title: 'Pink Waterfall',
      subtitle: 'Gentle pink noise',
      icon: Icons.water_rounded,
      color: Color(0xFFD36B8D),
      bgImage:
          'https://images.unsplash.com/photo-1527489377706-5bf97e608852?auto=format&fit=crop&w=500&q=80',
    ),
  ];

  final bool _isLoading = false;
  SleepSoundItem? _playingSound;
  bool _isPlaying = false;
  int _remainingMinutes = 45;

  bool get isLoading => _isLoading;
  List<SleepSoundItem> get soundscapes => defaultSoundscapes;
  SleepSoundItem? get playingSound => _playingSound;
  bool get isPlaying => _isPlaying;
  int get remainingMinutes => _remainingMinutes;

  void selectSound(SleepSoundItem sound) {
    _playingSound = sound;
    _isPlaying = true;
    notifyListeners();
  }

  void togglePlayback() {
    if (_playingSound == null) {
      // Default to Rain/Waterfall if nothing is playing
      _playingSound = defaultSoundscapes[0];
      _isPlaying = true;
    } else {
      _isPlaying = !_isPlaying;
    }
    notifyListeners();
  }

  void setTimer(int minutes) {
    _remainingMinutes = minutes;
    notifyListeners();
  }
}
