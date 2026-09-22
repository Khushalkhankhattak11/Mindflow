import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadedItem {
  final String id;
  final String title;
  final String localFilePath;
  final int fileSize;
  final DateTime downloadedAt;

  DownloadedItem({
    required this.id,
    required this.title,
    required this.localFilePath,
    required this.fileSize,
    required this.downloadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'localFilePath': localFilePath,
      'fileSize': fileSize,
      'downloadedAt': downloadedAt.toIso8601String(),
    };
  }

  factory DownloadedItem.fromMap(Map<String, dynamic> map) {
    return DownloadedItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      localFilePath: map['localFilePath'] ?? '',
      fileSize: map['fileSize'] ?? 0,
      downloadedAt: DateTime.tryParse(map['downloadedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class DownloadService extends ChangeNotifier {
  List<DownloadedItem> _downloadedSessions = [];
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  List<DownloadedItem> get downloadedSessions => _downloadedSessions;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;

  int get totalStorageBytes {
    int total = 0;
    for (var item in _downloadedSessions) {
      total += item.fileSize;
    }
    return total;
  }

  String get formattedTotalStorage {
    final mb = totalStorageBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  DownloadService() {
    _loadDownloadedItems();
  }

  Future<void> _loadDownloadedItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? itemsJson = prefs.getStringList('offline_downloaded_items');
      if (itemsJson != null) {
        _downloadedSessions = itemsJson
            .map((str) => DownloadedItem.fromMap(Map<String, dynamic>.from(Uri.splitQueryString(str))))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading offline downloads: $e');
      }
    }
    notifyListeners();
  }

  bool isSessionDownloaded(String title) {
    return _downloadedSessions.any((item) => item.title == title);
  }

  Future<bool> downloadSession({
    required String id,
    required String title,
    required String remoteUrl,
  }) async {
    if (isSessionDownloaded(title)) return true;

    _isDownloading = true;
    _downloadProgress = 0.1;
    notifyListeners();

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = '${id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.mp3';
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);

      // Simulate download progress steps
      for (int i = 2; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        _downloadProgress = i / 10.0;
        notifyListeners();
      }

      // Save dummy audio file content for offline playback placeholder
      await file.writeAsString('OFFLINE_AUDIO_FILE_DATA_$title');
      final size = await file.length();

      final newItem = DownloadedItem(
        id: id,
        title: title,
        localFilePath: filePath,
        fileSize: size > 0 ? size : 4200000, // ~4.2 MB mock size if small
        downloadedAt: DateTime.now(),
      );

      _downloadedSessions.add(newItem);
      await _saveToPrefs();

      _isDownloading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isDownloading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteDownloadedSession(String id) async {
    try {
      final index = _downloadedSessions.indexWhere((item) => item.id == id);
      if (index != -1) {
        final item = _downloadedSessions[index];
        final file = File(item.localFilePath);
        if (await file.exists()) {
          await file.delete();
        }
        _downloadedSessions.removeAt(index);
        await _saveToPrefs();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> itemsJson = _downloadedSessions
          .map((item) => Uri(queryParameters: item.toMap().map((k, v) => MapEntry(k, v.toString()))).query)
          .toList();
      await prefs.setStringList('offline_downloaded_items', itemsJson);
    } catch (_) {}
  }
}
