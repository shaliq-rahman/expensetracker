import 'package:cloud_firestore/cloud_firestore.dart';

class SettlementPayment {
  final double amount;
  final DateTime date;
  final String note;

  SettlementPayment({
    required this.amount,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'note': note,
    };
  }

  factory SettlementPayment.fromMap(Map<String, dynamic> map) {
    return SettlementPayment(
      amount: (map['amount'] ?? 0).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      note: map['note'] ?? '',
    );
  }
}

class PendingSettlement {
  final String id;
  final String title;
  final double amount;
  final List<SettlementPayment> paymentHistory;
  final String toWhom;
  final DateTime expectedClosingDate;
  final bool isSettled;
  final String type; // 'Person' or 'Card'

  PendingSettlement({
    required this.id,
    required this.title,
    required this.amount,
    this.paymentHistory = const [],
    required this.toWhom,
    required this.expectedClosingDate,
    this.isSettled = false,
    this.type = 'Person',
  });
  
  double get totalPaid {
      return paymentHistory.fold(0, (sum, item) => sum + item.amount);
  }
  
  double get remainingAmount {
      return amount - totalPaid;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'paymentHistory': paymentHistory.map((e) => e.toMap()).toList(),
      'toWhom': toWhom,
      'expectedClosingDate': Timestamp.fromDate(expectedClosingDate),
      'isSettled': isSettled,
      'type': type,
    };
  }

  factory PendingSettlement.fromMap(Map<String, dynamic> map) {
    var list = map['paymentHistory'] as List<dynamic>?;
    List<SettlementPayment> history = [];
    if (list != null) {
        history = list.map((e) => SettlementPayment.fromMap(e)).toList();
    } else if (map['paidAmount'] != null) {
        // Migration/Fallback: If old paidAmount exists, create one entry
        double oldPaid = (map['paidAmount'] ?? 0).toDouble();
        if (oldPaid > 0) {
            history.add(SettlementPayment(amount: oldPaid, date: DateTime.now()));
        }
    }

    return PendingSettlement(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      paymentHistory: history,
      toWhom: map['toWhom'] ?? '',
      expectedClosingDate: (map['expectedClosingDate'] as Timestamp).toDate(),
      isSettled: map['isSettled'] ?? false,
      type: map['type'] ?? 'Person',
    );
  }
}
