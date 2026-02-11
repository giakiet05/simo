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
      version: 3,
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
        name $textType,
        type $textType,
        created_at $textType,
        updated_at $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        category_id TEXT,
        recurring_config_id TEXT,
        amount $realType,
        formula TEXT,
        note TEXT,
        type $textType,
        created_at $textType,
        updated_at $textType,
        FOREIGN KEY (category_id) REFERENCES categories (id),
        FOREIGN KEY (recurring_config_id) REFERENCES recurring_configs (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE recurring_configs (
        id $idType,
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
        created_at $textType,
        updated_at $textType,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // Insert default categories
    final defaultCategories = [
      {'id': 'cat_salary', 'name': 'Salary', 'type': 'income'},
      {'id': 'cat_bonus', 'name': 'Bonus', 'type': 'income'},
      {'id': 'cat_investment', 'name': 'Investment', 'type': 'income'},
      {'id': 'cat_other_income', 'name': 'Other Income', 'type': 'income'},
      {'id': 'cat_food', 'name': 'Food & Dining', 'type': 'expense'},
      {'id': 'cat_transport', 'name': 'Transportation', 'type': 'expense'},
      {'id': 'cat_shopping', 'name': 'Shopping', 'type': 'expense'},
      {'id': 'cat_entertainment', 'name': 'Entertainment', 'type': 'expense'},
      {'id': 'cat_bills', 'name': 'Bills & Utilities', 'type': 'expense'},
      {'id': 'cat_healthcare', 'name': 'Healthcare', 'type': 'expense'},
      {'id': 'cat_other_expense', 'name': 'Other', 'type': 'expense'},
    ];

    final now = DateTime.now().toIso8601String();
    for (var category in defaultCategories) {
      await db.insert('categories', {
        'id': category['id'],
        'name': category['name'],
        'type': category['type'],
        'created_at': now,
        'updated_at': now,
      });
    }
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
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
