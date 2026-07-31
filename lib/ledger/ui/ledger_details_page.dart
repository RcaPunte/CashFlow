import 'package:cashledger/ledger/controller/ledger_details_controller.dart';
import 'package:cashledger/ledger/model/ledger_entry.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class LedgerDetailPage extends StatefulWidget {
  final String entryId;

  const LedgerDetailPage({super.key, required this.entryId});

  @override
  State<LedgerDetailPage> createState() => _LedgerDetailPageState();
}

class _LedgerDetailPageState extends State<LedgerDetailPage> {
  final _controller = LedgerDetailController();
  late Future<LedgerEntry?> _entryFuture;

  @override
  void initState() {
    super.initState();
    _entryFuture = _controller.getEntry(widget.entryId);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: const Text('Ledger Detail')),
      child: SafeArea(
        child: FutureBuilder<LedgerEntry?>(
          future: _entryFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return snapshot.connectionState == ConnectionState.waiting
                  ? const Center(child: CupertinoActivityIndicator())
                  : const Center(child: Text('Entry not found'));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final entry = snapshot.data!;
            final isDebit = entry.type == 'debit';
            final formatter = DateFormat('dd MMM yyyy');

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account: ${entry.accountName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Date: ${formatter.format(entry.date)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Type: ${isDebit ? 'Debit / Receipt' : 'Credit / Expense'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Amount: ₹${entry.amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Description: ${entry.description ?? '-'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}