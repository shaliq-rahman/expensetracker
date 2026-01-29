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
            'id': DateTime.now().microsecondsSinceEpoch.toString(),
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

  Future<void> editPaymentInSettlement(String settlementId, SettlementPayment oldPayment, SettlementPayment updatedPayment) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('pending_settlements')
          .doc(settlementId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final data = snapshot.data()!;
        final historyList = List<Map<String, dynamic>>.from(data['paymentHistory'] ?? []);
        
        int index = -1;
        for(int i=0; i<historyList.length; i++) {
             final map = historyList[i];
             // 1. Try match by ID
             if (map['id'] != null && map['id'] == oldPayment.id) {
                 index = i; break;
             }
             // 2. Fallback: Match by content if ID is missing (Legacy data)
             if (map['id'] == null) {
                 final amount = (map['amount'] ?? 0).toDouble();
                 final note = map['note'] ?? '';
                 final date = (map['date'] as Timestamp).toDate();
                 
                 // Check if content matches (allowing small time diff for precision)
                 if (amount == oldPayment.amount && 
                     note == oldPayment.note && 
                     date.difference(oldPayment.date).abs().inSeconds < 5) { // 5s tolerance
                     index = i; break;
                 }
             }
        }
        
        if (index != -1) {
          historyList[index] = updatedPayment.toMap();
          transaction.update(docRef, {
            'paymentHistory': historyList
          });
        } else {
            print('Payment to edit not found!'); // Debug info
        }
      });
    } catch (e) {
      print('Error editing payment in settlement: $e');
      rethrow;
    }
  }

  Future<void> deletePaymentFromSettlement(String settlementId, SettlementPayment paymentToDelete) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('pending_settlements')
          .doc(settlementId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final data = snapshot.data()!;
        final historyList = List<Map<String, dynamic>>.from(data['paymentHistory'] ?? []);
        
        int index = -1;
        for(int i=0; i<historyList.length; i++) {
             final map = historyList[i];
             if (map['id'] != null && map['id'] == paymentToDelete.id) {
                 index = i; break;
             }
             if (map['id'] == null) {
                 final amount = (map['amount'] ?? 0).toDouble();
                 final note = map['note'] ?? '';
                 final date = (map['date'] as Timestamp).toDate();
                 
                 if (amount == paymentToDelete.amount && 
                     note == paymentToDelete.note && 
                     date.difference(paymentToDelete.date).abs().inSeconds < 5) {
                     index = i; break;
                 }
             }
        }

        if (index != -1) {
           historyList.removeAt(index);
           transaction.update(docRef, {
              'paymentHistory': historyList
           });
        }
      });
    } catch (e) {
      print('Error deleting payment from settlement: $e');
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
