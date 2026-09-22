import 'dart:async';
import 'package:flutter/foundation.dart';

class BreathingExerciseViewModel extends ChangeNotifier {
  final List<String> _cycles = ['Inhale', 'Hold', 'Exhale', 'Hold'];
  int _cycleIndex = 0;
  int _secondsRemaining;
  int _secondsInCycle = 0;
  int _breathCount = 0;
  bool _isPlaying = true;
  Timer? _timer;

  BreathingExerciseViewModel({int durationSeconds = 285}) : _secondsRemaining = durationSeconds {
    _startTimer();
  }

  String get currentInstruction => _cycles[_cycleIndex];
  int get secondsRemaining => _secondsRemaining;
  int get breathCount => _breathCount;
  bool get isPlaying => _isPlaying;

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPlaying) {
        // Decrement session timer
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _isPlaying = false;
          _timer?.cancel();
        }

        // Increment cycle timer
        _secondsInCycle++;
        if (_secondsInCycle >= 4) {
          _secondsInCycle = 0;
          final previousIndex = _cycleIndex;
          _cycleIndex = (_cycleIndex + 1) % _cycles.length;
          // Completed one full cycle (went from index 3 back to 0)
          if (previousIndex == _cycles.length - 1 && _cycleIndex == 0) {
            _breathCount++;
          }
        }

        notifyListeners();
      }
    });
  }

  void togglePlayPause() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void reset(int durationSeconds) {
    _secondsRemaining = durationSeconds;
    _cycleIndex = 0;
    _secondsInCycle = 0;
    _breathCount = 0;
    _isPlaying = true;
    _startTimer();
    notifyListeners();
  }

  String formatTimeRemaining() {
    final mins = _secondsRemaining ~/ 60;
    final secs = _secondsRemaining % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
