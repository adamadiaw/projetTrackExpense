import '../../domain/entities/transaction.dart';
import '../../domain/entities/category.dart';

abstract class TransactionRepository {
  // Récupérer toutes les transactions
  Future<List<Transaction>> getAllTransactions();

  // Récupérer les transactions entre deux dates
  Future<List<Transaction>> getTransactionsByDate(DateTime start, DateTime end);

  // Ajouter une transaction
  Future<void> addTransaction(Transaction transaction);

  // Modifier une transaction
  Future<void> updateTransaction(Transaction transaction);

  // Supprimer une transaction
  Future<void> deleteTransaction(int id);

  // Obtenir le solde total (Revenus - Dépenses) sur une période
  Future<double> getBalance(DateTime start, DateTime end);

  // Obtenir le total des dépenses groupées par catégorie
  Future<Map<Category, double>> getExpensesByCategory(DateTime start, DateTime end);
}