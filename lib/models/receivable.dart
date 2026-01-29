import 'package:cloud_firestore/cloud_firestore.dart';

class ReceivablePayment {
  final String id;
  final double amount;
  final DateTime date;
  final String note;

  ReceivablePayment({
    String? id,
    required this.amount,
    required this.date,
    this.note = '',
  }) : id = id ?? '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'note': note,
    };
  }

  factory ReceivablePayment.fromMap(Map<String, dynamic> map) {
    return ReceivablePayment(
      id: map['id'] ?? '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}',
      amount: (map['amount'] ?? 0).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      note: map['note'] ?? '',
    );
  }
}

class ReceivableSettlement {
  final String id;
  final double amount;
  final DateTime date;
  final String note;

  ReceivableSettlement({
    String? id,
    required this.amount,
    required this.date,
    this.note = '',
  }) : id = id ?? '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'note': note,
    };
  }

  factory ReceivableSettlement.fromMap(Map<String, dynamic> map) {
    return ReceivableSettlement(
      id: map['id'] ?? '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}',
      amount: (map['amount'] ?? 0).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      note: map['note'] ?? '',
    );
  }
}

class Receivable {
  final String id;
  final String title;
  final double amount;
  final List<ReceivablePayment> paymentHistory;
  final List<ReceivableSettlement> settlementHistory;
  final String fromWhom;
  final DateTime expectedReturnDate;
  final DateTime lentDate;
  final bool isSettled;
  final String type; // 'Person' or 'Card'
  final String note;

  Receivable({
    required this.id,
    required this.title,
    required this.amount,
    this.paymentHistory = const [],
    this.settlementHistory = const [],
    required this.fromWhom,
    required this.expectedReturnDate,
    required this.lentDate,
    this.isSettled = false,
    this.type = 'Person',
    this.note = '',
  });
  
  double get totalAdditionalLent {
      return paymentHistory.fold(0, (sum, item) => sum + item.amount);
  }
  
  double get totalSettled {
      return settlementHistory.fold(0, (sum, item) => sum + item.amount);
  }
  
  double get remainingAmount {
      return amount + totalAdditionalLent - totalSettled;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'paymentHistory': paymentHistory.map((e) => e.toMap()).toList(),
      'settlementHistory': settlementHistory.map((e) => e.toMap()).toList(),
      'fromWhom': fromWhom,
      'expectedReturnDate': Timestamp.fromDate(expectedReturnDate),
      'lentDate': Timestamp.fromDate(lentDate),
      'isSettled': isSettled,
      'type': type,
      'note': note,
    };
  }

  factory Receivable.fromMap(Map<String, dynamic> map) {
    var paymentList = map['paymentHistory'] as List<dynamic>?;
    List<ReceivablePayment> payments = [];
    if (paymentList != null) {
      payments = paymentList.map((p) => ReceivablePayment.fromMap(p as Map<String, dynamic>)).toList();
      // Sort by date descending
      payments.sort((a, b) => b.date.compareTo(a.date));
    }
    
    var settlementList = map['settlementHistory'] as List<dynamic>?;
    List<ReceivableSettlement> settlements = [];
    if (settlementList != null) {
      settlements = settlementList.map((p) => ReceivableSettlement.fromMap(p as Map<String, dynamic>)).toList();
      // Sort by date descending
      settlements.sort((a, b) => b.date.compareTo(a.date));
    }
    
    return Receivable(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      paymentHistory: payments,
      settlementHistory: settlements,
      fromWhom: map['fromWhom'] ?? '',
      expectedReturnDate: (map['expectedReturnDate'] as Timestamp).toDate(),
      lentDate: (map['lentDate'] as Timestamp).toDate(),
      isSettled: map['isSettled'] ?? false,
      type: map['type'] ?? 'Person',
      note: map['note'] ?? '',
    );
  }
}
