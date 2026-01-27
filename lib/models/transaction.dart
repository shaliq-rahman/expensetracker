import 'package:uuid/uuid.dart';
import 'package:expense_tracker/models/category.dart';

enum TransactionType { income, expense }

enum PaymentMode { cash, upi, card }

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final TransactionType type;
  final PaymentMode paymentMode;
  final String? note;

  Transaction({
    String? id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
    this.paymentMode = PaymentMode.cash,
    this.note,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category.name, // Storing enum as String name
      'type': type.name, // Storing enum as String name
      'paymentMode': paymentMode.name,
      'note': note,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    // Helper for safe enum parsing
    T getEnum<T>(List<T> values, String? value, T defaultValue) {
      if (value == null) return defaultValue;
      return values.firstWhere(
        (e) => e.toString().split('.').last.toUpperCase() == value.toUpperCase(),
        orElse: () => defaultValue,
      );
    }

    print("Parsing Transaction: ${map['title']} - Cat: ${map['category']}");

    return Transaction(
      id: map['id'],
      title: map['title'] ?? 'Unknown',
      amount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : 0.0,
      date: DateTime.tryParse(map['date'].toString()) ?? DateTime.now(),
      category: getEnum(ExpenseCategory.values, map['category']?.toString(), ExpenseCategory.other),
      type: getEnum(TransactionType.values, map['type']?.toString(), TransactionType.expense),
      paymentMode: getEnum(PaymentMode.values, map['paymentMode']?.toString(), PaymentMode.cash),
      note: map['note'],
    );
  }
}
