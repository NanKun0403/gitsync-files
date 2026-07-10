import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/sync_service.dart';
import 'services/github_api.dart';
import 'services/git_service.dart';
import 'providers/file_list_provider.dart';
import 'screens/home_screen.dart';

const String _defaultRepo = 'gitsync-files';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final owner = prefs.getString('github_owner') ?? '';
  final repo = prefs.getString('github_repo') ?? _defaultRepo;
  final token = prefs.getString('github_token') ?? '';

  final apiService = GitHubApiService(
    repoOwner: owner,
    repoName: repo,
    token: token.isNotEmpty ? token : null,
  );

  // 获取应用支持目录作为 git 仓库缓存路径
  final appSupportDir = await getAppSupportDir();
  final gitService = GitService('$appSupportDir/gitsync_repo');

  final syncService = SyncService(
    gitService: gitService,
    apiService: apiService,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<SyncService>.value(value: syncService),
        ChangeNotifierProvider(
          create: (_) => FileListProvider(syncService: syncService),
        ),
      ],
      child: const GitSyncApp(),
    ),
  );
}

Future<String> getAppSupportDir() async {
  // 使用 path_provider 获取应用支持目录
  final dir = await _getApplicationSupportDirectory();
  return dir.path;
}

// 兼容不同平台的实现
Future<Directory> _getApplicationSupportDirectory() async {
  // 使用环境变量或在项目目录中创建
  final homeDir = Platform.environment['HOME'] ??
      Platform.environment['USERPROFILE'] ??
      '.';
  final dir = Directory('$homeDir/.gitsync');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return dir;
}

class GitSyncApp extends StatelessWidget {
  const GitSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}