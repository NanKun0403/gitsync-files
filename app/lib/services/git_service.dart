import 'dart:io';

class GitService {
  final String repoPath;

  GitService(this.repoPath);

  Future<String> _runGit(List<String> args) async {
    final result = await Process.run(
      'git',
      args,
      workingDirectory: repoPath,
    );
    if (result.exitCode != 0) {
      throw Exception('Git error: ${result.stderr}');
    }
    return result.stdout.toString().trim();
  }

  Future<void> clone(String repoUrl, {String? token}) async {
    String url = repoUrl;
    if (token != null) {
      url = repoUrl.replaceFirst('https://', 'https://$token@');
    }
    await _runGit(['clone', url, repoPath]);
  }

  Future<void> initRepo() async {
    await _runGit(['init']);
  }

  Future<void> pull({String remote = 'origin', String branch = 'main'}) async {
    await _runGit(['pull', remote, branch]);
  }

  Future<void> add(String filePath) async {
    await _runGit(['add', filePath]);
  }

  Future<void> commit(String message) async {
    await _runGit(['commit', '-m', message]);
  }

  Future<void> push({String remote = 'origin', String branch = 'main'}) async {
    await _runGit(['push', remote, branch]);
  }

  Future<void> remoteAdd(String url, {String? token}) async {
    final remoteUrl = token != null
        ? url.replaceFirst('https://', 'https://$token@')
        : url;
    await _runGit(['remote', 'add', 'origin', remoteUrl]);
  }

  /// 获取文件的版本历史
  Future<List<Map<String, String>>> getFileHistory(String filePath) async {
    final log = await _runGit([
      'log',
      '--format=%H|%aI',
      '--',
      filePath,
    ]);
    if (log.isEmpty) return [];
    return log.split('\n').map((line) {
      final parts = line.split('|');
      return {'commit': parts[0], 'timestamp': parts[1]};
    }).toList();
  }

  /// 检出文件的历史版本
  Future<List<int>> checkoutFileVersion(
      String filePath, String commitSha) async {
    final result = await Process.run(
      'git',
      ['show', '$commitSha:$filePath'],
      workingDirectory: repoPath,
    );
    if (result.exitCode != 0) {
      throw Exception('Failed to checkout version: ${result.stderr}');
    }
    return result.stdout;
  }

  Future<String> currentCommit() async {
    return _runGit(['rev-parse', 'HEAD']);
  }

  /// 设置 git 用户信息
  Future<void> setUserInfo(String name, String email) async {
    await _runGit(['config', 'user.name', name]);
    await _runGit(['config', 'user.email', email]);
  }
}