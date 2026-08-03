import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projet_track_expense/presentation/providers/category_provider.dart';
import 'package:projet_track_expense/presentation/providers/budget_provider.dart';
import 'package:projet_track_expense/domain/entities/category.dart';
import 'package:projet_track_expense/domain/entities/budget.dart';
import 'package:projet_track_expense/core/constants/app_colors.dart';
import 'package:projet_track_expense/core/constants/app_config.dart';
import 'package:projet_track_expense/core/styles/app_styles.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  Category? _selectedCategory;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _saveBudget() async {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      final amount = double.tryParse(_amountController.text) ?? 0;
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final budget = Budget(
        categoryId: _selectedCategory!.id!,
        amount: amount,
        periodStart: startOfMonth,
        periodEnd: endOfMonth,
      );

      try {
        await ref.read(addBudgetProvider(budget).future);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Budget enregistré !')),
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

  void _openAddBudgetDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Définir un budget'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Consumer(
                builder: (context, ref, child) {
                  final categoryAsync = ref.watch(expenseCategoryListProvider);
                  return categoryAsync.when(
                    data: (categories) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<Category>(
                            decoration: AppStyles.inputDecoration(context, 'Catégorie'), // 👈 Passage du context
                            value: _selectedCategory,
                            items: categories.map((cat) {
                              return DropdownMenuItem(
                                value: cat,
                                child: Text(cat.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                            validator: (value) => value == null ? 'Choisissez une catégorie' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _amountController,
                            decoration: AppStyles.inputDecoration(context, 'Montant max (${AppConfig.currencySymbol})'), // 👈 Passage du context
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Montant requis';
                              final amount = double.tryParse(value);
                              if (amount == null || amount <= 0) return 'Montant invalide';
                              return null;
                            },
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('Erreur de chargement des catégories')),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: _saveBudget,
              style: AppStyles.primaryButton,
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgetAsync = ref.watch(budgetListProvider);
    final categoryAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
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
            onPressed: _openAddBudgetDialog,
          ),
        ],
      ),
      body: budgetAsync.when(
        data: (budgets) {
          return categoryAsync.when(
            data: (categories) {
              if (budgets.isEmpty) {
                return const Center(child: Text('Aucun budget défini. Cliquez sur + pour en ajouter.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: budgets.length,
                itemBuilder: (context, index) {
                  final budget = budgets[index];
                  final category = categories.firstWhere(
                    (c) => c.id == budget.categoryId,
                    orElse: () => Category(
                      id: -1,
                      name: 'Inconnue',
                      icon: '',
                      color: '#000000',
                      type: CategoryType.expense,
                    ),
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    // 👇 Fond adapté au thème
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.transparent
                              : Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: budget.amount > 0 ? (budget.spent / budget.amount).clamp(0, 1) : 0,
                          backgroundColor: Colors.grey.shade200,
                          color: budget.isOverBudget
                              ? Colors.red
                              : (budget.isNearLimit ? Colors.orange : Colors.green),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${budget.spent.toStringAsFixed(2)}${AppConfig.currencySymbol} / ${budget.amount.toStringAsFixed(2)}${AppConfig.currencySymbol}',
                            ),
                            Text(
                              '${budget.remaining.toStringAsFixed(2)}${AppConfig.currencySymbol} restants',
                              style: TextStyle(
                                color: budget.isOverBudget
                                    ? Colors.red
                                    : (budget.isNearLimit ? Colors.orange : Colors.green),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Erreur catégories : $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur budgets : $error')),
      ),
    );
  }
}