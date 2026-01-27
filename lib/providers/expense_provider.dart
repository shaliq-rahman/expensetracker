import 'package:flutter/material.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/category.dart';

class ExpenseProvider with ChangeNotifier {
  final List<Transaction> _transactions = [];

  List<Transaction> get transactions => _transactions;

  double get totalBalance {
    double income = 0;
    double expense = 0;
    for (var tx in _transactions) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }
    return income - expense;
  }

  double get totalIncome {
    return _transactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalExpense {
    return _transactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  Map<ExpenseCategory, double> get categoryTotals {
    final Map<ExpenseCategory, double> totals = {};
    for (var tx in _transactions) {
      if (tx.type == TransactionType.expense) {
        if (!totals.containsKey(tx.category)) {
          totals[tx.category] = 0;
        }
        totals[tx.category] = totals[tx.category]! + tx.amount;
      }
    }
    return totals;
  }

  // Helper to filter transactions
  List<Transaction> getFilteredTransactions(String filterType, DateTime selectedDate) {
    return _transactions.where((tx) {
      if (filterType == 'Day') {
        return tx.date.year == selectedDate.year &&
            tx.date.month == selectedDate.month &&
            tx.date.day == selectedDate.day;
      } else if (filterType == 'Month') {
        return tx.date.year == selectedDate.year &&
            tx.date.month == selectedDate.month;
      } else if (filterType == 'Year') {
        return tx.date.year == selectedDate.year;
      }
      return true;
    }).toList();
  }

  double getPeriodIncome(String filterType, DateTime selectedDate) {
    return getFilteredTransactions(filterType, selectedDate)
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double getPeriodExpense(String filterType, DateTime selectedDate) {
    return getFilteredTransactions(filterType, selectedDate)
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double getPeriodBalance(String filterType, DateTime selectedDate) {
    double income = getPeriodIncome(filterType, selectedDate);
    double expense = getPeriodExpense(filterType, selectedDate);
    return income - expense;
  }

  void addTransaction(Transaction tx) {
    _transactions.add(tx);
    notifyListeners();
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((tx) => tx.id == id);
    notifyListeners();
  }
}
