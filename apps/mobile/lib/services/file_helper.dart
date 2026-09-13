import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class FileHelper {
  /// Generates a standardized export file path in the application temporary directory
  static Future<File> createTempExportFile({
    required String prefix,
    required String extension,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final ext = extension.startsWith('.') ? extension : '.$extension';
    final fileName = '${prefix}_$timestamp$ext';
    return File('${tempDir.path}/$fileName');
  }

  /// Appends UTF-8 Byte Order Mark (BOM: \uFEFF) to ensure Microsoft Excel displays Vietnamese characters properly
  static List<int> encodeUtf8WithBom(String content) {
    // UTF-8 BOM bytes: 0xEF, 0xBB, 0xBF
    final bom = [0xEF, 0xBB, 0xBF];
    final encodedContent = utf8.encode(content);
    return [...bom, ...encodedContent];
  }
}
