import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/meditation_model.dart';
import '../services/service_locator.dart';
import '../services/audio_cache_service.dart';

class MeditationPlayerViewModel extends ChangeNotifier {
  final MeditationSession session;
  late final AudioPlayer _audioPlayer;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _completeSubscription;

  int _currentSeconds = 0;
  int _totalSeconds = 0;
  bool _isPlaying = false;
  bool _isFavorited = true; // favorited by default in mockup

  MeditationPlayerViewModel({required this.session}) {
    _audioPlayer = AudioPlayer();
    _initAudio();
  }

  int get currentSeconds => _currentSeconds;
  int get totalSeconds => _totalSeconds;
  bool get isPlaying => _isPlaying;
  bool get isFavorited => _isFavorited;

  double get progressPercentage =>
      _totalSeconds > 0 ? _currentSeconds / _totalSeconds : 0.0;

  void _initAudio() {
    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      _totalSeconds = duration.inSeconds;
      notifyListeners();
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      _currentSeconds = position.inSeconds;
      notifyListeners();
    });

    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    _completeSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      _isPlaying = false;
      _currentSeconds = 0;
      notifyListeners();
    });

    final path = _getAudioPath(session.title);
    if (path.isNotEmpty) {
      _audioPlayer.play(locator<AudioCacheService>().getAudioSource(path)).catchError((e) {
        debugPrint('Error playing audio from remote/cache ($path): $e');
      });
    }
  }

  String _getAudioPath(String title) {
    final normalized = title.toLowerCase();
    if (normalized.contains('smile breathing')) {
      return 'audio/happyexersie1.mp3';
    } else if (normalized.contains('gratitude journey') || normalized.contains('gratitude meditation')) {
      return 'audio/hexercise2.mp3';
    } else if (normalized.contains('positive affirmations') || normalized.contains('positive energy')) {
      return 'audio/hexercise3.mp3';
    } else if (normalized.contains('walk through happiness') || normalized.contains('present moment awareness')) {
      return 'audio/he4.mp3';
    } else if (normalized.contains('happy body stretch') || normalized.contains('joyful breathing')) {
      return 'audio/happyexersie1.mp3';
    } else if (normalized.contains('laughter & joy') || normalized.contains('celebrate today')) {
      return 'audio/hexercise2.mp3';
    } else if (normalized.contains('morning energy reset') || normalized.contains('morning energy')) {
      return 'audio/hexercise3.mp3';
    } else if (normalized.contains('choose happiness') || normalized.contains('fresh start')) {
      return 'audio/he4.mp3';
    }

    // Fallback: cycle through the files based on title hash or just use a default
    final index = title.codeUnits.fold<int>(0, (prev, element) => prev + element) % 4;
    switch (index) {
      case 0:
        return 'audio/happyexersie1.mp3';
      case 1:
        return 'audio/hexercise2.mp3';
      case 2:
        return 'audio/hexercise3.mp3';
      case 3:
      default:
        return 'audio/he4.mp3';
    }
  }

  void togglePlayPause() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.resume();
    }
  }

  void seekToPercentage(double percentage) {
    final targetSeconds = (percentage * _totalSeconds).round().clamp(0, _totalSeconds);
    _audioPlayer.seek(Duration(seconds: targetSeconds));
  }

  void replay10() {
    final targetSeconds = (_currentSeconds - 10).clamp(0, _totalSeconds);
    _audioPlayer.seek(Duration(seconds: targetSeconds));
  }

  void forward10() {
    final targetSeconds = (_currentSeconds + 10).clamp(0, _totalSeconds);
    _audioPlayer.seek(Duration(seconds: targetSeconds));
  }

  void toggleFavorite() {
    _isFavorited = !_isFavorited;
    notifyListeners();
  }

  String formatDuration(int totalSecs) {
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _completeSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
