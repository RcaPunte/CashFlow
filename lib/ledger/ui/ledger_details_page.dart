import 'package:cashledger/ledger/controller/leder_details_controller.dart';
import 'package:cashledger/ledger/model/ledger_entry.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LedgerDetailPage extends ConsumerWidget {
  final String entryId;

  const LedgerDetailPage({super.key, required this.entryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supabase = Supabase.instance.client;

    return FutureBuilder<Map<String, dynamic>?>(
      future: supabase
          .from('ledger_entries')
          .select('*, accounts(name)')
          .eq('id', entryId)
          .maybeSingle(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CupertinoActivityIndicator());
        if (snapshot.hasError)
          return Center(child: Text('Error loading entry'));

        final data = snapshot.data!;
        final entry = LedgerEntry.fromMap(data);

        final isDebit = entry.type == 'debit';
        final formatter = DateFormat('dd MMM yyyy');

        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(middle: Text('Ledger Detail')),
          child: SafeArea(
            child: Padding(
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
            ),
          ),
        );
      },
    );
  }
}

// class LedgerDetailPage extends StatelessWidget {
//   final String entryId;

//   const LedgerDetailPage({super.key, required this.entryId});

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder(
//       future: Supabase.instance.client
//           .from("ledger")
//           .select()
//           .eq("id", entryId)
//           .single(),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           return const Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         }

//         final e = LedgerEntry.fromMap(snapshot.data as Map<String, dynamic>);

//         return Scaffold(
//           appBar: AppBar(title: const Text("Ledger Detail")),
//           body: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text("Date: ${e.date}"),
//                 Text("Account: ${e.accountId}"),
//                 Text("Type: ${e.type}"),
//                 Text("Amount: ${e.amount}"),
//                 Text("Description: ${e.description ?? ''}"),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
