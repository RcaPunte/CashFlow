import 'dart:collection';
import 'package:cashledger/cash_book/by_month/controller/monthly_summary_provider.dart';
import 'package:cashledger/cash_book/by_month/model/monthly_cash_summary.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ByMonth extends ConsumerStatefulWidget {
  final DateTime date;

  const ByMonth({super.key, required this.date});

  @override
  ConsumerState<ByMonth> createState() => _ByMonthState();
}

class _ByMonthState extends ConsumerState<ByMonth> {
  final DateFormat rowDateFormat = DateFormat('dd MMM yyyy');

  LinkedHashMap<String, double> _groupMapByAccount(Map<String, double> data) {
    final sortedKeys = data.keys.toList()..sort();
    final map = <String, double>{}; // collection literal
    for (var k in sortedKeys) {
      map[k] = data[k]!;
    }
    return LinkedHashMap.from(map); // ensures return type is LinkedHashMap
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(monthlySummaryProvider(widget.date));

    return Material(
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(
            "Monthly Report: ${widget.date.month}/${widget.date.year}",
          ),
        ),
        child: summaryAsync.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => Center(child: Text("Error: $e")),
          data: (MonthlyCashSummary m) => SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCard(m),
                const SizedBox(height: 20),
                _sectionTitle("Receipts by Account"),
                _accountsTable(_groupMapByAccount(m.receiptsByAccount)),
                const SizedBox(height: 16),
                _sectionTitle("Expenses by Account"),
                _accountsTable(_groupMapByAccount(m.expensesByAccount)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(MonthlyCashSummary m) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _row("Opening Balance", m.openingBalance),
          _row("Receipts", m.receipts),
          _row("Expenses", m.expenses),
          const Divider(height: 20),
          _row("Closing Balance", m.closingBalance, isBold: true),
        ],
      ),
    );
  }

  Widget _row(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            "₹${value.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _accountsTable(LinkedHashMap<String, double> data) {
    if (data.isEmpty) {
      return const Text("No data");
    }
    return CupertinoListSection.insetGrouped(
      children: data.entries
          .map(
            (e) => CupertinoListTile(
              title: Text(e.key),
              trailing: Text("₹${e.value.toStringAsFixed(2)}"),
            ),
          )
          .toList(),
    );
  }
}
