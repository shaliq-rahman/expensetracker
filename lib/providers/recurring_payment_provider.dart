import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/models/recurring_payment.dart';

class RecurringPaymentProvider with ChangeNotifier {
  List<RecurringPayment> _payments = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription? _subscription;

  List<RecurringPayment> get payments => _payments;

  void fetchPayments() {
    final user = _auth.currentUser;
    if (user == null) {
      _payments = [];
      notifyListeners();
      return;
    }

    _subscription?.cancel();
    _subscription = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('recurring_payments')
        .snapshots()
        .listen((snapshot) {
      _payments = snapshot.docs.map((doc) {
        return RecurringPayment.fromMap(doc.data());
      }).toList();
      notifyListeners();
    });
  }

  Future<void> addPayment(RecurringPayment payment) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('recurring_payments')
          .doc(payment.id)
          .set(payment.toMap());
    } catch (e) {
      print('Error adding recurring payment: $e');
      rethrow;
    }
  }

  Future<void> updatePayment(RecurringPayment payment) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('recurring_payments')
          .doc(payment.id)
          .update(payment.toMap());
    } catch (e) {
      print('Error updating recurring payment: $e');
      rethrow;
    }
  }

  Future<void> deletePayment(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('recurring_payments')
          .doc(id)
          .delete();
    } catch (e) {
      print('Error deleting recurring payment: $e');
      rethrow;
    }
  }
  
  Future<void> toggleCurrentMonthCleared(String id, bool isCleared) async {
      final user = _auth.currentUser;
      if (user == null) return;
      
      try {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('recurring_payments')
              .doc(id)
              .update({
                  'lastPaymentDate': isCleared ? Timestamp.fromDate(DateTime.now()) : null
              });
      } catch (e) {
         print('Error toggling payment cleared status: $e');
         rethrow;
      }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
