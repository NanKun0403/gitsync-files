import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/file_list_provider.dart';
import '../widgets/file_card.dart';
import 'file_detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<FileListProvider>().refresh();
    });
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.pickFiles();
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;

    if (!mounted) return;

    try {
      await context.read<FileListProvider>().uploadFile(file.path!, 'app_user');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${file.name} 上传成功!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GitSync'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: '刷新',
            onPressed: () => context.read<FileListProvider>().refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '设置',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<FileListProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.manifest == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => provider.refresh(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }
          final files = provider.manifest?.files ?? [];
          if (files.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无文件', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('点击右下角 + 按钮上传文件'),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.refresh(),
            child: ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                return FileCard(
                  file: file,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FileDetailScreen(file: file),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndUpload,
        tooltip: '上传文件',
        child: const Icon(Icons.add),
      ),
    );
  }
}