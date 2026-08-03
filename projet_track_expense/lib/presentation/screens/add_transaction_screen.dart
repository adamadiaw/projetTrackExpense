import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projet_track_expense/domain/entities/transaction.dart';
import 'package:projet_track_expense/domain/entities/category.dart';
import 'package:projet_track_expense/presentation/providers/transaction_provider.dart';
import 'package:projet_track_expense/presentation/providers/category_provider.dart';
import 'package:projet_track_expense/core/constants/app_colors.dart';
import 'package:intl/intl.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TransactionType _selectedType = TransactionType.expense;
  Category? _selectedCategory;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      final amount = double.tryParse(_amountController.text) ?? 0;
      final transaction = Transaction(
        amount: amount,
        categoryId: _selectedCategory!.id!,
        description: _descriptionController.text.trim(),
        date: _selectedDate,
        type: _selectedType,
        isRecurring: false,
      );

      try {
        await ref.read(transactionNotifierProvider.notifier).addTransaction(transaction);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : ${e.toString()}')),
          );
        }
      }
    } else if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une catégorie')),
      );
    }
  }

  void _openCategoryPicker() {
    // On stocke le type actuel pour le passer au Consumer
    final currentType = _selectedType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // ✅ SOLUTION DU 1ER COUP : On utilise un Consumer à l'intérieur
      builder: (BuildContext sheetContext) {
        return Consumer(
          builder: (context, ref, child) {
            // On lit le provider ici. Si le chargement dure 0.5s, le Consumer va se mettre à jour.
            final categoryAsyncValue = currentType == TransactionType.expense
                ? ref.watch(expenseCategoryListProvider)
                : ref.watch(incomeCategoryListProvider);

            return categoryAsyncValue.when(
              data: (categories) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  height: 450,
                  child: Column(
                    children: [
                      const Text(
                        'Choisir une catégorie',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.separated(
                          itemCount: categories.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            return ListTile(
                              onTap: () {
                                setState(() {
                                  _selectedCategory = cat;
                                });
                                Navigator.of(sheetContext).pop();
                              },
                              leading: CircleAvatar(
                                backgroundColor: Color(int.parse(cat.color.substring(1), radix: 16) + 0xFF000000),
                                child: Icon(
                                  _getIconFromString(cat.icon),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(cat.name),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Erreur : $error')),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Ajouter une transaction'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Type de transaction
                SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(
                      value: TransactionType.expense,
                      label: Text('Dépense'),
                      icon: Icon(Icons.arrow_downward),
                    ),
                    ButtonSegment(
                      value: TransactionType.income,
                      label: Text('Revenu'),
                      icon: Icon(Icons.arrow_upward),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (Set<TransactionType> newSelection) {
                    setState(() {
                      _selectedType = newSelection.first;
                      _selectedCategory = null;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Montant
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Montant (€)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.euro),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Veuillez saisir un montant';
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Montant invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez saisir une description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date
                InkWell(
                  onTap: () async {
                    FocusScope.of(context).unfocus();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sélecteur de catégorie
                InkWell(
                  onTap: _openCategoryPicker,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Catégorie',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    child: _selectedCategory != null
                        ? Row(
                            children: [
                              Icon(
                                _getIconFromString(_selectedCategory!.icon),
                                color: Color(int.parse(_selectedCategory!.color.substring(1), radix: 16) + 0xFF000000),
                              ),
                              const SizedBox(width: 8),
                              Text(_selectedCategory!.name),
                            ],
                          )
                        : const Text('Sélectionnez une catégorie...'),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Enregistrer'),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
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