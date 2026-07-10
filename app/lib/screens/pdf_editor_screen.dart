import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfEditorScreen extends StatefulWidget {
  final String filePath;

  const PdfEditorScreen({super.key, required this.filePath});

  @override
  State<PdfEditorScreen> createState() => _PdfEditorScreenState();
}

class _PdfEditorScreenState extends State<PdfEditorScreen> {
  int _pageCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPdfInfo();
  }

  Future<void> _loadPdfInfo() async {
    try {
      final document =
          PdfDocument(inputBytes: File(widget.filePath).readAsBytesSync());
      setState(() {
        _pageCount = document.pages.count;
        _isLoading = false;
      });
      document.dispose();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载 PDF 失败: $e')),
        );
      }
    }
  }

  Future<void> _splitPdf(int splitAfterPage) async {
    if (splitAfterPage <= 0 || splitAfterPage >= _pageCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法在指定位置拆分：超出页码范围')),
      );
      return;
    }

    try {
      final inputBytes = File(widget.filePath).readAsBytesSync();
      final document = PdfDocument(inputBytes: inputBytes);

      // 前半部分
      final part1 = PdfDocument();
      for (int i = 0; i < splitAfterPage && i < document.pages.count; i++) {
        part1.pages.add().graphics.drawPdfTemplate(
              document.pages[i].createTemplate(),
              Offset.zero,
              Size(document.pages[i].size.width,
                  document.pages[i].size.height),
            );
      }

      // 后半部分
      final part2 = PdfDocument();
      for (int i = splitAfterPage; i < document.pages.count; i++) {
        part2.pages.add().graphics.drawPdfTemplate(
              document.pages[i].createTemplate(),
              Offset.zero,
              Size(document.pages[i].size.width,
                  document.pages[i].size.height),
            );
      }

      final dir = widget.filePath.substring(0, widget.filePath.lastIndexOf(RegExp(r'[/\\]')));
      final baseName =
          widget.filePath.split(RegExp(r'[/\\]')).last.replaceAll('.pdf', '');
      await File('$dir/${baseName}_part1.pdf').writeAsBytes(await part1.save());
      await File('$dir/${baseName}_part2.pdf').writeAsBytes(await part2.save());

      document.dispose();
      part1.dispose();
      part2.dispose();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF 拆分完成！已生成 ${baseName}_part1.pdf 和 ${baseName}_part2.pdf'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('拆分失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF 编辑')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PDF 信息
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('文件名: ${widget.filePath.split(RegExp(r'[/\\]')).last}'),
                          const SizedBox(height: 8),
                          Text('总页数: $_pageCount'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 操作按钮
                  const Text(
                    '拆分操作',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // 拆分为两半
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _splitPdf(_pageCount ~/ 2),
                      icon: const Icon(Icons.content_cut),
                      label: Text('从中间拆分为两半 (${_pageCount ~/ 2}/${_pageCount - (_pageCount ~/ 2)} 页)'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 拆分前 N 页
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showSplitDialog(),
                      icon: const Icon(Icons.more_horiz),
                      label: const Text('自定义拆分位置...'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _showSplitDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('拆分 PDF'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('在第几页之后拆分？'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '拆分位置',
                hintText: '1 ~ ${_pageCount - 1}',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null && page > 0 && page < _pageCount) {
                Navigator.pop(context, page);
              }
            },
            child: const Text('确认拆分'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _splitPdf(result);
    }
  }
}