import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class DeviceService {
  static const String _deviceIdKey = 'mindflow_device_id';
  final FlutterSecureStorage _storage;
  final DeviceInfoPlugin _deviceInfo;
  String? _cachedDeviceId;

  DeviceService({
    FlutterSecureStorage? storage,
    DeviceInfoPlugin? deviceInfo,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  Future<String> getUniqueDeviceId() async {
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    try {
      // 1. Try reading from keychain/secure storage first (works on iOS even after uninstall)
      String? savedId = await _storage.read(key: _deviceIdKey);
      if (savedId != null && savedId.isNotEmpty) {
        _cachedDeviceId = savedId;
        return savedId;
      }

      // 2. If nothing is saved, get native platform identifiers
      String? hardwareId;
      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        hardwareId = iosInfo.identifierForVendor;
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        // In device_info_plus v10+, the unique android hardware ID is represented by 'id'
        // or we can use another hardware property. Let's use androidInfo.id as a fallback.
        hardwareId = androidInfo.id;
      }

      // 3. Fallback: If hardware ID is unavailable, generate a random UUID-like string
      String finalId = hardwareId ?? _generateFallbackId();

      // 4. Save to secure storage to persist it across future runs
      await _storage.write(key: _deviceIdKey, value: finalId);
      _cachedDeviceId = finalId;
      return finalId;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting unique device ID: $e');
      }
      // Ultimate fallback
      return _generateFallbackId();
    }
  }

  String _generateFallbackId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final random = (100000 + (now % 900000)).toString(); // Simple numeric random padding
    return 'dev_${now}_$random';
  }
}
