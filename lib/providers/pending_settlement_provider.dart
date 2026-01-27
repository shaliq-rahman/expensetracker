import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/models/pending_settlement.dart';

class PendingSettlementProvider with ChangeNotifier {
  List<PendingSettlement> _settlements = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription? _subscription;

  List<PendingSettlement> get settlements => _settlements;

  void fetchSettlements() {
    final user = _auth.currentUser;
    if (user == null) {
      _settlements = [];
      notifyListeners();
      return;
    }

    _subscription?.cancel();
    _subscription = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('pending_settlements')
        .snapshots()
        .listen((snapshot) {
      _settlements = snapshot.docs.map((doc) {
        return PendingSettlement.fromMap(doc.data());
      }).toList();
      notifyListeners();
    });
  }

  Future<void> addSettlement(PendingSettlement settlement) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('pending_settlements')
          .doc(settlement.id)
          .set(settlement.toMap());
    } catch (e) {
      print('Error adding pending settlement: $e');
      rethrow;
    }
  }

  Future<void> updateSettlement(PendingSettlement settlement) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('pending_settlements')
          .doc(settlement.id)
          .update(settlement.toMap());
    } catch (e) {
       print('Error updating pending settlement: $e');
       rethrow;
    }
  }

  Future<void> addPaymentToSettlement(String settlementId, double amount, DateTime date, String note) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final settlementRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('pending_settlements')
          .doc(settlementId);

       await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(settlementRef);
        if (!snapshot.exists) return;

        final currentData = snapshot.data()!;
        final currentHistory = (currentData['paymentHistory'] as List<dynamic>?) ?? [];
        
        currentHistory.add({
            'amount': amount,
            'date': Timestamp.fromDate(date),
            'note': note,
        });

        transaction.update(settlementRef, {
            'paymentHistory': currentHistory
        });
      });
      
    } catch (e) {
      print('Error adding payment to settlement: $e');
      rethrow;
    }
  }

  Future<void> deleteSettlement(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('pending_settlements')
          .doc(id)
          .delete();
    } catch (e) {
      print('Error deleting pending settlement: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
