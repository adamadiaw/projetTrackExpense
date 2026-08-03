import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projet_track_expense/presentation/providers/repository_providers.dart';
import 'package:projet_track_expense/domain/entities/budget.dart';
// import 'package:projet_track_expense/data/database/app_database.dart';

final budgetListProvider = FutureProvider<List<Budget>>((ref) async {
  final db = ref.watch(databaseProvider);
  final maps = await db.getAllBudgets();
  return maps.map((map) => Budget(
    id: map['id'] as int?,
    categoryId: map['categoryId'] as int,
    amount: map['amount'] as double,
    periodStart: DateTime.parse(map['periodStart'] as String),
    periodEnd: DateTime.parse(map['periodEnd'] as String),
    spent: map['spent'] as double? ?? 0.0,
  )).toList();
});

// Fonction pour ajouter ou mettre à jour un budget
final addBudgetProvider = FutureProvider.family<void, Budget>((ref, budget) async {
  final db = ref.watch(databaseProvider);
  final map = {
    'categoryId': budget.categoryId,
    'amount': budget.amount,
    'periodStart': budget.periodStart.toIso8601String(),
    'periodEnd': budget.periodEnd.toIso8601String(),
    'spent': budget.spent,
  };
  await db.insertBudget(map);
  ref.invalidate(budgetListProvider);
});