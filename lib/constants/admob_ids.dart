import 'package:flutter/foundation.dart';

class AdMobIds {
  const AdMobIds._();

  static const androidAppOpenAdUnitId =
      'ca-app-pub-3940256099942544/9257395921';
  static const iosAppOpenAdUnitId = 'ca-app-pub-3940256099942544/5575463023';

  static String? get appOpenAdUnitId {
    if (kIsWeb) return null;

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => androidAppOpenAdUnitId,
      TargetPlatform.iOS => iosAppOpenAdUnitId,
      _ => null,
    };
  }
}
