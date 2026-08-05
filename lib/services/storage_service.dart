import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/qr_record.dart';

class StorageService {
  static const String _fileName = 'qr_history.json';
  static List<QrRecord>? mockRecords;

  static Future<File> _getHistoryFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  static Future<List<QrRecord>> loadRecords() async {
    if (mockRecords != null) return mockRecords!;
    try {
      final file = await _getHistoryFile();
      if (!await file.exists()) return [];
      final contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      return jsonList.map((json) => QrRecord.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveRecords(List<QrRecord> records) async {
    if (mockRecords != null) {
      mockRecords = records;
      return;
    }
    try {
      final file = await _getHistoryFile();
      final jsonList = records.map((r) => r.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (_) {}
  }

  static Future<void> addRecord(QrRecord record) async {
    if (mockRecords != null) {
      mockRecords!.insert(0, record);
      return;
    }
    try {
      final records = await loadRecords();
      // Insert at the beginning of the list to show newest records first
      records.insert(0, record);
      await saveRecords(records);
    } catch (_) {}
  }

  static Future<void> deleteRecord(String id) async {
    if (mockRecords != null) {
      mockRecords!.removeWhere((r) => r.id == id);
      return;
    }
    try {
      final records = await loadRecords();
      records.removeWhere((r) => r.id == id);
      await saveRecords(records);
    } catch (_) {}
  }
}
