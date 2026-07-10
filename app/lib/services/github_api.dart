import 'dart:convert';
import 'package:http/http.dart' as http;

class GitHubApiService {
  final String repoOwner;
  final String repoName;
  final String? token;

  String get _baseUrl => 'https://api.github.com/repos/$repoOwner/$repoName';

  GitHubApiService({
    required this.repoOwner,
    required this.repoName,
    this.token,
  });

  Map<String, String> get _headers => {
        'Accept': 'application/vnd.github.v3+json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  /// 获取 manifest.json 内容
  Future<String> getManifestContent() async {
    final url = '$_baseUrl/contents/manifest.json?ref=main';
    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final content = json['content'] as String;
      return utf8.decode(base64Decode(content.replaceAll('\n', '')));
    }
    throw Exception('Failed to fetch manifest: ${response.statusCode}');
  }

  /// 获取文件下载 URL（通过 CDN）
  String getFileDownloadUrl(String storagePath) {
    return 'https://cdn.jsdelivr.net/gh/$repoOwner/$repoName@main/$storagePath';
  }

  /// 直接下载文件内容
  Future<List<int>> downloadFile(String storagePath) async {
    final url = getFileDownloadUrl(storagePath);
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw Exception('Failed to download file: ${response.statusCode}');
  }

  /// 通过 GitHub API 上传文件（用于小文件）
  Future<void> uploadFileViaApi(
    String filePath,
    String content,
    String commitMessage,
  ) async {
    final url = '$_baseUrl/contents/$filePath';
    final body = jsonEncode({
      'message': commitMessage,
      'content': base64Encode(utf8.encode(content)),
      'branch': 'main',
    });
    final response = await http.put(
      Uri.parse(url),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: body,
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to upload via API: ${response.statusCode}');
    }
  }

  /// 获取仓库最新 commit SHA
  Future<String> getLatestCommitSha() async {
    final url = '$_baseUrl/git/ref/heads/main';
    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['object']['sha'];
    }
    throw Exception('Failed to fetch latest commit: ${response.statusCode}');
  }
}