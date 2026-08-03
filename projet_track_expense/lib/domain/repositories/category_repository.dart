import '../../domain/entities/category.dart';

abstract class CategoryRepository {
  // Récupérer toutes les catégories
  Future<List<Category>> getAllCategories();

  // Récupérer les catégories par type (income/expense)
  Future<List<Category>> getCategoriesByType(CategoryType type);

  // Ajouter une catégorie
  Future<void> addCategory(Category category);

  // Supprimer une catégorie
  Future<void> deleteCategory(int id);
}