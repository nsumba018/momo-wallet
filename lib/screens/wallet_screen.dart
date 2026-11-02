import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/txn.dart';
import 'txn_form.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  String _filter = 'All'; // All, IN or OUT

  Future<void> _delete(BuildContext context, Txn txn, List<Txn> all) async {
    // Refuse a delete that would make the balance go below 0 in the history.
    final oldestFirst = all.reversed.where((t) => t.id != txn.id).toList();
    if (!historyStaysPositive(oldestFirst)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cannot delete: the balance would go below 0')));
      return;
    }
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this transaction?'),
        content: Text(txn.description),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (sure == true) {
      await myTransactions().doc(txn.id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // Live: delivers the list now, and again at every change.
      stream: myTransactions().orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        final loaded = snapshot.hasData;
        final txns = loaded ? snapshot.data!.docs.map(Txn.fromDoc).toList() : <Txn>[];
        // Computed every time, never saved.
        final balance = computeBalance(txns);
        final totalIn = txns.where((t) => t.isIn).fold<int>(0, (s, t) => s + t.amount);
        final totalOut = txns.where((t) => !t.isIn).fold<int>(0, (s, t) => s + t.amount);
        final shown = _filter == 'IN'
            ? txns.where((t) => t.isIn).toList()
            : _filter == 'OUT'
                ? txns.where((t) => !t.isIn).toList()
                : txns;

        return Scaffold(
          appBar: AppBar(
            title: const Text('MoMo Wallet'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Log out',
                onPressed: () => FirebaseAuth.instance.signOut(),
              ),
            ],
          ),
          floatingActionButton: loaded
              ? FloatingActionButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => TxnForm(balance: balance))),
                  child: const Icon(Icons.add),
                )
              : null,
          body: _body(context, snapshot, txns, shown, balance, totalIn, totalOut),
        );
      },
    );
  }

  Widget _body(BuildContext context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
      List<Txn> txns, List<Txn> shown, int balance, int totalIn, int totalOut) {
    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Could not load your transactions.\n${snapshot.error}',
              textAlign: TextAlign.center),
        ),
      );
    }
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(FirebaseAuth.instance.currentUser?.email ?? '',
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Text('$balance RWF',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('In: $totalIn   ·   Out: $totalOut'),
              ],
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final f in ['All', 'IN', 'OUT'])
              ChoiceChip(
                label: Text(f),
                selected: _filter == f,
                onSelected: (_) => setState(() => _filter = f),
              ),
          ],
        ),
        Expanded(
          child: shown.isEmpty
              ? const Center(child: Text('No transactions yet'))
              : ListView.builder(
                  itemCount: shown.length,
                  itemBuilder: (context, index) {
                    final t = shown[index];
                    return ListTile(
                      leading: Icon(
                        t.isIn ? Icons.arrow_downward : Icons.arrow_upward,
                        color: t.isIn ? Colors.green : Colors.red,
                      ),
                      title: Text(t.description),
                      trailing: Text(
                        '${t.isIn ? '+' : '-'}${t.amount}',
                        style: TextStyle(
                            color: t.isIn ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold),
                      ),
                      // Tap = edit, long press = delete.
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => TxnForm(txn: t, balance: balance))),
                      onLongPress: () => _delete(context, t, txns),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
