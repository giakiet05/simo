import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('simo.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const boolType = 'INTEGER NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
      CREATE TABLE categories (
        id $idType,
        cloud_id TEXT,
        name $textType,
        type $textType,
        icon TEXT,
        color TEXT,
        synced INTEGER DEFAULT 0,
        created_at $textType,
        updated_at $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        cloud_id TEXT,
        category_id TEXT,
        recurring_config_id TEXT,
        amount $realType,
        formula TEXT,
        note TEXT,
        type $textType,
        synced INTEGER DEFAULT 0,
        created_at $textType,
        updated_at $textType,
        FOREIGN KEY (category_id) REFERENCES categories (id),
        FOREIGN KEY (recurring_config_id) REFERENCES recurring_configs (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE recurring_configs (
        id $idType,
        cloud_id TEXT,
        category_id TEXT,
        name $textType,
        amount $realType,
        type $textType,
        frequency $textType,
        interval $intType,
        day_of_week INTEGER,
        day_of_month INTEGER,
        next_run $textType,
        is_active $boolType,
        synced INTEGER DEFAULT 0,
        created_at $textType,
        updated_at $textType,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_deletions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cloud_id $textType,
        table_name $textType,
        deleted_at $textType
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Migrate from is_system to type
      // Create new table with type column
      await db.execute('''
        CREATE TABLE categories_new (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Copy data, mapping is_system categories to types
      final oldCategories = await db.query('categories');
      final now = DateTime.now().toIso8601String();

      for (var cat in oldCategories) {
        final id = cat['id'] as String;
        String type = 'expense'; // default

        // Map income categories
        if (id == 'sys_salary' || id == 'cat_salary' ||
            id.contains('salary') || id.contains('income') ||
            id.contains('bonus') || id.contains('investment')) {
          type = 'income';
        }

        // Skip Unknown category
        if (id == 'sys_unknown') continue;

        await db.insert('categories_new', {
          'id': cat['id'],
          'name': cat['name'],
          'type': type,
          'created_at': cat['created_at'] ?? now,
          'updated_at': now,
        });
      }

      // Drop old table and rename new one
      await db.execute('DROP TABLE categories');
      await db.execute('ALTER TABLE categories_new RENAME TO categories');
    }

    if (oldVersion < 4) {
      // Add icon and color columns to categories
      await db.execute('ALTER TABLE categories ADD COLUMN icon TEXT');
      await db.execute('ALTER TABLE categories ADD COLUMN color TEXT');
    }

    if (oldVersion < 5) {
      // Add sync fields to all tables
      await db.execute('ALTER TABLE categories ADD COLUMN cloud_id TEXT');
      await db.execute('ALTER TABLE categories ADD COLUMN synced INTEGER DEFAULT 0');

      await db.execute('ALTER TABLE transactions ADD COLUMN cloud_id TEXT');
      await db.execute('ALTER TABLE transactions ADD COLUMN synced INTEGER DEFAULT 0');

      await db.execute('ALTER TABLE recurring_configs ADD COLUMN cloud_id TEXT');
      await db.execute('ALTER TABLE recurring_configs ADD COLUMN synced INTEGER DEFAULT 0');

      // Create pending_deletions table
      await db.execute('''
        CREATE TABLE pending_deletions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          cloud_id TEXT NOT NULL,
          table_name TEXT NOT NULL,
          deleted_at TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 6) {
      // Remove default categories (id starts with 'cat_')
      print('[DB] Migration v6: Removing default categories');

      // Get all default categories
      final defaultCats = await db.query(
        'categories',
        where: "id LIKE 'cat_%'",
      );

      print('[DB] Found ${defaultCats.length} default categories to remove');

      // Mark them for deletion on cloud
      final now = DateTime.now().toIso8601String();
      for (var cat in defaultCats) {
        final cloudId = cat['cloud_id'] as String?;
        if (cloudId != null) {
          await db.insert('pending_deletions', {
            'cloud_id': cloudId,
            'table_name': 'categories',
            'deleted_at': now,
          });
        }
      }

      // Delete from local
      final deletedCount = await db.delete(
        'categories',
        where: "id LIKE 'cat_%'",
      );

      print('[DB] Deleted $deletedCount default categories from local');
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
