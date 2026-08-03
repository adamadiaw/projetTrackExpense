import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projet_track_expense/domain/entities/category.dart';
import 'package:projet_track_expense/presentation/providers/repository_providers.dart';

final categoryListProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return await repo.getAllCategories();
});

final expenseCategoryListProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return await repo.getCategoriesByType(CategoryType.expense);
});

final incomeCategoryListProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return await repo.getCategoriesByType(CategoryType.income);
});