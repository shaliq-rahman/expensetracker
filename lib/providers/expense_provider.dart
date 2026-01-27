import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/category.dart';

class ExpenseProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription? _subscription;

  List<Transaction> get transactions => _transactions;

  // Start listening to real-time updates
  void fetchTransactions() {
    final user = _auth.currentUser;
    if (user == null) {
      _transactions = [];
      notifyListeners();
      return;
    }

    _subscription?.cancel();
    _subscription = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
      _transactions = snapshot.docs.map((doc) {
        return Transaction.fromMap(doc.data());
      }).toList();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

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

  Future<void> addTransaction(Transaction tx) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(tx.id)
          .set(tx.toMap());
      
      await FirebaseAnalytics.instance.logEvent(
        name: 'add_transaction',
        parameters: {
          'amount': tx.amount,
          'category': tx.category.name,
          'type': tx.type.name,
        },
      );
      // Local update is handled by stream listener
    } catch (e) {
      print('Error adding transaction: $e');
      rethrow;
    }
  }

  Future<void> deleteTransaction(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(id)
          .delete();

      await FirebaseAnalytics.instance.logEvent(
        name: 'delete_transaction',
      );
      // Local update is handled by stream listener
    } catch (e) {
      print('Error deleting transaction: $e');
      rethrow;
    }
  }
}
