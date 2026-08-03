import 'package:projet_track_expense/domain/repositories/transaction_repository.dart';
import 'package:projet_track_expense/domain/entities/transaction.dart';
import 'package:projet_track_expense/domain/entities/category.dart';
import 'package:projet_track_expense/data/database/app_database.dart';
import 'package:projet_track_expense/core/utils/encryption_helper.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final AppDatabase _database;

  TransactionRepositoryImpl({
    required AppDatabase database,
    required EncryptionHelper encryptionHelper,
  }) : _database = database;

  Transaction _mapToTransaction(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      amount: map['amount'] as double,
      categoryId: map['categoryId'] as int,
      description: map['description'] as String,
      date: DateTime.parse(map['date'] as String),
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      isRecurring: (map['isRecurring'] as int?) == 1,
      recurringInterval: map['recurringInterval'] as String?,
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> _transactionToMap(Transaction t) {
    return {
      if (t.id != null) 'id': t.id,
      'amount': t.amount,
      'categoryId': t.categoryId,
      'description': t.description,
      'date': t.date.toIso8601String(),
      'type': t.type.name,
      'isRecurring': t.isRecurring ? 1 : 0,
      'recurringInterval': t.recurringInterval,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<List<Transaction>> getAllTransactions() async {
    final maps = await _database.getAllTransactions();
    return maps.map((map) => _mapToTransaction(map)).toList();
  }

  @override
  Future<List<Transaction>> getTransactionsByDate(DateTime start, DateTime end) async {
    final maps = await _database.getTransactionsByDate(
      start.toIso8601String(),
      end.toIso8601String(),
    );
    return maps.map((map) => _mapToTransaction(map)).toList();
  }

  @override
  Future<void> addTransaction(Transaction transaction) async {
    final map = _transactionToMap(transaction);
    await _database.insertTransaction(map);

    // 1. Calculer les dépenses pour ce mois et cette catégorie
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final transactionsThisMonth = await _database.getTransactionsByDate(
      startOfMonth.toIso8601String(),
      endOfMonth.toIso8601String(),
    );

    final expensesForCategory = transactionsThisMonth
        .where((t) => t['categoryId'] == transaction.categoryId && t['type'] == 'expense')
        .fold<double>(0.0, (sum, item) => sum + (item['amount'] as double));

    // 2. Mettre à jour la colonne 'spent' dans la table budgets
    await _database.updateBudgetSpentByCategory(transaction.categoryId, expensesForCategory);
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    final map = _transactionToMap(transaction);
    await _database.updateTransaction(transaction.id!, map);
  }

  @override
  Future<void> deleteTransaction(int id) async {
    await _database.deleteTransaction(id);
  }

  @override
  Future<double> getBalance(DateTime start, DateTime end) async {
    final income = await _database.getTotalIncome(
      start.toIso8601String(),
      end.toIso8601String(),
    );
    final expenses = await _database.getTotalExpenses(
      start.toIso8601String(),
      end.toIso8601String(),
    );
    return income - expenses;
  }

  @override
  Future<Map<Category, double>> getExpensesByCategory(DateTime start, DateTime end) async {
    return {};
  }
}