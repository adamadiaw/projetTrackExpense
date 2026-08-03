import 'package:projet_track_expense/domain/entities/transaction.dart';
import 'package:projet_track_expense/domain/repositories/transaction_repository.dart';

class AddTransactionUseCase {
  final TransactionRepository _repository;

  AddTransactionUseCase(this._repository);

  Future<void> call(Transaction transaction) async {
    // RÈGLE MÉTIER 1 : Le montant doit être supérieur à 0
    if (transaction.amount <= 0) {
      throw ArgumentError('Le montant de la transaction doit être supérieur à 0.');
    }

    // RÈGLE MÉTIER 2 : La description ne peut pas être vide
    if (transaction.description.trim().isEmpty) {
      throw ArgumentError('La description de la transaction est obligatoire.');
    }

    // RÈGLE MÉTIER 3 : La date ne peut pas être dans le futur (optionnel, selon vos besoins)
    if (transaction.date.isAfter(DateTime.now())) {
      throw ArgumentError('La date de la transaction ne peut pas être dans le futur.');
    }

    // Si toutes les règles sont passées, on sauvegarde
    await _repository.addTransaction(transaction);
  }
}