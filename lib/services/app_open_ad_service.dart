import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/admob_ids.dart';
import '../repositories/auth_repository.dart';
import 'service_locator.dart';

class AppOpenAdService {
  AppOpenAd? _appOpenAd;
  bool _isLoading = false;
  bool _isShowing = false;
  bool _hasShownThisLaunch = false;
  bool _showWhenLoaded = false;

  Future<void> loadAd() async {
    if (locator<AuthRepository>().currentUserModel?.isSubscriptionActive ?? false) {
      return;
    }

    final adUnitId = AdMobIds.appOpenAdUnitId;
    if (adUnitId == null || _isLoading || _appOpenAd != null) return;

    _isLoading = true;
    await AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          _appOpenAd = ad;
          if (_showWhenLoaded) {
            _showWhenLoaded = false;
            unawaited(showAdIfAvailable());
          }
        },
        onAdFailedToLoad: (_) {
          _isLoading = false;
          _appOpenAd = null;
          _showWhenLoaded = false;
        },
      ),
    );
  }

  Future<void> showAdIfAvailable() async {
    if (locator<AuthRepository>().currentUserModel?.isSubscriptionActive ?? false) {
      return;
    }

    if (_hasShownThisLaunch || _isShowing) return;

    final ad = _appOpenAd;
    if (ad == null) {
      _showWhenLoaded = true;
      await loadAd();
      return;
    }

    _isShowing = true;
    _hasShownThisLaunch = true;
    _appOpenAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback<AppOpenAd>(
      onAdDismissedFullScreenContent: (ad) {
        _isShowing = false;
        ad.dispose();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        _isShowing = false;
        ad.dispose();
      },
    );

    await ad.show();
  }

  void dispose() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
  }
}
