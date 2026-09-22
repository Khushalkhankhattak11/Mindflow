import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioCacheService {
  // Supabase storage public URL for audio assets
  final String supabaseBaseUrl = 'https://nvouexmeevpdkfbspyer.supabase.co/storage/v1/object/public/Sounds';

  Directory? _cacheDir;
  bool _isInitialized = false;
  final ValueNotifier<double> downloadProgress = ValueNotifier(0.0);
  final ValueNotifier<bool> isDownloading = ValueNotifier(false);

  // List of all 17 audio files in the app
  static const List<String> _audioFiles = [
    'audio/hexercise3.mp3',
    'audio/he4.mp3',
    'audio/hexercise2.mp3',
    'audio/happyexersie1.mp3',
    'voice/rain.mp3',
    'voice/wave.mp3',
    'voice/beach.mp3',
    'voice/slowwind.mp3',
    'voice/wind.mp3',
    'voice/fire.mp3',
    'sleep/rain.mp3',
    'sleep/waterfall.mp3',
    'sleep/water.mp3',
    'sleep/occenwave.mp3',
    'sleep/pinkwaterfall.mp3',
    'sleep/circket.mp3',
    'sleep/deepforest.mp3',
  ];

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final docDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${docDir.path}/audio_cache');
      
      // Create directory if it doesn't exist
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }
      _isInitialized = true;
      
      // Start downloading missing files in the background without blocking main startup
      unawaited(_startBackgroundDownload());
    } catch (e) {
      debugPrint('AudioCacheService: Initialization warning/error: $e');
    }
  }

  /// Resolves the audio path to a Source object.
  /// If the file is cached locally, it returns a [DeviceFileSource].
  /// Otherwise, it falls back to a [UrlSource] pointing to Supabase.
  Source getAudioSource(String relativePath) {
    var cleanPath = relativePath.trim();
    // Normalize path by stripping prefixes
    if (cleanPath.startsWith('assets/')) {
      cleanPath = cleanPath.replaceFirst('assets/', '');
    }
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    if (_cacheDir != null) {
      final localFile = File('${_cacheDir!.path}/$cleanPath');
      if (localFile.existsSync()) {
        debugPrint('AudioCacheService: Playing cached file: ${localFile.path}');
        return DeviceFileSource(localFile.path);
      }
    }

    final remoteUrl = '$supabaseBaseUrl/$cleanPath';
    debugPrint('AudioCacheService: Local file not found/cache not ready, streaming from remote: $remoteUrl');
    return UrlSource(remoteUrl);
  }

  Future<void> _startBackgroundDownload() async {
    if (_cacheDir == null) return;

    if (supabaseBaseUrl.contains('YOUR_PROJECT_ID')) {
      debugPrint('AudioCacheService: Supabase URL is not configured. Skipping download.');
      return;
    }

    isDownloading.value = true;
    int downloadedCount = 0;

    for (final relativePath in _audioFiles) {
      if (_cacheDir == null) break;
      final localFile = File('${_cacheDir!.path}/$relativePath');
      
      // Ensure the parent subfolders (audio, sleep, voice) exist locally
      final parentDir = localFile.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      if (await localFile.exists()) {
        downloadedCount++;
        downloadProgress.value = downloadedCount / _audioFiles.length;
        continue;
      }

      try {
        final remoteUrl = Uri.parse('$supabaseBaseUrl/$relativePath');
        debugPrint('AudioCacheService: Downloading $relativePath from $remoteUrl');
        
        final client = HttpClient();
        // Set connection timeout
        client.connectionTimeout = const Duration(seconds: 10);
        
        final request = await client.getUrl(remoteUrl);
        final response = await request.close();

        if (response.statusCode == 200) {
          final fileSink = localFile.openWrite();
          await response.pipe(fileSink);
          debugPrint('AudioCacheService: Successfully downloaded $relativePath');
        } else {
          debugPrint('AudioCacheService: Failed to download $relativePath. Status: ${response.statusCode}');
        }
        client.close();
      } catch (e) {
        debugPrint('AudioCacheService: Error downloading $relativePath: $e');
      }

      downloadedCount++;
      downloadProgress.value = downloadedCount / _audioFiles.length;
    }

    isDownloading.value = false;
    debugPrint('AudioCacheService: Background sync completed. Cached $downloadedCount/${_audioFiles.length} files.');
  }
}
