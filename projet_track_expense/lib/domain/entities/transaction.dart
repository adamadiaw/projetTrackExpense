import 'package:equatable/equatable.dart';

enum TransactionType { income, expense }

class Transaction extends Equatable {
  final int? id;
  final double amount;
  final int categoryId;
  final String description;
  final DateTime date;
  final TransactionType type;
  final bool isRecurring;
  final String? recurringInterval;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Transaction({
    this.id,
    required this.amount,
    required this.categoryId,
    required this.description,
    required this.date,
    required this.type,
    this.isRecurring = false,
    this.recurringInterval,
    this.createdAt,
    this.updatedAt,
  });

  Transaction copyWith({int? id, double? amount, int? categoryId, String? description, DateTime? date, TransactionType? type, bool? isRecurring, String? recurringInterval, DateTime? createdAt, DateTime? updatedAt}) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      date: date ?? this.date,
      type: type ?? this.type,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringInterval: recurringInterval ?? this.recurringInterval,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, amount, categoryId, description, date, type, isRecurring, recurringInterval, createdAt, updatedAt];
}