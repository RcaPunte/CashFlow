import 'package:cashledger/cash_book/by_month/controller/annual_chart_provider.dart';
import 'package:cashledger/cash_book/ui/annual_barline_chart.dart';
import 'package:cashledger/cash_book/ui/cash_book_add_edit_screen.dart';
import 'package:cashledger/cash_book/ui/cash_book_list_screen.dart';
import 'package:cashledger/ledger/ui/monthly_ledger_list_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Retained for certain color usage or scaffolding
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cashledger/cash_book/by_month/controller/monthly_summary_provider.dart';
import 'package:cashledger/cash_book/by_month/model/monthly_cash_summary.dart';

class CashbookDashboard extends ConsumerStatefulWidget {
  const CashbookDashboard({super.key});

  @override
  ConsumerState<CashbookDashboard> createState() => _CashbookDashboardState();
}

class _CashbookDashboardState extends ConsumerState<CashbookDashboard> {
  late List<DateTime> months;

  @override
  void initState() {
    super.initState();
    _generateMonths();
  }

  void _generateMonths() {
    // Generates the last 12 months, ordered oldest to newest.
    final now = DateTime.now();
    months = List.generate(
      12,
      (i) => DateTime(now.year, now.month - i, 1),
    ).reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final summaryList = months
        .map((m) => ref.watch(monthlySummaryProvider(m)))
        .toList();
    final currentYear = DateTime.now().year;
    final annualChartAsync = ref.watch(annualChartProvider(currentYear));

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Cash Book"), // Simplified Title
      ),
      // Use CustomScrollView for a native scroll experience
      child: CustomScrollView(
        slivers: [
          // Header Spacer
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Current Year Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                "$currentYear Overall Summary",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.label,
                ),
              ),
            ),
          ),

          // Total Summary Card (Calculates totals and displays)
          SliverToBoxAdapter(
            child: _DashboardSummaryCard(summaryList: summaryList),
          ),

          // Annual Chart
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 20),
              child: annualChartAsync.when(
                loading: () =>
                    const Center(child: CupertinoActivityIndicator()),
                error: (e, _) => Center(child: Text("Error loading chart: $e")),
                data: (data) {
                  return SizedBox(
                    height: 250,
                    child: AnnualBarLineChart(data: data),
                  );
                },
              ),
            ),
          ),

          // Quick Actions Section (Standard iOS Grouped List)
          SliverList(
            delegate: SliverChildListDelegate([_buildQuickActions(context)]),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // Quick Actions Section (Updated to use CupertinoListSection)
  // ------------------------------------------------------------
  Widget _buildQuickActions(BuildContext context) {
    return CupertinoListSection.insetGrouped(
      header: const Text(
        "QUICK ACTIONS",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      children: [
        // 1. New Cash Entry
        CupertinoListTile(
          title: const Text("New Cash Entry"),
          leading: const Icon(
            CupertinoIcons.add_circled_solid,
            color: CupertinoColors.activeGreen,
          ),
          trailing: const Icon(
            CupertinoIcons
                .chevron_right, // ✅ Correct way to add the trailing arrow
            size: 18, // Adjusted size for a standard look
            color: CupertinoColors
                .systemGrey, // iOS uses a subdued gray for trailing arrows
          ),
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => const AddEntryScreen()),
            );
          },
        ),

        // 2. Full Cashbook List
        CupertinoListTile(
          title: const Text("View Cashbook"),
          leading: const Icon(
            CupertinoIcons.list_bullet,
            color: CupertinoColors.systemBlue,
          ),
          trailing: const Icon(
            CupertinoIcons
                .chevron_right, // ✅ Correct way to add the trailing arrow
            size: 18, // Adjusted size for a standard look
            color: CupertinoColors
                .systemGrey, // iOS uses a subdued gray for trailing arrows
          ),
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => const CashbookScreen()),
            );
          },
        ),

        // 3. Monthly Reports
        CupertinoListTile(
          title: const Text("Monthly Reports"),
          leading: const Icon(
            CupertinoIcons.chart_pie_fill,
            color: CupertinoColors.systemOrange,
          ),
          trailing: const Icon(
            CupertinoIcons
                .chevron_right, // ✅ Correct way to add the trailing arrow
            size: 18, // Adjusted size for a standard look
            color: CupertinoColors
                .systemGrey, // iOS uses a subdued gray for trailing arrows
          ),
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) => const MonthlyLedgerListScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
// Refactored Summary Card (Replaces _buildTotalSummary)
// ------------------------------------------------------------
class _DashboardSummaryCard extends StatelessWidget {
  final List<AsyncValue<MonthlyCashSummary>> summaryList;

  const _DashboardSummaryCard({required this.summaryList});

  Widget _summaryRow(String title, double value, {Color? color}) {
    final effectiveColor =
        color ??
        (value >= 0 ? CupertinoColors.label : CupertinoColors.systemRed);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          Text(
            "₹${value.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: effectiveColor,
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

    for (var item in summaryList) {
      item.whenData((m) {
        totalReceipts += m.receipts;
        totalExpenses += m.expenses;
      });
    }

    final balance = totalReceipts - totalExpenses;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryRow(
              "Total Receipts",
              totalReceipts,
              color: CupertinoColors.activeGreen,
            ),
            const Divider(height: 10, color: CupertinoColors.separator),
            _summaryRow(
              "Total Expenses",
              totalExpenses,
              color: CupertinoColors.systemRed,
            ),
            const Divider(height: 10, color: CupertinoColors.separator),
            _summaryRow(
              "Net Balance",
              balance,
              color: balance >= 0
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.systemRed,
            ),
          ],
        ),
      ),
    );
  }
}
