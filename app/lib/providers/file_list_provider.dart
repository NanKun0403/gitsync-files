import 'package:flutter/material.dart';
import '../models/file_manifest.dart';
import '../services/sync_service.dart';

class FileListProvider extends ChangeNotifier {
  final SyncService syncService;
  FileManifest? _manifest;
  bool _isLoading = false;
  String? _error;

  FileListProvider({required this.syncService});

  FileManifest? get manifest => _manifest;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _manifest = await syncService.getManifest();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<SyncFile> uploadFile(String filePath, String userName) async {
    _isLoading = true;
    notifyListeners();

    try {
      final syncFile = await syncService.uploadFile(filePath, userName);
      await refresh();
      return syncFile;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<String> downloadFile(String fileId, String outputDir) async {
    return syncService.downloadFile(fileId, outputDir);
  }
}