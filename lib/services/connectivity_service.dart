import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  // Defaults to true so we don't flash a warning during initial loading
  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(true);

  Future<void> init() async {
    // 1. Initial check on startup
    final result = await _connectivity.checkConnectivity();
    await _updateConnectionStatus(result);

    // 2. Listen to network interface changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) async {
      await _updateConnectionStatus(results);
    });
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    if (results.isEmpty || (results.length == 1 && results.first == ConnectivityResult.none)) {
      isConnected.value = false;
      return;
    }

    // Perform active lookup to verify the connection has internet capability
    final hasInternet = await _checkRealInternetAccess();
    isConnected.value = hasInternet;
  }

  Future<bool> _checkRealInternetAccess() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {
      // Lookup failed, indicating no actual internet access
    }
    return false;
  }

  /// Force a manual check, useful for the "Try Again" button on the UI
  Future<bool> checkConnectionManually() async {
    final result = await _connectivity.checkConnectivity();
    await _updateConnectionStatus(result);
    return isConnected.value;
  }

  void dispose() {
    _subscription.cancel();
  }
}
