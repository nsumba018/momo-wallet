import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/txn.dart';
import '../state/wallet_state.dart';

// Add a new transaction, or edit one (when txn is given).
class TxnForm extends StatefulWidget {
  const TxnForm({super.key, this.txn});

  final Txn? txn;

  @override
  State<TxnForm> createState() => _TxnFormState();
}

class _TxnFormState extends State<TxnForm> {
  final _description = TextEditingController();
  final _amount = TextEditingController();
  bool _isIn = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.txn;
    if (t != null) {
      _description.text = t.description;
      _amount.text = t.amount.toString();
      _isIn = t.isIn;
    }
  }

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _refuse(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    final description = _description.text.trim();
    final amount = int.tryParse(_amount.text.trim());

    // Every check happens before anything is saved.
    if (description.isEmpty) return _refuse('Enter a description');
    if (amount == null || amount <= 0) {
      return _refuse('The amount must be a whole number above 0');
    }
    final wallet = context.read<WalletState>();
    // Balance without the transaction being edited (if any).
    final base = wallet.balance - (widget.txn?.signed ?? 0);
    final txn = Txn(description: description, amount: amount, isIn: _isIn);
    if (base + txn.signed < 0) return _refuse('Insufficient balance');

    setState(() => _saving = true);
    try {
      if (widget.txn == null) {
        await wallet.add(txn);
      } else {
        await wallet.edit(widget.txn!.id, txn);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _refuse('Could not save: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = context.watch<WalletState>().balance;
    final editing = widget.txn != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit transaction' : 'New transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your balance: $balance RWF',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('IN')),
                ButtonSegment(value: false, label: Text('OUT')),
              ],
              selected: {_isIn},
              onSelectionChanged: (s) => setState(() => _isIn = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (RWF)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(editing ? 'Save changes' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }
}
