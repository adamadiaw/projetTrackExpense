import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static Database? _database;

  // Singleton pour éviter d'ouvrir plusieurs connexions
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialisation et création des tables
  Future<Database> _initDatabase() async {
    final documentsPath = await getDatabasesPath();
    final path = join(documentsPath, 'projettrackexpense.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        // 1. Table des Catégories
        await db.execute('''
          CREATE TABLE categories(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            icon TEXT NOT NULL,
            color TEXT NOT NULL,
            type TEXT NOT NULL,
            isDefault INTEGER DEFAULT 0
          )
        ''');

        // 2. Table des Transactions (avec clé étrangère)
        await db.execute('''
          CREATE TABLE transactions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount REAL NOT NULL,
            categoryId INTEGER NOT NULL,
            description TEXT NOT NULL,
            date TEXT NOT NULL,
            type TEXT NOT NULL,
            isRecurring INTEGER DEFAULT 0,
            recurringInterval TEXT,
            createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
            updatedAt TEXT,
            FOREIGN KEY(categoryId) REFERENCES categories(id) ON DELETE CASCADE
          )
        ''');

        // 3. Table des Budgets (avec clé étrangère)
        await db.execute('''
          CREATE TABLE budgets(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            categoryId INTEGER NOT NULL,
            amount REAL NOT NULL,
            periodStart TEXT NOT NULL,
            periodEnd TEXT NOT NULL,
            spent REAL DEFAULT 0,
            FOREIGN KEY(categoryId) REFERENCES categories(id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  // ==========================================
  // REQUÊTES CRUD (CATÉGORIES)
  // ==========================================
  
  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final db = await database;
    return await db.query('categories');
  }

  Future<int> insertCategory(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('categories', data);
  }

  Future<int> updateCategory(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update('categories', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // REQUÊTES CRUD (TRANSACTIONS)
  // ==========================================

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await database;
    return await db.query('transactions', orderBy: 'date DESC');
  }

  Future<List<Map<String, dynamic>>> getTransactionsByDate(String start, String end) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT * FROM transactions 
      WHERE date BETWEEN ? AND ?
      ORDER BY date DESC
    ''', [start, end]);
  }

  Future<List<Map<String, dynamic>>> getRecentTransactions({int limit = 3}) async {
    final db = await database;
    return await db.query('transactions', orderBy: 'date DESC', limit: limit);
  }

  Future<int> insertTransaction(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('transactions', data);
  }

  Future<int> updateTransaction(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update('transactions', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // STATISTIQUES FINANCIÈRES
  // ==========================================

  Future<double> getTotalIncome(String start, String end) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total 
      FROM transactions 
      WHERE type = 'income' AND date BETWEEN ? AND ?
    ''', [start, end]);
    return result.first['total'] as double? ?? 0.0;
  }

  Future<double> getTotalExpenses(String start, String end) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total 
      FROM transactions 
      WHERE type = 'expense' AND date BETWEEN ? AND ?
    ''', [start, end]);
    return result.first['total'] as double? ?? 0.0;
  }

  // ==========================================
  // REQUÊTES CRUD (BUDGETS)
  // ==========================================

  Future<List<Map<String, dynamic>>> getAllBudgets() async {
    final db = await database;
    return await db.query('budgets');
  }

  Future<int> insertBudget(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('budgets', data);
  }

  // MÉTHODE AJOUTÉE POUR METTRE À JOUR LE SPENT
  Future<void> updateBudgetSpentByCategory(int categoryId, double newTotalSpent) async {
    final db = await database;
    await db.update(
      'budgets',
      {'spent': newTotalSpent},
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );
  }
}