import 'package:cashledger/cash_book/by_month/controller/monthly_summary_provider.dart';
import 'package:cashledger/cash_book/by_month/model/monthly_cash_summary.dart';
import 'package:cashledger/cash_book/by_month/ui/monthly_report_screen.dart';
import 'package:cashledger/cash_book/ui/widget/financial_yeaer_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Keep for Material-based Riverpod/scaffolding compatibility if needed, but UI is Cupertino
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class MonthlyLedgerListScreen extends ConsumerStatefulWidget {
  const MonthlyLedgerListScreen({super.key});

  @override
  ConsumerState<MonthlyLedgerListScreen> createState() =>
      _MonthlyLedgerListScreenState();
}

class _MonthlyLedgerListScreenState
    extends ConsumerState<MonthlyLedgerListScreen> {
  late final List<DateTime> months;
  final DateFormat _monthFormat = DateFormat('MMMM yyyy');

  @override
  void initState() {
    super.initState();
    initDate();
    // Generate the last 12 months, ordered oldest to newest
  }

  initDate() {
    final year = ref.read(yearProvider);
    final now = DateTime(
      year,
      12,
      1,
    ); // Start from the end of the selected year
    months = List.generate(
      12,
      (i) => DateTime(now.year, now.month - i, 1),
    ).reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    // Watch all months using FutureProvider.family
    final summariesAsync = months
        .map((month) => ref.watch(monthlySummaryProvider(month)))
        .toList();

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Monthly Ledger"),
      ),
      child: CustomScrollView(
        slivers: [
          // 1. Total Summary Header (now a SliverToBoxAdapter for integration)
          SliverToBoxAdapter(child: _TotalsSummary(summaries: summariesAsync)),

          // 2. Monthly List Header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Text(
                'Month-wise Reports',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: CupertinoColors.label,
                ),
              ),
            ),
          ),

          // 3. Monthly List Items (Grouped iOS Style)
          SliverList(
            delegate: SliverChildListDelegate([
              CupertinoListSection(
                // Use list style for a clean, non-inset look within the scroll view
                backgroundColor: CupertinoColors.systemGroupedBackground,
                children: List.generate(months.length, (index) {
                  final monthSummary = summariesAsync[index];

                  return monthSummary.when(
                    loading: () => const CupertinoListTile(
                      leading: CupertinoActivityIndicator(),
                      title: Text('Loading...'),
                    ),
                    error: (e, _) => CupertinoListTile(
                      title: Text(
                        "Error fetching data",
                        style: TextStyle(color: CupertinoColors.destructiveRed),
                      ),
                    ),
                    data: (MonthlyCashSummary m) => _MonthlySummaryTile(
                      summary: m,
                      monthFormat: _monthFormat,
                    ),
                  );
                }),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// Component 1: Totals Summary
// ----------------------------------------------------

class _TotalsSummary extends StatelessWidget {
  final List<AsyncValue<MonthlyCashSummary>> summaries;

  const _TotalsSummary({required this.summaries});

  Widget _summaryRow(String label, double value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: CupertinoColors.systemGrey),
          ),
          Text(
            "₹${value.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color ?? CupertinoColors.label,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalReceipts = 0;
    double totalExpenses = 0;

    for (var s in summaries) {
      s.whenData((m) {
        totalReceipts += m.receipts;
        totalExpenses += m.expenses;
      });
    }

    final totalBalance = totalReceipts - totalExpenses;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemGroupedBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: CupertinoColors.separator.withOpacity(0.5),
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Total YTD Summary",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: CupertinoColors.activeBlue,
              ),
            ),
            const Divider(height: 20, color: CupertinoColors.separator),
            _summaryRow(
              "Total Receipts",
              totalReceipts,
              color: CupertinoColors.activeGreen,
            ),
            _summaryRow(
              "Total Expenses",
              totalExpenses,
              color: CupertinoColors.destructiveRed,
            ),
            _summaryRow(
              "Net Balance",
              totalBalance,
              color: totalBalance >= 0
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.destructiveRed,
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// Component 2: Monthly Tile
// ----------------------------------------------------

class _MonthlySummaryTile extends StatelessWidget {
  final MonthlyCashSummary summary;
  final DateFormat monthFormat;

  const _MonthlySummaryTile({required this.summary, required this.monthFormat});

  @override
  Widget build(BuildContext context) {
    final monthDate = DateTime.parse("${summary.monthKey}-01");
    return CupertinoListTile(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => MonthlyReportScreen(month: monthDate),
          ),
        );
      },
      // Leading icon or visual indicator
      leading: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: CupertinoColors.activeBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            monthFormat.format(monthDate)[0], // First letter of the month
            style: const TextStyle(
              color: CupertinoColors.activeBlue,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),

      // Title is the month name
      title: Padding(
        padding: const EdgeInsets.only(top: 6.0),
        child: Text(
          monthFormat.format(monthDate),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Subtitle shows the key metrics (Receipts/Expenses)
      subtitle: Padding(
        padding: const EdgeInsets.only(left: 0, top: 6, bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'IN: ₹${summary.receipts.toStringAsFixed(0)}',
              style: const TextStyle(
                color: CupertinoColors.activeGreen,
                fontSize: 12,
              ),
            ),
            Spacer(),
            //const SizedBox(width: 8),
            Text(
              'OUT: ₹${summary.expenses.toStringAsFixed(0)}',
              style: const TextStyle(
                color: CupertinoColors.destructiveRed,
                fontSize: 12,
              ),
            ),
            Spacer(),
            Text(
              "BL: ₹${summary.closingBalance.toStringAsFixed(2)}",
              style: TextStyle(
                // fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),

      // Trailing shows the closing balance and navigation arrow
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 6.0),
            child: Icon(CupertinoIcons.chevron_right, size: 16),
          ),
        ],
      ),
    );
  }
}
