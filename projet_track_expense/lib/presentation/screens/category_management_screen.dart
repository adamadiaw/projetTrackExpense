import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projet_track_expense/domain/entities/category.dart';
import 'package:projet_track_expense/presentation/providers/category_provider.dart';
import 'package:projet_track_expense/core/constants/app_colors.dart';
// import 'package:projet_track_expense/core/constants/app_config.dart';
import 'package:projet_track_expense/core/styles/app_styles.dart';
// import 'package:projet_track_expense/data/repositories/impl/category_repository_impl.dart';
import 'package:projet_track_expense/presentation/providers/repository_providers.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends ConsumerState<CategoryManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedIcon = 'Icons.category';
  String _selectedColor = '#1EA6DC';
  CategoryType _selectedType = CategoryType.expense;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    if (_formKey.currentState!.validate()) {
      final newCategory = Category(
        name: _nameController.text.trim(),
        icon: _selectedIcon,
        color: _selectedColor,
        type: _selectedType,
        isDefault: false,
      );

      try {
        final repo = ref.read(categoryRepositoryProvider);
        await repo.addCategory(newCategory);
        
        ref.invalidate(categoryListProvider);
        ref.invalidate(expenseCategoryListProvider);
        ref.invalidate(incomeCategoryListProvider);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Catégorie ajoutée avec succès !')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : ${e.toString()}')),
          );
        }
      }
    }
  }

  void _openAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nouvelle catégorie'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: AppStyles.inputDecoration(context, 'Nom de la catégorie'), // 👈 Passage du context
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le nom est obligatoire';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<CategoryType>(
                    value: _selectedType,
                    decoration: AppStyles.inputDecoration(context, 'Type'), // 👈 Passage du context
                    items: CategoryType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type == CategoryType.expense ? 'Dépense' : 'Revenu'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: _addCategory,
              style: AppStyles.primaryButton,
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des catégories'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openAddCategoryDialog,
          ),
        ],
      ),
      body: categoryAsync.when(
        data: (categories) {
          final expenses = categories.where((c) => c.type == CategoryType.expense).toList();
          final incomes = categories.where((c) => c.type == CategoryType.income).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Dépenses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...expenses.map((cat) => _buildCategoryTile(cat)).toList(),
              const SizedBox(height: 24),
              const Text('Revenus', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...incomes.map((cat) => _buildCategoryTile(cat)).toList(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur : $err')),
      ),
    );
  }

  Widget _buildCategoryTile(Category cat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: Color(int.parse(cat.color.substring(1), radix: 16) + 0xFF000000),
          child: Icon(
            _getIconFromString(cat.icon),
            color: Colors.white,
          ),
        ),
        title: Text(cat.name),
        subtitle: cat.isDefault ? const Text('Par défaut', style: TextStyle(fontSize: 12, color: Colors.grey)) : null,
        trailing: cat.isDefault 
            ? null 
            : IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Supprimer ?'),
                      content: Text('Voulez-vous supprimer la catégorie "${cat.name}" ?'),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
                        TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Oui', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  
                  if (confirm == true) {
                    final repo = ref.read(categoryRepositoryProvider);
                    await repo.deleteCategory(cat.id!);
                    ref.invalidate(categoryListProvider);
                  }
                },
              ),
      ),
    );
  }

  IconData _getIconFromString(String iconName) {
    const iconMap = {
      'Icons.fastfood': Icons.fastfood,
      'Icons.directions_car': Icons.directions_car,
      'Icons.home': Icons.home,
      'Icons.receipt': Icons.receipt,
      'Icons.movie': Icons.movie,
      'Icons.local_hospital': Icons.local_hospital,
      'Icons.monetization_on': Icons.monetization_on,
      'Icons.work': Icons.work,
      'Icons.trending_up': Icons.trending_up,
    };
    return iconMap[iconName] ?? Icons.category;
  }
}