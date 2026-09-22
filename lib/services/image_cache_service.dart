import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_logger.dart';

/// Pre-caches meditation images and background assets directly to local disk
/// and saves their file paths in SharedPreferences for instant local retrieval.
class ImageCacheService {
  static const String supabaseBaseUrl =
      'https://nvouexmeevpdkfbspyer.supabase.co/storage/v1/object/public/medition';

  static final List<String> _meditationImageUrls = List.generate(
    10,
    (index) => '$supabaseBaseUrl/m${index + 1}.png',
  );

  static final List<String> _bannerImageUrls = [
    'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1518837695005-2083093ee35b?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1506318137071-a8e063b4bec0?auto=format&fit=crop&w=800&q=80',
  ];

  Directory? _cacheDir;
  SharedPreferences? _prefs;
  bool _initialized = false;
  Completer<void>? _initCompleter;
  final Map<String, Future<File?>> _pendingDownloads = {};

  Future<void> init() async {
    if (_initialized) return;
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    _initCompleter = Completer<void>();
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/image_cache');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _cacheDir = dir;
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    } catch (e, stackTrace) {
      AppLogger.w('Failed to initialize image cache directory and SharedPreferences', e, stackTrace);
    } finally {
      _initCompleter?.complete();
      _initCompleter = null;
    }
  }

  String _getPrefsKey(String url) {
    final fileName = Uri.parse(url).pathSegments.last;
    return 'cached_img_path_$fileName';
  }

  /// Downloads all Supabase meditation images (m1.png to m10.png) and banner assets in parallel,
  /// storing them on local disk and recording their file paths in SharedPreferences.
  Future<void> precacheAllAppImages() async {
    if (!_initialized) await init();
    final allUrls = [..._meditationImageUrls, ..._bannerImageUrls];

    await Future.wait(allUrls.map((url) => getOrDownloadImage(url)));
  }

  /// Checks SharedPreferences and disk for the local cached File.
  /// Synchronous and zero-delay if file was previously downloaded.
  File? getLocalCachedImage(String url) {
    if (!_initialized || _cacheDir == null) return null;
    try {
      final key = _getPrefsKey(url);
      final savedPath = _prefs?.getString(key);

      if (savedPath != null && savedPath.isNotEmpty) {
        final savedFile = File(savedPath);
        if (savedFile.existsSync()) {
          return savedFile;
        }
      }

      final fileName = Uri.parse(url).pathSegments.last;
      final file = File('${_cacheDir!.path}/$fileName');
      if (file.existsSync()) {
        final prefs = _prefs;
        if (prefs != null) {
          unawaited(prefs.setString(key, file.path));
        }
        return file;
      }
    } catch (_) {}
    return null;
  }

  /// Fetches image from local cache or downloads it to disk & SharedPreferences.
  /// Deduplicates concurrent download requests for the same URL using Completers.
  Future<File?> getOrDownloadImage(String url) async {
    if (!_initialized) await init();
    if (_cacheDir == null) return null;

    final localFile = getLocalCachedImage(url);
    if (localFile != null) {
      return localFile;
    }

    if (_pendingDownloads.containsKey(url)) {
      return await _pendingDownloads[url];
    }

    final completer = Completer<File?>();
    _pendingDownloads[url] = completer.future;

    try {
      final file = await _downloadAndSaveImage(url);
      completer.complete(file);
      return file;
    } catch (e) {
      completer.complete(null);
      return null;
    } finally {
      final _ = _pendingDownloads.remove(url);
    }
  }

  Future<File?> _downloadAndSaveImage(String url) async {
    if (_cacheDir == null) return null;
    try {
      final fileName = Uri.parse(url).pathSegments.last;
      final file = File('${_cacheDir!.path}/$fileName');
      final key = _getPrefsKey(url);

      if (await file.exists()) {
        await _prefs?.setString(key, file.path);
        return file;
      }

      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8);
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set('User-Agent', 'MindFlowApp/1.0');
      final response = await request.close().timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final bytes =
            await response.fold<List<int>>([], (p, e) => p..addAll(e));
        await file.writeAsBytes(bytes);
        await _prefs?.setString(key, file.path);
        AppLogger.d('Saved image to disk and SharedPreferences: $fileName -> ${file.path}');
        return file;
      }
    } catch (e, stackTrace) {
      AppLogger.w('Failed to cache image locally: $url', e, stackTrace);
    }
    return null;
  }
}
