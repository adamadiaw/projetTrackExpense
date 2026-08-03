import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projet_track_expense/domain/entities/transaction.dart';
import 'package:projet_track_expense/presentation/providers/transaction_provider.dart';
import 'package:intl/intl.dart';

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionAsync = ref.watch(transactionListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toutes les transactions'),
      ),
      body: transactionAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(child: Text('Aucune transaction enregistrée'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final t = transactions[index];
              final color = t.type == TransactionType.expense ? Colors.red : Colors.green;
              final sign = t.type == TransactionType.expense ? '-' : '+';
              final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€', decimalDigits: 2);
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Icon(t.type == TransactionType.expense ? Icons.arrow_downward : Icons.arrow_upward, color: color),
                ),
                title: Text(t.description),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(t.date)),
                trailing: Text(
                  '$sign${formatter.format(t.amount)}',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur : $err')),
      ),
    );
  }
}