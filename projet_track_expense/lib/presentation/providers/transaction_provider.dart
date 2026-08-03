import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projet_track_expense/domain/entities/transaction.dart';
// import 'package:projet_track_expense/domain/usecases/add_transaction_usecase.dart';
import 'package:projet_track_expense/presentation/providers/repository_providers.dart';
import 'package:projet_track_expense/presentation/providers/budget_provider.dart'; 

// 1. Provider pour charger la liste des transactions (FutureProvider)
final transactionListProvider = FutureProvider<List<Transaction>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return await repo.getAllTransactions();
});

// 2. Provider pour obtenir le solde actuel
final balanceProvider = FutureProvider<double>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0);
  return await repo.getBalance(startOfMonth, endOfMonth);
});

// 3. Le Notifier moderne
class TransactionNotifier extends Notifier<List<Transaction>> {
  
  @override
  List<Transaction> build() {
    loadTransactions();
    return [];
  }

  Future<void> loadTransactions() async {
    final repo = ref.read(transactionRepositoryProvider);
    final transactions = await repo.getAllTransactions();
    state = transactions;
  }

  Future<void> addTransaction(Transaction transaction) async {
    final useCase = ref.read(addTransactionUseCaseProvider);
    try {
      await useCase(transaction);
      
      // Invalidation des caches pour forcer le rafraîchissement de l'UI
      ref.invalidate(transactionListProvider); 
      ref.invalidate(balanceProvider);
      ref.invalidate(budgetListProvider);
      
      // Mise à jour de l'état interne
      await loadTransactions();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTransaction(int id) async {
    final repo = ref.read(transactionRepositoryProvider);
    await repo.deleteTransaction(id);
    
    ref.invalidate(transactionListProvider);
    ref.invalidate(balanceProvider);
    ref.invalidate(budgetListProvider); // 🔥 Aussi ici pour la suppression
    await loadTransactions();
  }
}

// 4. Provider pour le Notifier
final transactionNotifierProvider = NotifierProvider<TransactionNotifier, List<Transaction>>(() {
  return TransactionNotifier();
});