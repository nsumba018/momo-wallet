import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'txn.dart';

// Add a new transaction, or edit one (when txn is given).
class TxnForm extends StatefulWidget {
  const TxnForm({super.key, this.txn, required this.balance});

  final Txn? txn;
  final int balance; // current balance, to refuse an OUT that is too big

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    final description = _description.text.trim();
    final amount = int.tryParse(_amount.text.trim());

    // Every check happens before anything is saved.
    if (description.isEmpty) return _refuse('Enter a description');
    if (amount == null || amount <= 0) {
      return _refuse('The amount must be a whole number above 0');
    }
    // Balance without the transaction being edited (if any).
    final base = widget.balance - (widget.txn?.signed ?? 0);
    final txn = Txn(description: description, amount: amount, isIn: _isIn);
    if (base + txn.signed < 0) return _refuse('Insufficient balance');

    setState(() => _saving = true);
    try {
      if (widget.txn == null) {
        await myTransactions().add({
          ...txn.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await myTransactions().doc(widget.txn!.id).update(txn.toMap());
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
    final editing = widget.txn != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit transaction' : 'New transaction')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                  labelText: 'Description', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Amount (RWF)', border: OutlineInputBorder()),
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
