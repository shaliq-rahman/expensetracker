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
}
