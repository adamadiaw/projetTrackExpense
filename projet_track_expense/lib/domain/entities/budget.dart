import 'package:equatable/equatable.dart';

class Budget extends Equatable {
  final int? id;
  final int categoryId;
  final double amount;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double spent;

  const Budget({
    this.id,
    required this.categoryId,
    required this.amount,
    required this.periodStart,
    required this.periodEnd,
    this.spent = 0.0,
  });

  Budget copyWith({int? id, int? categoryId, double? amount, DateTime? periodStart, DateTime? periodEnd, double? spent}) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      spent: spent ?? this.spent,
    );
  }

  double get remaining => amount - spent;
  double get percentageUsed => amount == 0 ? 0 : (spent / amount) * 100;
  bool get isOverBudget => spent > amount;
  bool get isNearLimit => percentageUsed >= 80.0;

  @override
  List<Object?> get props => [id, categoryId, amount, periodStart, periodEnd, spent];
}