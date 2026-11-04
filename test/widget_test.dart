// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:momo_wallet/models/txn.dart';

void main() {
  test('computes the wallet balance from signed transactions', () {
    final transactions = [
      Txn(description: 'Opening balance', amount: 10000, isIn: true),
      Txn(description: 'Sent money', amount: 2500, isIn: false),
      Txn(description: 'Received money', amount: 4000, isIn: true),
    ];

    expect(computeBalance(transactions), 11500);
  });

  test('detects a transaction history that goes below zero', () {
    final validHistory = [
      Txn(description: 'Opening balance', amount: 1000, isIn: true),
      Txn(description: 'Purchase', amount: 500, isIn: false),
    ];
    final invalidHistory = [
      Txn(description: 'Purchase', amount: 500, isIn: false),
    ];

    expect(historyStaysPositive(validHistory), isTrue);
    expect(historyStaysPositive(invalidHistory), isFalse);
  });
}
