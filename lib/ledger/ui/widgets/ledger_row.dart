import 'package:cashledger/ledger/model/ledger_entry.dart';
import 'package:cashledger/ledger/ui/widgets/ledger_details_pie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LedgerRowWidget extends StatelessWidget {
  final LedgerEntry entry;
  final double runningBalance;

  const LedgerRowWidget({
    super.key,
    required this.entry,
    required this.runningBalance,
  });

  @override
  Widget build(BuildContext context) {
    final isDebit = entry.type == 'debit';

    final debitColor = CupertinoColors.activeGreen.resolveFrom(context);
    final creditColor = CupertinoColors.systemRed.resolveFrom(context);
    final balanceColor = CupertinoColors.label.resolveFrom(context);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => LedgerDetailPage(entryId: entry.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: CupertinoColors.separator, width: 0.4),
          ),
        ),
        child: Row(
          children: [
            // Date
            Expanded(
              flex: 2,
              child: Text(
                DateFormat('MMM d, yy').format(entry.date),
                style: const TextStyle(
                  fontSize: 11,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ),

            // Description
            Expanded(
              flex: 4,
              child: Text(
                entry.description ?? '',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),

            // Debit Amount
            Expanded(
              flex: 2,
              child: Text(
                isDebit ? entry.amount.toStringAsFixed(0) : '',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: debitColor,
                ),
              ),
            ),

            // Credit Amount
            Expanded(
              flex: 2,
              child: Text(
                !isDebit ? entry.amount.toStringAsFixed(0) : '',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: creditColor,
                ),
              ),
            ),

            // Running Balance
            Expanded(
              flex: 2,
              child: Text(
                runningBalance.toStringAsFixed(0),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: balanceColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// class LedgerRowWidget extends StatelessWidget {
//   final LedgerEntry entry;
//   final double balance;
//   final String? accountFilter;

//   const LedgerRowWidget({
//     required this.entry,
//     required this.balance,
//     this.accountFilter,
//     super.key,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final isDebit = entry.type == 'debit';
//     final formatter = DateFormat('MMM d, yy');

//     return InkWell(
//       onTap: () => context.push('/ledger/detail/${entry.id}'),
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//         decoration: BoxDecoration(
//           border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
//         ),
//         child: Row(
//           children: [
//             // DATE
//             SizedBox(
//               width: MediaQuery.of(context).size.width * 0.14,
//               child: Text(
//                 formatter.format(entry.date),
//                 style: const TextStyle(fontSize: 10),
//               ),
//             ),

//             // DESCRIPTION
//             Expanded(
//               child: Text(
//                 entry.description ?? '',
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//                 style: const TextStyle(fontSize: 11),
//               ),
//             ),

//             // DEBIT
//             SizedBox(
//               width: MediaQuery.of(context).size.width * 0.15,
//               child: Text(
//                 isDebit ? entry.amount.toStringAsFixed(0) : '',
//                 textAlign: TextAlign.right,
//                 style: const TextStyle(fontSize: 11),
//               ),
//             ),

//             // CREDIT
//             SizedBox(
//               width: MediaQuery.of(context).size.width * 0.15,
//               child: Text(
//                 !isDebit ? entry.amount.toStringAsFixed(0) : '',
//                 textAlign: TextAlign.right,
//                 style: const TextStyle(fontSize: 11),
//               ),
//             ),

//             // BALANCE
//             SizedBox(
//               width: MediaQuery.of(context).size.width * 0.15,
//               child: Text(
//                 balance.toStringAsFixed(0),
//                 textAlign: TextAlign.right,
//                 style: const TextStyle(fontSize: 11),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
