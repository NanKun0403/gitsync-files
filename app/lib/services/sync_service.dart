import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import '../models/file_manifest.dart';
import 'git_service.dart';
import 'github_api.dart';

class SyncService {
  final GitService gitService;
  final GitHubApiService apiService;

  /// 本地存储 manifest.json 的缓存路径
  String? _repoCachePath;

  SyncService({
    required this.gitService,
    required this.apiService,
  });

  /// 获取或创建本地仓库缓存目录
  Future<String> get repoCachePath async {
    if (_repoCachePath != null) return _repoCachePath!;
    final dir = await getApplicationSupportDirectory();
    _repoCachePath = '${dir.path}/gitsync_repo';
    return _repoCachePath!;
  }

  /// 确保本地仓库已 clone
  Future<void> ensureRepo() async {
    final path = await repoCachePath;
    final repoDir = Directory(path);
    if (!repoDir.existsSync()) {
      await repoDir.create(recursive: true);
      // 用 API 获取 token
      await gitService.clone(
        'https://github.com/${apiService.repoOwner}/${apiService.repoName}.git',
        token: apiService.token,
      );
    }
  }

  /// 获取当前文件清单
  Future<FileManifest> getManifest() async {
    final path = await repoCachePath;
    // 优先拉取最新
    try {
      final gs = GitService(path);
      await gs.pull();
    } catch (_) {
      // pull 失败时继续用本地缓存
    }

    final manifestPath = '$path/manifest.json';
    if (!File(manifestPath).existsSync()) {
      return FileManifest(
        files: [],
        lastUpdated: DateTime.now(),
      );
    }
    final content = File(manifestPath).readAsStringSync();
    return FileManifest.fromJsonString(content);
  }

  /// 上传文件
  Future<SyncFile> uploadFile(
    String localFilePath,
    String uploadedBy, {
    String? branch,
  }) async {
    await ensureRepo();
    final path = await repoCachePath;
    final gs = GitService(path);

    // 1. Pull 最新
    await gs.pull();

    // 2. 读取 manifest
    final manifest = await getManifest();

    // 3. 复制文件到仓库
    final file = File(localFilePath);
    final fileName = file.uri.pathSegments.last;
    const uuid = Uuid();
    final fileId = uuid.v4();
    final storagePath = 'files/$fileId/$fileName';

    final destDir = Directory('$path/files/$fileId');
    await destDir.create(recursive: true);
    await file.copy('${destDir.path}/$fileName');

    // 4. 更新 manifest
    final now = DateTime.now();
    final syncFile = SyncFile(
      id: fileId,
      name: fileName,
      mimeType: _getMimeType(fileName),
      currentSize: await file.length(),
      versions: [
        FileVersion(
          commitSha: '', // 将在 commit 后填充
          timestamp: now,
          size: await file.length(),
        ),
      ],
      currentCommit: '',
      uploadedBy: uploadedBy,
      uploadedAt: now,
    );

    manifest.files.add(syncFile);
    manifest.lastUpdated = now;

    // 5. 写入新 manifest
    File('$path/manifest.json')
        .writeAsStringSync(manifest.toJsonString());

    // 6. Git commit + push
    await gs.add(storagePath);
    await gs.add('manifest.json');
    await gs.commit('upload: $fileName from $uploadedBy');
    final commitSha = await gs.currentCommit();
    await gs.push();

    // 7. 更新 commit 信息
    syncFile.currentCommit = commitSha;
    syncFile.versions[0].commitSha = commitSha;

    return syncFile;
  }

  /// 下载文件到指定路径
  Future<String> downloadFile(String fileId, String outputDir) async {
    final manifest = await getManifest();
    final syncFile = manifest.files.firstWhere((f) => f.id == fileId);

    final outputPath = '$outputDir/${syncFile.name}';
    // 确保输出目录存在
    await Directory(outputDir).create(recursive: true);

    // 通过 CDN 下载
    final bytes = await apiService.downloadFile(syncFile.storagePath);
    await File(outputPath).writeAsBytes(bytes);

    return outputPath;
  }

  /// 获取文件版本历史
  Future<List<FileVersion>> getVersionHistory(String fileId) async {
    final manifest = await getManifest();
    final syncFile = manifest.files.firstWhere((f) => f.id == fileId);

    final path = await repoCachePath;
    final gs = GitService(path);

    final history = await gs.getFileHistory(syncFile.storagePath);
    return history
        .map((h) => FileVersion(
              commitSha: h['commit']!,
              timestamp: DateTime.parse(h['timestamp']!),
              size: 0, // size 需要额外查询
            ))
        .toList();
  }

  /// 恢复文件到指定版本
  Future<String> restoreVersion(String fileId, String commitSha) async {
    final path = await repoCachePath;
    final gs = GitService(path);

    final manifest = await getManifest();
    final syncFile = manifest.files.firstWhere((f) => f.id == fileId);

    final bytes = await gs.checkoutFileVersion(
      syncFile.storagePath,
      commitSha,
    );

    // 替换当前文件
    final fullPath = '$path/${syncFile.storagePath}';
    await File(fullPath).writeAsBytes(bytes);

    // 更新 manifest
    syncFile.currentCommit = commitSha;
    syncFile.currentSize = bytes.length;
    manifest.lastUpdated = DateTime.now();
    File('$path/manifest.json')
        .writeAsStringSync(manifest.toJsonString());

    await gs.add(syncFile.storagePath);
    await gs.add('manifest.json');
    await gs.commit('restore: ${syncFile.name} to $commitSha');
    await gs.push();

    return syncFile.storagePath;
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }
}