import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projet_track_expense/core/constants/app_colors.dart';
import 'package:projet_track_expense/domain/entities/transaction.dart';
import 'package:projet_track_expense/presentation/providers/theme_provider.dart';
import 'package:projet_track_expense/presentation/screens/add_transaction_screen.dart';
import 'package:projet_track_expense/presentation/providers/transaction_provider.dart';
import 'package:projet_track_expense/presentation/screens/category_management_screen.dart';
import 'package:projet_track_expense/presentation/screens/transaction_list_screen.dart';
import 'package:projet_track_expense/presentation/screens/budget_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final transactionAsync = ref.watch(transactionListProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          // Bouton Catégories
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CategoryManagementScreen()),
              );
            },
          ),
          // Bouton Budgets
          IconButton(
            icon: const Icon(Icons.account_balance),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const BudgetScreen()),
              );
            },
          ),
          // Thème
          Consumer(
            builder: (context, ref, child) {
              return IconButton(
                icon: const Icon(Icons.brightness_6),
                onPressed: () {
                  ref.read(themeProvider.notifier).toggleTheme();
                },
              );
            },
          ),
          // Déconnexion
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Logique de déconnexion plus tard
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte du solde
            transactionAsync.when(
              data: (transactions) => _buildBalanceCard(context, transactions),
              loading: () => _buildShimmerCard(),
              error: (err, stack) => Text('Erreur solde : $err'),
            ),

            const SizedBox(height: 20),
            
            // Stats rapides
            transactionAsync.when(
              data: (transactions) => _buildQuickStats(context, transactions),
              loading: () => _buildShimmerStats(),
              error: (err, stack) => Text('Erreur stats : $err'),
            ),
            
            const SizedBox(height: 20),
            
            // Graphique Camembert
            _buildChartSection(context, transactionAsync),
            
            const SizedBox(height: 20),
            
            // Liste des dernières transactions
            _buildRecentTransactionsHeader(context),
            const SizedBox(height: 10),
            transactionAsync.when(
              data: (transactions) {
                final recent = transactions.take(3).toList();
                if (recent.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(child: Text('Aucune transaction enregistrée')),
                  );
                }
                return Column(
                  children: recent.map((t) => _buildTransactionItem(context, t)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Erreur transactions : $err'),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- CALCULS DYNAMIQUES ---

  double _calculateBalance(List<Transaction> transactions) {
    double totalIncome = 0;
    double totalExpenses = 0;
    for (final t in transactions) {
      if (t.type == TransactionType.income) {
        totalIncome += t.amount;
      } else {
        totalExpenses += t.amount;
      }
    }
    return totalIncome - totalExpenses;
  }

  double _calculateTotalIncome(List<Transaction> transactions) {
    return transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, item) => sum + item.amount);
  }

  double _calculateTotalExpenses(List<Transaction> transactions) {
    return transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, item) => sum + item.amount);
  }

  // --- WIDGETS ---

  Widget _buildBalanceCard(BuildContext context, List<Transaction> transactions) {
    final balance = _calculateBalance(transactions);
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€', decimalDigits: 2);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Solde total', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              formatter.format(balance),
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        height: 100,
        padding: const EdgeInsets.all(20.0),
        color: Colors.grey.shade300,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, List<Transaction> transactions) {
    final income = _calculateTotalIncome(transactions);
    final expenses = _calculateTotalExpenses(transactions);
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€', decimalDigits: 2);
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            title: 'Dépenses',
            amount: formatter.format(expenses),
            color: Colors.red,
            icon: Icons.arrow_downward,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            title: 'Revenus',
            amount: formatter.format(income),
            color: Colors.green,
            icon: Icons.arrow_upward,
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerStats() {
    return Row(
      children: [
        Expanded(child: Container(height: 80, color: Colors.grey.shade300)),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 80, color: Colors.grey.shade300)),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, {required String title, required String amount, required Color color, required IconData icon}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                Icon(icon, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(amount, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(BuildContext context, AsyncValue<List<Transaction>> transactionAsync) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dépenses par catégorie', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: transactionAsync.when(
                data: (transactions) {
                  // On filtre uniquement les dépenses
                  final expenses = transactions.where((t) => t.type == TransactionType.expense).toList();
                  
                  if (expenses.isEmpty) {
                    return const Center(child: Text('Aucune dépense enregistrée'));
                  }

                  // On regroupe les montants par categoryId
                  final Map<int, double> categoryTotals = {};
                  for (final t in expenses) {
                    categoryTotals[t.categoryId] = (categoryTotals[t.categoryId] ?? 0) + t.amount;
                  }

                  // ✅ CORRECTION : Liste de couleurs fixes pour un beau camembert
                  final List<Color> palette = [
                    Colors.red, Colors.blue, Colors.green, Colors.orange, 
                    Colors.purple, Colors.teal, Colors.pink, Colors.indigo
                  ];

                  int colorIndex = 0;
                  final sections = categoryTotals.entries.map((entry) {
                    final color = palette[colorIndex % palette.length];
                    colorIndex++;
                    return PieChartSectionData(
                      color: color,
                      value: entry.value,
                      title: '${entry.value.toStringAsFixed(0)}€',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList();

                  return PieChart(
                    PieChartData(
                      sections: sections,
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Erreur graphique : $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Dernières transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const TransactionListScreen()),
            );
          },
          child: const Text('Voir tout'),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(BuildContext context, Transaction t) {
    final color = t.type == TransactionType.expense ? Colors.red : Colors.green;
    final sign = t.type == TransactionType.expense ? '-' : '+';
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€', decimalDigits: 2);
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(t.type == TransactionType.expense ? Icons.arrow_downward : Icons.arrow_upward, color: color),
      ),
      title: Text(t.description, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(DateFormat('dd/MM/yyyy').format(t.date), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      trailing: Text(
        '$sign${formatter.format(t.amount)}',
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}