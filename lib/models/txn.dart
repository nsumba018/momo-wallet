import 'package:cloud_firestore/cloud_firestore.dart';

// One transaction = one Firestore document.
class Txn {
  Txn({
    this.id = '',
    required this.description,
    required this.amount,
    required this.isIn,
    this.createdAt,
  });

  final String id;
  final String description;
  final int amount;
  final bool isIn; // true = money in, false = money out
  final DateTime? createdAt;

  // Only the facts are saved. The balance is never saved: it is computed.
  Map<String, dynamic> toMap() => {
    'description': description,
    'amount': amount,
    'isIn': isIn,
  };

  factory Txn.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Txn(
      id: doc.id,
      description: data['description'] as String,
      amount: (data['amount'] as num).toInt(),
      isIn: data['isIn'] as bool,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // +amount when money comes in, -amount when it goes out.
  int get signed => isIn ? amount : -amount;
}

// Balance after applying every transaction: money in minus money out.
int computeBalance(List<Txn> txns) =>
    txns.fold<int>(0, (total, t) => total + t.signed);

// True if the running balance never goes below 0 (oldest first).
bool historyStaysPositive(List<Txn> txnsOldestFirst) {
  var running = 0;
  for (final t in txnsOldestFirst) {
    running += t.signed;
    if (running < 0) return false;
  }
  return true;
}
