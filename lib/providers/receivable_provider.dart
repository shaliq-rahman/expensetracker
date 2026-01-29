import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/models/receivable.dart';

class ReceivableProvider with ChangeNotifier {
  List<Receivable> _receivables = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription? _subscription;

  List<Receivable> get receivables => _receivables;

  void fetchReceivables() {
    final user = _auth.currentUser;
    if (user == null) {
      _receivables = [];
      notifyListeners();
      return;
    }

    _subscription?.cancel();
    _subscription = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('receivables')
        .snapshots()
        .listen((snapshot) {
      _receivables = snapshot.docs.map((doc) {
        return Receivable.fromMap(doc.data());
      }).toList();
      notifyListeners();
    });
  }

  Future<void> addReceivable(Receivable receivable) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('receivables')
          .doc(receivable.id)
          .set(receivable.toMap());
    } catch (e) {
      print('Error adding receivable: $e');
      rethrow;
    }
  }

  Future<void> updateReceivable(Receivable receivable) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('receivables')
          .doc(receivable.id)
          .update(receivable.toMap());
    } catch (e) {
       print('Error updating receivable: $e');
       rethrow;
    }
  }

  Future<void> addPaymentToReceivable(String receivableId, double amount, DateTime date, String note) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final receivableRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('receivables')
          .doc(receivableId);

       await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(receivableRef);
        if (!snapshot.exists) return;

        final currentData = snapshot.data()!;
        final currentHistory = (currentData['paymentHistory'] as List<dynamic>?) ?? [];
        
        // Generate a unique ID for the new payment
        final paymentId = '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
        
        currentHistory.add({
            'id': paymentId,
            'amount': amount,
            'date': Timestamp.fromDate(date),
            'note': note,
        });

        transaction.update(receivableRef, {
            'paymentHistory': currentHistory
        });
      });
      
    } catch (e) {
      print('Error adding payment to receivable: $e');
      rethrow;
    }
  }

  Future<void> addSettlementToReceivable(String receivableId, double amount, DateTime date, String note) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final receivableRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('receivables')
          .doc(receivableId);

       await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(receivableRef);
        if (!snapshot.exists) return;

        final currentData = snapshot.data()!;
        final currentHistory = (currentData['settlementHistory'] as List<dynamic>?) ?? [];
        
        // Generate a unique ID for the new settlement
        final settlementId = '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
        
        currentHistory.add({
            'id': settlementId,
            'amount': amount,
            'date': Timestamp.fromDate(date),
            'note': note,
        });

        transaction.update(receivableRef, {
            'settlementHistory': currentHistory
        });
      });
      
    } catch (e) {
      print('Error adding settlement to receivable: $e');
      rethrow;
    }
  }

  Future<void> editPaymentInReceivable(String receivableId, String paymentId, double amount, DateTime date, String note) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('editPaymentInReceivable: No user logged in');
      return;
    }

    print('editPaymentInReceivable called: receivableId=$receivableId, paymentId=$paymentId, amount=$amount, note=$note');

    try {
      final receivableRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('receivables')
          .doc(receivableId);

       await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(receivableRef);
        if (!snapshot.exists) {
          print('editPaymentInReceivable: Receivable not found');
          return;
        }

        final currentData = snapshot.data()!;
        final currentHistory = (currentData['paymentHistory'] as List<dynamic>?) ?? [];
        
        print('editPaymentInReceivable: Current history length: ${currentHistory.length}');
        print('editPaymentInReceivable: Looking for paymentId: $paymentId');
        // Find the payment by ID or by matching amount and date if ID is null
        int? matchIndex;
        print('editPaymentInReceivable: DUMPING HISTORY:');
        for (int i = 0; i < currentHistory.length; i++) {
          final item = currentHistory[i];
          print('  Index $i: $item');
          final itemId = item['id'];
          print('  Index $i ID: $itemId (Type: ${itemId.runtimeType})');
          
          // If the item has an ID and it matches, use it
          if (itemId != null && itemId.toString() == paymentId.toString()) {
            matchIndex = i;
            print('editPaymentInReceivable: Found payment by ID at index $i');
            break;
          }
        }
        
        // If not found by ID, this might be an old payment without an ID
        // We need to match it by its position or unique characteristics
        // Since we can't reliably match without an ID, we'll assign IDs to all payments
        if (matchIndex == null) {
          print('editPaymentInReceivable: Payment ID not found - this may be an old payment without ID');
          print('editPaymentInReceivable: Will assign IDs to all payments and update based on generated ID');
        }
        
        // Build updated history
        final updatedHistory = <Map<String, dynamic>>[];
        bool foundPayment = false;
        
        for (int i = 0; i < currentHistory.length; i++) {
          final item = currentHistory[i];
          final itemId = item['id'];
          final currentItemId = itemId ?? '${item['date'].millisecondsSinceEpoch}_${i}';
          
          // Check if this is the payment we're editing
          bool isMatch = false;
          if (matchIndex != null && i == matchIndex) {
            isMatch = true;
          } else if (matchIndex == null && currentItemId.toString() == paymentId.toString()) {
            // Match by generated ID if original was null
            isMatch = true;
          }
          
          if (isMatch) {
            foundPayment = true;
            print('editPaymentInReceivable: Updating payment at index $i');
            updatedHistory.add({
              'id': paymentId,
              'amount': amount,
              'date': Timestamp.fromDate(date),
              'note': note,
            });
          } else {
            // Preserve existing payment, assign ID if missing
            updatedHistory.add({
              'id': currentItemId,
              'amount': item['amount'],
              'date': item['date'],
              'note': item['note'] ?? '',
            });
          }
        }

        if (!foundPayment) {
          print('editPaymentInReceivable: WARNING - Payment not found in history!');
        }

        print('editPaymentInReceivable: Updating with ${updatedHistory.length} items');
        transaction.update(receivableRef, {
            'paymentHistory': updatedHistory
        });
      });
      
      print('editPaymentInReceivable: Transaction completed successfully');
    } catch (e) {
      print('Error editing payment in receivable: $e');
      rethrow;
    }
  }

  Future<void> deletePaymentFromReceivable(String receivableId, String paymentId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final receivableRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('receivables')
          .doc(receivableId);

       await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(receivableRef);
        if (!snapshot.exists) return;

        final currentData = snapshot.data()!;
        final currentHistory = (currentData['paymentHistory'] as List<dynamic>?) ?? [];
        
        // Remove the specific payment
        final updatedHistory = currentHistory.where((item) => item['id'] != paymentId).toList();

        transaction.update(receivableRef, {
            'paymentHistory': updatedHistory
        });
      });
      
    } catch (e) {
      print('Error deleting payment from receivable: $e');
      rethrow;
    }
  }

  Future<void> editSettlementInReceivable(String receivableId, String settlementId, double amount, DateTime date, String note) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('editSettlementInReceivable: No user logged in');
      return;
    }

    print('editSettlementInReceivable called: receivableId=$receivableId, settlementId=$settlementId, amount=$amount, note=$note');

    try {
      final receivableRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('receivables')
          .doc(receivableId);

       await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(receivableRef);
        if (!snapshot.exists) {
          print('editSettlementInReceivable: Receivable not found');
          return;
        }

        final currentData = snapshot.data()!;
        final currentHistory = (currentData['settlementHistory'] as List<dynamic>?) ?? [];
        
        print('editSettlementInReceivable: Current history length: ${currentHistory.length}');
        print('editSettlementInReceivable: Looking for settlementId: $settlementId');
        
        // Try to find settlement by ID first
        int? matchIndex;
        for (int i = 0; i < currentHistory.length; i++) {
          final item = currentHistory[i];
          final itemId = item['id'];
          
          if (itemId != null && itemId.toString() == settlementId.toString()) {
            matchIndex = i;
            print('editSettlementInReceivable: Found settlement by ID at index $i');
            break;
          }
        }
        
        if (matchIndex == null) {
          print('editSettlementInReceivable: Settlement ID not found - this may be an old settlement without ID');
        }
        
        // Build updated history
        final updatedHistory = <Map<String, dynamic>>[];
        bool foundSettlement = false;
        
        for (int i = 0; i < currentHistory.length; i++) {
          final item = currentHistory[i];
          final itemId = item['id'];
          final currentItemId = itemId ?? '${item['date'].millisecondsSinceEpoch}_${i}';
          
          // Check if this is the settlement we're editing
          bool isMatch = false;
          if (matchIndex != null && i == matchIndex) {
            isMatch = true;
          } else if (matchIndex == null && currentItemId.toString() == settlementId.toString()) {
            isMatch = true;
          }
          
          if (isMatch) {
            foundSettlement = true;
            print('editSettlementInReceivable: Updating settlement at index $i');
            updatedHistory.add({
              'id': settlementId,
              'amount': amount,
              'date': Timestamp.fromDate(date),
              'note': note,
            });
          } else {
            // Preserve existing settlement, assign ID if missing
            updatedHistory.add({
              'id': currentItemId,
              'amount': item['amount'],
              'date': item['date'],
              'note': item['note'] ?? '',
            });
          }
        }

        if (!foundSettlement) {
          print('editSettlementInReceivable: WARNING - Settlement not found in history!');
        }

        print('editSettlementInReceivable: Updating with ${updatedHistory.length} items');
        transaction.update(receivableRef, {
            'settlementHistory': updatedHistory
        });
      });
      
      print('editSettlementInReceivable: Transaction completed successfully');
    } catch (e) {
      print('Error editing settlement in receivable: $e');
      rethrow;
    }
  }

  Future<void> deleteSettlementFromReceivable(String receivableId, String settlementId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final receivableRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('receivables')
          .doc(receivableId);

       await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(receivableRef);
        if (!snapshot.exists) return;

        final currentData = snapshot.data()!;
        final currentHistory = (currentData['settlementHistory'] as List<dynamic>?) ?? [];
        
        // Remove the specific settlement
        final updatedHistory = currentHistory.where((item) => item['id'] != settlementId).toList();

        transaction.update(receivableRef, {
            'settlementHistory': updatedHistory
        });
      });
      
    } catch (e) {
      print('Error deleting settlement from receivable: $e');
      rethrow;
    }
  }

  Future<void> deleteReceivable(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('receivables')
          .doc(id)
          .delete();
    } catch (e) {
      print('Error deleting receivable: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
