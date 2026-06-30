import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

class FileService {
  /// 保存内容：桌面写文件，Web 触发下载
  static Future<void> save(String content, String filename) async {
    if (kIsWeb) {
      final blob = html.Blob([content], 'text/plain');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', '$filename.txt')
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final diaryDir = io.Directory('${dir.path}/diary_cipher');
      if (!await diaryDir.exists()) {
        await diaryDir.create(recursive: true);
      }
      final file = io.File('${diaryDir.path}/$filename.txt');
      await file.writeAsString(content);
    }
  }

  /// 读取文件内容（仅桌面端）
  static Future<String?> read(String filename) async {
    if (kIsWeb) return null;
    final dir = await getApplicationDocumentsDirectory();
    final file = io.File('${dir.path}/diary_cipher/$filename.txt');
    if (await file.exists()) {
      return await file.readAsString();
    }
    return null;
  }

  /// 列出所有日记日期（仅桌面端）
  static Future<List<String>> listDates() async {
    if (kIsWeb) return [];
    final dir = await getApplicationDocumentsDirectory();
    final diaryDir = io.Directory('${dir.path}/diary_cipher');
    if (!await diaryDir.exists()) return [];
    final dates = <String>[];
    await for (final entity in diaryDir.list()) {
      if (entity is io.File && entity.path.endsWith('.txt')) {
        final name = entity.uri.pathSegments.last.replaceAll('.txt', '');
        dates.add(name);
      }
    }
    dates.sort((a, b) => b.compareTo(a));
    return dates;
  }

  /// 删除日记文件（同时删除对应提示文件）
  static Future<void> delete(String filename) async {
    if (kIsWeb) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = io.File('${dir.path}/diary_cipher/$filename.txt');
    if (await file.exists()) {
      await file.delete();
    }
    // 同时删除提示
    await deleteHint(filename);
  }

  /// 保存口令提示
  static Future<void> saveHint(String filename, String hint) async {
    if (kIsWeb) return;
    final dir = await getApplicationDocumentsDirectory();
    final hintDir = io.Directory('${dir.path}/diary_cipher/hints');
    if (!await hintDir.exists()) {
      await hintDir.create(recursive: true);
    }
    final file = io.File('${hintDir.path}/$filename.txt');
    await file.writeAsString(hint);
  }

  /// 读取口令提示
  static Future<String?> readHint(String filename) async {
    if (kIsWeb) return null;
    final dir = await getApplicationDocumentsDirectory();
    final file = io.File('${dir.path}/diary_cipher/hints/$filename.txt');
    if (await file.exists()) {
      return await file.readAsString();
    }
    return null;
  }

  /// 删除提示文件（内部使用）
  static Future<void> deleteHint(String filename) async {
    if (kIsWeb) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = io.File('${dir.path}/diary_cipher/hints/$filename.txt');
    if (await file.exists()) {
      await file.delete();
    }
  }
}