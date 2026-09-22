enum SplashStatus {
  loading,
  completed,
}

class SplashState {
  final SplashStatus status;
  final String message;

  const SplashState({
    required this.status,
    required this.message,
  });
}
