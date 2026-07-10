import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/github_api.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _ownerController = TextEditingController();
  final _repoController = TextEditingController();
  final _tokenController = TextEditingController();
  final _cdnController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _ownerController.dispose();
    _repoController.dispose();
    _tokenController.dispose();
    _cdnController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _ownerController.text = prefs.getString('github_owner') ?? '';
    _repoController.text = prefs.getString('github_repo') ?? 'gitsync-files';
    _tokenController.text = prefs.getString('github_token') ?? '';
    _cdnController.text = prefs.getString('cdn_base') ?? '';
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('github_owner', _ownerController.text);
      await prefs.setString('github_repo', _repoController.text);
      await prefs.setString('github_token', _tokenController.text);
      await prefs.setString('cdn_base', _cdnController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('设置已保存')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _testConnection() async {
    if (_ownerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先填写 GitHub 用户名')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final api = GitHubApiService(
        repoOwner: _ownerController.text,
        repoName: _repoController.text,
        token: _tokenController.text.isNotEmpty
            ? _tokenController.text
            : null,
      );

      // 测试读取 manifest
      await api.getManifestContent();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 连接成功！manifest.json 可正常读取'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 连接失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // GitHub 配置区域
          const Text(
            'GitHub 配置',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ownerController,
            decoration: const InputDecoration(
              labelText: 'GitHub 用户名/组织',
              hintText: 'your-username',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _repoController,
            decoration: const InputDecoration(
              labelText: '仓库名',
              hintText: 'gitsync-files',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.folder),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tokenController,
            decoration: const InputDecoration(
              labelText: 'GitHub Personal Access Token',
              hintText: 'ghp_xxxxxxxxxxxx',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.key),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 20),

          // CDN 配置区域
          const Text(
            'CDN 配置',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cdnController,
            decoration: const InputDecoration(
              labelText: 'CDN 地址（留空使用 jsDelivr）',
              hintText: 'https://cdn.jsdelivr.net/gh/...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.cloud),
            ),
          ),
          const SizedBox(height: 24),

          // 操作按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: const Icon(Icons.save),
              label: Text(_isSaving ? '保存中...' : '保存设置'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isSaving ? null : _testConnection,
              icon: const Icon(Icons.wifi_tethering),
              label: Text(_isSaving ? '测试中...' : '测试连接'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 帮助信息
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '使用帮助',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. 在 GitHub 上创建仓库（如 gitsync-files）\n'
                    '2. 在仓库中创建 manifest.json（初始内容：{"files":[],"last_updated":"2024-01-01T00:00:00Z"}）\n'
                    '3. 生成 Personal Access Token（权限选 repo）\n'
                    '4. 在本页面填入以上信息并保存\n'
                    '5. 返回主页刷新即可看到文件列表',
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      // 可以跳转到 GitHub Token 创建页面
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('创建 GitHub Token'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}