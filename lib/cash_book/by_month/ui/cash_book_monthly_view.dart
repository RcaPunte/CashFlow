import 'package:cashledger/cash_book/by_month/controller/monthly_statement_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CashbookMonthViewScreen extends ConsumerWidget {
  final DateTime month;
  const CashbookMonthViewScreen({required this.month, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statementAsync = ref.watch(monthlyStatementProvider(month));

    return Material(
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(DateFormat('MMMM yyyy').format(month)),
        ),
        child: SafeArea(
          child: statementAsync.when(
            loading: () => Center(child: CupertinoActivityIndicator()),
            error: (e, _) => Center(child: Text("Error: $e")),
            data: (s) => ListView(
              padding: EdgeInsets.all(16),
              children: [
                // 🔹 SUMMARY CARD
                _summaryCard(s),

                SizedBox(height: 24),

                // 🔹 ACCOUNT REPORT
                Text(
                  "Receipts & Expenses by Account",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),

                ...s.accountSummary.entries.map((e) {
                  return _accountTile(e.key, e.value);
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -----------------------------------
  // SUMMARY CARD UI
  // -----------------------------------
  Widget _summaryCard(MonthlyStatement s) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _summaryRow("Opening Balance", s.opening),
          _summaryRow("New Receipts", s.receipts),
          _summaryRow("Total Receipts", s.totalReceipts, bold: true),
          _summaryRow("Total Expenses", s.expenses),
          Divider(),
          _summaryRow(
            "Closing Balance",
            s.totalReceipts - s.expenses,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            "₹${value.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------
  // ACCOUNT REPORT TILE
  // -----------------------------------
  Widget _accountTile(String name, AccountSummary s) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            _smallRow("Receipts", s.receipts),
            _smallRow("Expenses", s.expenses),
          ],
        ),
      ),
    );
  }

  Widget _smallRow(String label, double value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text("₹${value.toStringAsFixed(2)}")],
      ),
    );
  }
}
