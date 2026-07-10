import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends StatelessWidget {
  final String filePath;

  const PdfViewerScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF 查看')),
      body: SfPdfViewer.file(
        File(filePath),
        enableTextSelection: true,
        canShowScrollHead: true,
        canShowScrollStatus: true,
      ),
    );
  }
}