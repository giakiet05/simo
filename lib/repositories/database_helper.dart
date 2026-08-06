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
      version: 11,
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
        budget_limit REAL,
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
        transaction_date TEXT,
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

    await db.execute('''
      CREATE TABLE loan_contacts (
        id $idType,
        cloud_id TEXT,
        contact_name $textType,
        type $textType,
        total_amount $realType,
        remaining_amount $realType,
        status $textType,
        synced INTEGER DEFAULT 0,
        created_at $textType,
        updated_at $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE loan_transactions (
        id $idType,
        cloud_id TEXT,
        loan_id $textType,
        amount $realType,
        type $textType,
        date $textType,
        due_date TEXT,
        note TEXT,
        synced INTEGER DEFAULT 0,
        created_at $textType,
        updated_at $textType,
        FOREIGN KEY (loan_id) REFERENCES loan_contacts (id) ON DELETE CASCADE
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

    if (oldVersion < 7) {
      // Create loans and loan_transactions tables
      const idType = 'TEXT PRIMARY KEY';
      const textType = 'TEXT NOT NULL';
      const realType = 'REAL NOT NULL';

      await db.execute('''
        CREATE TABLE IF NOT EXISTS loan_contacts (
          id $idType,
          cloud_id TEXT,
          contact_name $textType,
          type $textType,
          total_amount $realType,
          remaining_amount $realType,
          status $textType,
          due_date TEXT,
          note TEXT,
          synced INTEGER DEFAULT 0,
          created_at $textType,
          updated_at $textType
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS loan_transactions (
          id $idType,
          cloud_id TEXT,
          loan_id $textType,
          amount $realType,
          type $textType,
          date $textType,
          note TEXT,
          synced INTEGER DEFAULT 0,
          created_at $textType,
          updated_at $textType,
          FOREIGN KEY (loan_id) REFERENCES loan_contacts (id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 8) {
      print('[DB] Migration v8: Adjusting loan tables');
      // Add due_date to loan_transactions
      try {
        await db.execute('ALTER TABLE loan_transactions ADD COLUMN due_date TEXT');
      } catch (e) {
        print('[DB] Migration v8: due_date column might already exist, skipping.');
      }
      // Note: SQLite doesn't support DROP COLUMN easily. We just leave due_date and note in loans table but stop using them.
    }

    if (oldVersion < 9) {
      print('[DB] Migration v9: Rename loans to loan_contacts');
      try {
        await db.execute('ALTER TABLE loans RENAME TO loan_contacts');
      } catch (e) {
        print('[DB] Migration v9: loans table not found or already renamed, skipping.');
      }
    }

    if (oldVersion < 10) {
      print('[DB] Migration v10: Add budget_limit to categories');
      await db.execute('ALTER TABLE categories ADD COLUMN budget_limit REAL');
    }

    if (oldVersion < 11) {
      print('[DB] Migration v11: Add transaction_date to transactions');
      await db.execute('ALTER TABLE transactions ADD COLUMN transaction_date TEXT');
    }
  }

  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('loan_transactions');
      await txn.delete('transactions');
      await txn.delete('recurring_configs');
      await txn.delete('pending_deletions');
      await txn.delete('loan_contacts');
      await txn.delete('categories');
    });
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
