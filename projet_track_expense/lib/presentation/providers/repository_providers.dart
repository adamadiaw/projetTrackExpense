import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projet_track_expense/core/utils/encryption_helper.dart';
import 'package:projet_track_expense/data/database/app_database.dart';
// import 'package:projet_track_expense/data/database/app_database.dart';
// import 'package:projet_track_expense/core/utils/encryption_helper.dart';
import 'package:projet_track_expense/data/repositories/impl/transaction_repository_impl.dart';
import 'package:projet_track_expense/data/repositories/impl/category_repository_impl.dart';
import 'package:projet_track_expense/domain/usecases/add_transaction_usecase.dart';

// 1. Provider pour la base de données
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// 2. Provider pour le helper de chiffrement
final encryptionHelperProvider = Provider<EncryptionHelper>((ref) {
  return EncryptionHelper();
});

// 3. Provider pour le Repository des Transactions
final transactionRepositoryProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  final encryption = ref.watch(encryptionHelperProvider);
  return TransactionRepositoryImpl(
    database: db,
    encryptionHelper: encryption,
  );
});

// 4. Provider pour le Repository des Catégories
final categoryRepositoryProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return CategoryRepositoryImpl(database: db);
});

// 5. Provider pour l'Use Case d'ajout de transaction
final addTransactionUseCaseProvider = Provider((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return AddTransactionUseCase(repo);
});