import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final dbPath = '/home/giakiet05/.local/share/simo/simo.db'; // Adjust path if needed
  if (!File(dbPath).existsSync()) {
    print("DB not found at $dbPath");
    return;
  }
  final db = await openDatabase(dbPath);
  final maps = await db.query('transactions');
  for (var map in maps) {
    print(map);
  }
}
