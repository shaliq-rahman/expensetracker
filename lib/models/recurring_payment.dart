import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/models/category.dart';

class RecurringPayment {
  final String id;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime date; // Start date
  final int remainingTenure; // in months
  final DateTime? lastPaymentDate;
  final DateTime paymentDate; // The recurring date (e.g., 5th of every month)

  RecurringPayment({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.remainingTenure,
    this.lastPaymentDate,
    required this.paymentDate,
  });

  bool get isCurrentMonthCleared {
    if (lastPaymentDate == null) return false;
    final now = DateTime.now();
    return lastPaymentDate!.year == now.year && lastPaymentDate!.month == now.month;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category.index, // Storing index for simplicity, or name
      'date': Timestamp.fromDate(date),
      'remainingTenure': remainingTenure,
      'lastPaymentDate': lastPaymentDate != null ? Timestamp.fromDate(lastPaymentDate!) : null,
      'paymentDate': Timestamp.fromDate(paymentDate),
    };
  }

  factory RecurringPayment.fromMap(Map<String, dynamic> map) {
    return RecurringPayment(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      category: ExpenseCategory.values[map['category'] ?? 0],
      date: (map['date'] as Timestamp).toDate(),
      remainingTenure: map['remainingTenure'] ?? 0,
      lastPaymentDate: map['lastPaymentDate'] != null ? (map['lastPaymentDate'] as Timestamp).toDate() : null,
      paymentDate: (map['paymentDate'] as Timestamp).toDate(),
    );
  }
}
