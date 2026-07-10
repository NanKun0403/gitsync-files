import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import '../models/file_manifest.dart';
import '../providers/file_list_provider.dart';
import 'pdf_viewer_screen.dart';
import 'pdf_editor_screen.dart';

class FileDetailScreen extends StatelessWidget {
  final SyncFile file;

  const FileDetailScreen({super.key, required this.file});

  Future<void> _downloadAndOpen(BuildContext context) async {
    final provider = context.read<FileListProvider>();
    final dir = await getApplicationDocumentsDirectory();
    final outputDir = '${dir.path}/gitsync_downloads';

    // 确保目录存在
    await Directory(outputDir).create(recursive: true);

    try {
      final filePath = await provider.downloadFile(file.id, outputDir);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已下载到: $filePath')),
        );

        // 打开文件
        await OpenFilex.open(filePath);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载失败: $e')),
        );
      }
    }
  }

  Future<void> _openPdfEditor(BuildContext context) async {
    final provider = context.read<FileListProvider>();
    final dir = await getApplicationDocumentsDirectory();
    final outputDir = '${dir.path}/gitsync_downloads';
    await Directory(outputDir).create(recursive: true);

    try {
      final filePath = await provider.downloadFile(file.id, outputDir);

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfEditorScreen(filePath: filePath),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载失败: $e')),
        );
      }
    }
  }

  Future<void> _openPdfViewer(BuildContext context) async {
    final provider = context.read<FileListProvider>();
    final dir = await getApplicationDocumentsDirectory();
    final outputDir = '${dir.path}/gitsync_downloads';
    await Directory(outputDir).create(recursive: true);

    try {
      final filePath = await provider.downloadFile(file.id, outputDir);

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(filePath: filePath),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载失败: $e')),
        );
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isPdf = file.mimeType == 'application/pdf';

    return Scaffold(
      appBar: AppBar(
        title: Text(file.name),
        actions: [
          if (isPdf)
            IconButton(
              icon: const Icon(Icons.visibility),
              tooltip: '查看 PDF',
              onPressed: () => _openPdfViewer(context),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 文件信息卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('文件名', file.name),
                    const Divider(),
                    _infoRow('类型', file.mimeType),
                    const Divider(),
                    _infoRow('大小', _formatSize(file.currentSize)),
                    const Divider(),
                    _infoRow('上传者', file.uploadedBy),
                    const Divider(),
                    _infoRow('上传时间', file.uploadedAt.toLocal().toString()),
                    const Divider(),
                    _infoRow('版本数', '${file.versions.length}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 下载按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _downloadAndOpen(context),
                icon: const Icon(Icons.download),
                label: const Text('下载并打开'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),

            // PDF 编辑按钮
            if (isPdf) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openPdfEditor(context),
                  icon: const Icon(Icons.edit),
                  label: const Text('PDF 编辑（拆分）'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openPdfViewer(context),
                  icon: const Icon(Icons.visibility),
                  label: const Text('PDF 预览'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 版本历史
            const Text(
              '版本历史',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: file.versions.isEmpty
                  ? const Center(child: Text('暂无版本历史'))
                  : ListView.builder(
                      itemCount: file.versions.length,
                      itemBuilder: (context, index) {
                        final version = file.versions[index];
                        return ListTile(
                          leading: const Icon(Icons.history),
                          title: Text('版本 ${file.versions.length - index}'),
                          subtitle: Text(
                              version.timestamp.toLocal().toString()),
                          trailing: Text(
                            version.commitSha.isNotEmpty
                                ? version.commitSha.substring(0, 7)
                                : 'pending',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}