import 'dart:convert';

class FileVersion {
  String commitSha;
  final DateTime timestamp;
  int size;

  FileVersion({
    required this.commitSha,
    required this.timestamp,
    required this.size,
  });

  Map<String, dynamic> toJson() => {
        'commit': commitSha,
        'timestamp': timestamp.toIso8601String(),
        'size': size,
      };

  factory FileVersion.fromJson(Map<String, dynamic> json) => FileVersion(
        commitSha: json['commit'],
        timestamp: DateTime.parse(json['timestamp']),
        size: json['size'],
      );
}

class SyncFile {
  final String id; // UUID
  final String name; // 原始文件名
  final String mimeType;
  int currentSize;
  final List<FileVersion> versions;
  String currentCommit;
  final String uploadedBy;
  final DateTime uploadedAt;

  SyncFile({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.currentSize,
    required this.versions,
    required this.currentCommit,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  String get storagePath => 'files/$id/$name';

  String get downloadUrl =>
      'https://raw.githubusercontent.com/REPO_OWNER/REPO_NAME/main/$storagePath';

  String get cdnDownloadUrl => 'https://cdn.example.com/$storagePath';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': mimeType,
        'size': currentSize,
        'versions': versions.map((v) => v.toJson()).toList(),
        'current_commit': currentCommit,
        'uploaded_by': uploadedBy,
        'uploaded_at': uploadedAt.toIso8601String(),
      };

  factory SyncFile.fromJson(Map<String, dynamic> json) => SyncFile(
        id: json['id'],
        name: json['name'],
        mimeType: json['type'],
        currentSize: json['size'],
        versions: (json['versions'] as List)
            .map((v) => FileVersion.fromJson(v))
            .toList(),
        currentCommit: json['current_commit'],
        uploadedBy: json['uploaded_by'],
        uploadedAt: DateTime.parse(json['uploaded_at']),
      );
}

class FileManifest {
  final List<SyncFile> files;
  DateTime lastUpdated;

  FileManifest({required this.files, required this.lastUpdated});

  Map<String, dynamic> toJson() => {
        'files': files.map((f) => f.toJson()).toList(),
        'last_updated': lastUpdated.toIso8601String(),
      };

  factory FileManifest.fromJson(Map<String, dynamic> json) => FileManifest(
        files: (json['files'] as List)
            .map((f) => SyncFile.fromJson(f))
            .toList(),
        lastUpdated: DateTime.parse(json['last_updated']),
      );

  String toJsonString() => jsonEncode(toJson());

  factory FileManifest.fromJsonString(String str) =>
      FileManifest.fromJson(jsonDecode(str));
}