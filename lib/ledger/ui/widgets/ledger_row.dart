import 'package:cashledger/ledger/model/ledger_entry.dart';
import 'package:cashledger/ledger/ui/widgets/ledger_details_pie.dart'; // Assuming this leads to the detail screen
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Retained for Material/InkWell context if needed, but not used here.
import 'package:intl/intl.dart';

class LedgerRowWidget extends StatelessWidget {
  final LedgerEntry entry;
  final double runningBalance;
  // NOTE: bgColor is removed in favor of a cleaner separator line,
  // but kept as a parameter for compatibility if the parent needs it.
  final Color bgColor;

  const LedgerRowWidget({
    super.key,
    required this.bgColor, // Keeping for compatibility, but using transparent color
    required this.entry,
    required this.runningBalance,
  });

  @override
  Widget build(BuildContext context) {
    final isDebit = entry.type == 'debit';
    final formatter = NumberFormat('#,##0.00', 'en_US');

    // Use resolved colors for dynamic dark/light mode support
    final debitColor = CupertinoColors.activeGreen.resolveFrom(context);
    final creditColor = CupertinoColors.systemRed.resolveFrom(context);
    final balanceColor = runningBalance >= 0
        ? CupertinoColors.label.resolveFrom(context)
        : CupertinoColors.systemRed.resolveFrom(
            context,
          ); // Highlight negative balance

    return Container(
      // Standard row height for list items
      height: 48,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground, // Ensure consistent background
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator.withOpacity(
              0.6,
            ), // Subtle separator
            width: 0.4,
          ),
        ),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.zero,
        onPressed: () {
          // Navigate to the detail screen on tap
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => LedgerDetailPage(entryId: entry.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
          ), // Consistent padding
          child: Row(
            children: [
              // 1. Date (Fixed width)
              SizedBox(
                width:
                    MediaQuery.of(context).size.width * 0.15, // Adjusted width
                child: Text(
                  // Use shorter format for table row
                  DateFormat(
                    'MMM d',
                  ).format(DateTime.parse(entry.date.toString())),
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ),

              // 2. Description (Expanded)
              Expanded(
                child: Text(
                  entry.description ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.label,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 3. Debit Amount (Fixed width, Right aligned)
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.18,
                child: Text(
                  isDebit ? formatter.format(entry.amount) : '',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: debitColor,
                  ),
                ),
              ),

              // 4. Credit Amount (Fixed width, Right aligned)
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.18,
                child: Text(
                  !isDebit ? formatter.format(entry.amount) : '',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: creditColor,
                  ),
                ),
              ),

              // 5. Running Balance (Fixed width, Right aligned)
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.20,
                child: Text(
                  formatter.format(runningBalance),
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
      ),
    );
  }
}
