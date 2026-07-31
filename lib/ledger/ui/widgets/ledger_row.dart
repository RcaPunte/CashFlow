import 'package:cashledger/ledger/model/ledger_entry.dart';
import 'package:cashledger/ledger/ui/ledger_details_page.dart';
import 'package:flutter/cupertino.dart';
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
    final formatter = NumberFormat('#,##0.00', 'en_US');
    final dateStr = DateFormat('MMM d').format(entry.date);

    final debitColor = CupertinoColors.activeGreen.resolveFrom(context);
    final creditColor = CupertinoColors.systemRed.resolveFrom(context);
    final balanceColor = runningBalance >= 0
        ? CupertinoColors.label.resolveFrom(context)
        : CupertinoColors.systemRed.resolveFrom(context);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator.withOpacity(0.6),
            width: 0.4,
          ),
        ),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.zero,
        onPressed: () {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => LedgerDetailPage(entryId: entry.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              // Date
              SizedBox(
                width: 56,
                child: Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ),
              // Description
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
              // Debit
              SizedBox(
                width: 72,
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
              // Credit
              SizedBox(
                width: 72,
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
              // Balance
              SizedBox(
                width: 80,
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

class LedgerRowHeaderWidget extends StatelessWidget {
  const LedgerRowHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: CupertinoColors.activeBlue,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator.withOpacity(0.6),
            width: 0.4,
          ),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: Text(
                "Date",
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Text(
                "Particulars",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(width: 8),
            SizedBox(
              width: 72,
              child: Text(
                "Receipts",
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(
              width: 72,
              child: Text(
                "Expenses",
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                "Balance",
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}