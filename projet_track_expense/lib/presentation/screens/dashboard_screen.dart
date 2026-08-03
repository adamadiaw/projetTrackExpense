import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projet_track_expense/core/constants/app_colors.dart';
import 'package:projet_track_expense/core/constants/app_config.dart';
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
    // ignore: unused_local_variable
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 180,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.account_balance_wallet,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'TrackExpense',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Gérez vos finances',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: AppColors.primary),
              title: const Text('Tableau de bord'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance, color: AppColors.primary),
              title: const Text('Gérer les budgets'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const BudgetScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.category, color: AppColors.primary),
              title: const Text('Gérer les catégories'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CategoryManagementScreen()));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Tableau de bord'),
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
          Consumer(
            builder: (context, ref, child) {
              final themeMode = ref.watch(themeProvider);
              // L'icône change selon le mode
              final icon = themeMode == ThemeMode.dark 
                  ? Icons.wb_sunny_outlined 
                  : Icons.nightlight_round;
              
              return IconButton(
                icon: Icon(icon),
                onPressed: () {
                  ref.read(themeProvider.notifier).toggleTheme();
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            transactionAsync.when(
              data: (transactions) => _buildBalanceCard(context, transactions),
              loading: () => _buildShimmerCard(),
              error: (err, stack) => Text('Erreur solde : $err'),
            ),
            const SizedBox(height: 20),
            transactionAsync.when(
              data: (transactions) => _buildQuickStats(context, transactions),
              loading: () => _buildShimmerStats(),
              error: (err, stack) => Text('Erreur stats : $err'),
            ),
            const SizedBox(height: 20),
            _buildChartSection(context, transactionAsync),
            const SizedBox(height: 20),
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
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddTransactionScreen()));
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

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
    return transactions.where((t) => t.type == TransactionType.income).fold(0, (sum, item) => sum + item.amount);
  }

  double _calculateTotalExpenses(List<Transaction> transactions) {
    return transactions.where((t) => t.type == TransactionType.expense).fold(0, (sum, item) => sum + item.amount);
  }

  Widget _buildBalanceCard(BuildContext context, List<Transaction> transactions) {
    final balance = _calculateBalance(transactions);
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: AppConfig.currencySymbol, decimalDigits: 2);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Solde total', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Text(
            formatter.format(balance),
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(24)),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildQuickStats(BuildContext context, List<Transaction> transactions) {
    final income = _calculateTotalIncome(transactions);
    final expenses = _calculateTotalExpenses(transactions);
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: AppConfig.currencySymbol, decimalDigits: 2);
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(context, title: 'Dépenses', amount: formatter.format(expenses), color: Colors.red, icon: Icons.arrow_downward),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(context, title: 'Revenus', amount: formatter.format(income), color: Colors.green, icon: Icons.arrow_upward),
        ),
      ],
    );
  }

  Widget _buildShimmerStats() {
    return Row(
      children: [
        Expanded(child: Container(height: 80, color: Colors.grey.shade200)),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 80, color: Colors.grey.shade200)),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, {required String title, required String amount, required Color color, required IconData icon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16.0),
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
    );
  }

  Widget _buildChartSection(BuildContext context, AsyncValue<List<Transaction>> transactionAsync) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.transparent
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dépenses par catégorie', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: transactionAsync.when(
              data: (transactions) {
                final expenses = transactions.where((t) => t.type == TransactionType.expense).toList();
                if (expenses.isEmpty) return const Center(child: Text('Aucune dépense enregistrée'));

                final Map<int, double> categoryTotals = {};
                for (final t in expenses) {
                  categoryTotals[t.categoryId] = (categoryTotals[t.categoryId] ?? 0) + t.amount;
                }

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
                    title: '${entry.value.toStringAsFixed(0)} ${AppConfig.currencySymbol}',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList();

                return PieChart(PieChartData(sections: sections, sectionsSpace: 2, centerSpaceRadius: 40));
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Erreur graphique : $err')),
            ),
          ),
        ],
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
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const TransactionListScreen()));
          },
          child: const Text('Voir tout'),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(BuildContext context, Transaction t) {
    final color = t.type == TransactionType.expense ? Colors.red : Colors.green;
    final sign = t.type == TransactionType.expense ? '-' : '+';
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: AppConfig.currencySymbol, decimalDigits: 2);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.transparent
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(t.type == TransactionType.expense ? Icons.arrow_downward : Icons.arrow_upward, color: color),
        ),
        title: Text(t.description, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(DateFormat('dd/MM/yyyy').format(t.date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: Text(
          '$sign${formatter.format(t.amount)}',
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}