import 'package:projet_track_expense/domain/repositories/category_repository.dart';
import 'package:projet_track_expense/domain/entities/category.dart';
import 'package:projet_track_expense/data/database/app_database.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final AppDatabase _database;

  CategoryRepositoryImpl({required AppDatabase database}) : _database = database;

  // Helper pour convertir un Map SQL en objet Category
  Category _mapToCategory(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String,
      color: map['color'] as String,
      type: CategoryType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CategoryType.expense,
      ),
      isDefault: (map['isDefault'] as int?) == 1,
    );
  }

  // Helper pour convertir une Category en Map SQL
  Map<String, dynamic> _categoryToMap(Category category) {
    return {
      'name': category.name,
      'icon': category.icon,
      'color': category.color,
      'type': category.type.name,
      'isDefault': category.isDefault ? 1 : 0,
    };
  }

  @override
  Future<List<Category>> getAllCategories() async {
    final maps = await _database.getAllCategories();
    return maps.map((map) => _mapToCategory(map)).toList();
  }

  @override
  Future<List<Category>> getCategoriesByType(CategoryType type) async {
    final db = await _database.database; // On récupère la connexion directe à la base de données
    final maps = await db.rawQuery(
      'SELECT * FROM categories WHERE type = ?',
      [type.name]
    );
    return maps.map((map) => _mapToCategory(map)).toList();
  }

  @override
  Future<void> addCategory(Category category) async {
    final map = _categoryToMap(category);
    await _database.insertCategory(map);
  }

  @override
  Future<void> deleteCategory(int id) async {
    await _database.deleteCategory(id);
  }
}