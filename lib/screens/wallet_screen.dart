import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/txn.dart';
import '../state/wallet_state.dart';
import 'txn_form.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  Future<void> _delete(BuildContext context, Txn txn) async {
    final wallet = context.read<WalletState>();
    // Refuse a delete that would make the balance go below 0 in the history.
    final oldestFirst = wallet.transactions.reversed
        .where((t) => t.id != txn.id)
        .toList();
    if (!historyStaysPositive(oldestFirst)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete: the balance would go below 0'),
        ),
      );
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
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (sure == true) {
      await wallet.remove(txn);
    }
  }

  void _openForm(BuildContext context, Txn? txn) {
    final wallet = context.read<WalletState>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<WalletState>.value(
          value: wallet,
          child: TxnForm(txn: txn),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final wallet = context.watch<WalletState>();

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
      floatingActionButton: wallet.loading
          ? null
          : FloatingActionButton(
              onPressed: () => _openForm(context, null),
              child: const Icon(Icons.add),
            ),
      body: _body(context, wallet, user),
    );
  }

  Widget _body(BuildContext context, WalletState wallet, User user) {
    if (wallet.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(wallet.error!, textAlign: TextAlign.center),
        ),
      );
    }
    if (wallet.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final txns = wallet.transactions;
    final shown = wallet.visible;

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  user.email ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  '${wallet.balance} RWF',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('In: ${wallet.totalIn}   ·   Out: ${wallet.totalOut}'),
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
                selected: wallet.filter == f.toLowerCase(),
                onSelected: (_) =>
                    context.read<WalletState>().setFilter(f.toLowerCase()),
              ),
          ],
        ),
        Expanded(
          child: txns.isEmpty
              ? const Center(
                  child: Text('No transactions yet. Tap + to add one.'),
                )
              : shown.isEmpty
              ? const Center(child: Text('Nothing matches this filter.'))
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () => _openForm(context, t),
                      onLongPress: () => _delete(context, t),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
