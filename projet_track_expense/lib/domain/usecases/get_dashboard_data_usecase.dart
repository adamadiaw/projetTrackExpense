import 'package:projet_track_expense/domain/entities/transaction.dart';
import 'package:projet_track_expense/domain/repositories/transaction_repository.dart';

class DashboardData {
  final double balance;
  final double totalIncome;
  final double totalExpenses;
  final double dailyExpenses;
  final List<Transaction> recentTransactions;

  DashboardData({
    required this.balance,
    required this.totalIncome,
    required this.totalExpenses,
    required this.dailyExpenses,
    required this.recentTransactions,
  });
}

class GetDashboardDataUseCase {
  final TransactionRepository _repository;

  GetDashboardDataUseCase(this._repository);

  Future<DashboardData> call() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    // Date de début de mois (pour le bilan mensuel)
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    // On exécute les requêtes en parallèle pour être plus rapide
    final results = await Future.wait([
      // 1. Le solde du mois en cours
      _repository.getBalance(startOfMonth, endOfMonth),
      
      // 2. Revenus du mois
      _repository.getBalance(startOfMonth, endOfMonth), // Simulé pour l'exemple, normalement il faudrait séparer revenus/dépenses
      
      // 3. Dépenses du mois (on utilise le solde inversé pour l'exemple)
      _repository.getBalance(startOfMonth, endOfMonth), // Simulé
      
      // 4. Dépenses du jour
      _repository.getBalance(startOfDay, endOfDay), // Simulé (normalement getTotalExpenses)
      
      // 5. Les 3 dernières transactions
      _repository.getAllTransactions(),
    ]);

    // On traite les résultats
    final balance = results[0] as double;
    final recentTransactions = results[4] as List<Transaction>;
    
    // On ne garde que les 3 plus récentes
    final sortedRecent = recentTransactions..sort((a, b) => b.date.compareTo(a.date));
    final top3 = sortedRecent.take(3).toList();

    return DashboardData(
      balance: balance,
      totalIncome: 0, // À calculer plus tard avec une méthode dédiée
      totalExpenses: 0, // À calculer plus tard avec une méthode dédiée
      dailyExpenses: 0, // À calculer plus tard avec une méthode dédiée
      recentTransactions: top3,
    );
  }
}