import 'package:projet_track_expense/domain/entities/category.dart';
import 'package:projet_track_expense/domain/repositories/category_repository.dart';

class CategorySeeder {
  static Future<void> seedCategories(CategoryRepository repository) async {
    // Vérifier si des catégories existent déjà
    final existing = await repository.getAllCategories();
    if (existing.isNotEmpty) {
      // Si déjà des catégories, on ne fait rien
      return;
    }

    // Liste des catégories par défaut (Dépenses)
    final expenseCategories = [
      Category(
        name: 'Alimentation',
        icon: 'Icons.fastfood',
        color: '#FF5733',
        type: CategoryType.expense,
        isDefault: true,
      ),
      Category(
        name: 'Transport',
        icon: 'Icons.directions_car',
        color: '#33A1FF',
        type: CategoryType.expense,
        isDefault: true,
      ),
      Category(
        name: 'Logement',
        icon: 'Icons.home',
        color: '#8E44AD',
        type: CategoryType.expense,
        isDefault: true,
      ),
      Category(
        name: 'Factures',
        icon: 'Icons.receipt',
        color: '#F39C12',
        type: CategoryType.expense,
        isDefault: true,
      ),
      Category(
        name: 'Loisirs',
        icon: 'Icons.movie',
        color: '#1ABC9C',
        type: CategoryType.expense,
        isDefault: true,
      ),
      Category(
        name: 'Santé',
        icon: 'Icons.local_hospital',
        color: '#E74C3C',
        type: CategoryType.expense,
        isDefault: true,
      ),
    ];

    // Liste des catégories par défaut (Revenus)
    final incomeCategories = [
      Category(
        name: 'Salaire',
        icon: 'Icons.monetization_on',
        color: '#2ECC71',
        type: CategoryType.income,
        isDefault: true,
      ),
      Category(
        name: 'Freelance',
        icon: 'Icons.work',
        color: '#3498DB',
        type: CategoryType.income,
        isDefault: true,
      ),
      Category(
        name: 'Investissements',
        icon: 'Icons.trending_up',
        color: '#9B59B6',
        type: CategoryType.income,
        isDefault: true,
      ),
    ];

    // Insertion en base
    for (final cat in expenseCategories) {
      await repository.addCategory(cat);
    }
    for (final cat in incomeCategories) {
      await repository.addCategory(cat);
    }
  }
}