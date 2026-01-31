import 'package:cashledger/cash_book/by_month/controller/annual_chart_provider.dart';
import 'package:cashledger/cash_book/ui/annual_barline_chart.dart';
import 'package:cashledger/cash_book/ui/cash_book_add_edit_screen.dart';
import 'package:cashledger/cash_book/ui/cash_book_list_screen.dart';
import 'package:cashledger/cash_book/ui/widget/financial_yeaer_selector.dart';
import 'package:cashledger/ledger/ui/monthly_ledger_list_screen.dart';
import 'package:cashledger/user_profile/ui/widget/user_profile_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cashledger/cash_book/by_month/controller/monthly_summary_provider.dart';
import 'package:cashledger/cash_book/by_month/model/monthly_cash_summary.dart';

List<DateTime> generateMonths(int startYear) {
  final endDate = DateTime(startYear, 12, 31); // FY end (India)
  return List.generate(
    12,
    (i) => DateTime(endDate.year, endDate.month - i, 1),
  ).reversed.toList();
}

// Define a common breakpoint for responsiveness
const double kTabletBreakpoint = 800.0;

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
    // _generateMonths();
  }

  List<DateTime> _generateMonths(int startYear) {
    final endDate = DateTime(startYear, 12, 31); // FY end (India)
    return List.generate(
      12,
      (i) => DateTime(endDate.year, endDate.month - i, 1),
    ).reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedYear = ref.watch(yearProvider); // ✅ SAFE HERE

    months = _generateMonths(selectedYear);
    final summaryList = months
        .map((m) => ref.watch(monthlySummaryProvider(m)))
        .toList();
    final currentYear = selectedYear;
    final annualChartAsync = ref.watch(annualChartProvider(currentYear));

    // Check for wide screen
    final isWideScreen = MediaQuery.of(context).size.width >= kTabletBreakpoint;

    final summaryCard = _DashboardSummaryCard();
    final annualChart = SizedBox(
      height: 250,
      child: annualChartAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(child: Text("Error loading chart: $e")),
        data: (data) => AnnualBarLineChart(data: data),
      ),
    );

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text("Cash Book"),
        trailing: SizedBox(
          width: 100,
          child: Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  // ignore: unused_result
                  ref.refresh(annualChartProvider(currentYear));
                },
                child: const Icon(CupertinoIcons.refresh, size: 22),
              ),

              UserProfileButton(),
            ],
          ),
        ),
      ),

      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          // Header Spacer
          //   const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Current Year Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWideScreen ? 30 : 20,
                vertical: 8,
              ),
              child: Row(
                children: [
                  Text(
                    "$currentYear Overall Summary",
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.label,
                    ),
                  ),
                  YearSelector(),
                ],
              ),
            ),
          ),

          // Adaptive Summary and Chart Layout
          SliverToBoxAdapter(
            child: Padding(
              // Adjust padding for wider screens
              padding: EdgeInsets.symmetric(
                horizontal: isWideScreen ? 30 : 16,
                vertical: 8,
              ),
              child: isWideScreen
                  ? _WideLayout(
                      summaryCard: summaryCard,
                      annualChart: annualChart,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Phone/Narrow Layout: Summary Card then Chart
                        summaryCard,
                        Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 20),
                          child: annualChart,
                        ),
                      ],
                    ),
            ),
          ),

          // Quick Actions Section (Standard iOS Grouped List)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isWideScreen ? 14 : 0),
              child: _buildQuickActions(context),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // Quick Actions Section
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
            CupertinoIcons.chevron_right,
            size: 18,
            color: CupertinoColors.systemGrey,
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
            CupertinoIcons.chevron_right,
            size: 18,
            color: CupertinoColors.systemGrey,
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
            CupertinoIcons.chevron_right,
            size: 18,
            color: CupertinoColors.systemGrey,
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
// Wide Layout Widget (For desktop/tablet landscape)
// ------------------------------------------------------------
class _WideLayout extends StatelessWidget {
  final Widget summaryCard;
  final Widget annualChart;

  const _WideLayout({required this.summaryCard, required this.annualChart});

  @override
  Widget build(BuildContext context) {
    // Lay out Summary Card (smaller) and Chart (larger) side-by-side
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Card: Takes up roughly 1/3 of the width
        SizedBox(
          width:
              MediaQuery.of(context).size.width * 0.35 -
              30, // 35% minus padding
          child: summaryCard,
        ),
        const SizedBox(width: 20),

        // Annual Chart: Takes up the remaining space
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 20),
            child: annualChart,
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
// Refactored Summary Card
// ------------------------------------------------------------
class _DashboardSummaryCard extends ConsumerWidget {
  const _DashboardSummaryCard({super.key});

  Widget _summaryRow(
    BuildContext context,
    String title,
    double value, {
    Color? color,
  }) {
    final Color effectiveColor;

    if (color is CupertinoDynamicColor) {
      effectiveColor = color.resolveFrom(context);
    } else {
      effectiveColor =
          color ??
          (value >= 0
              ? CupertinoColors.label.resolveFrom(context)
              : CupertinoColors.systemRed.resolveFrom(context));
    }

    final valueFormatter = NumberFormat('#,##0.00', 'en_US');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          Text(
            "₹${valueFormatter.format(value)}",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: effectiveColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final months = generateMonths(ref.watch(yearProvider));

    double openingBalance = 0;
    double newReceipts = 0;
    double totalExpenses = 0;

    bool openingCaptured = false;

    for (final month in months) {
      final summaryAsync = ref.watch(monthlySummaryProvider(month));

      summaryAsync.whenData((summary) {
        // First (earliest) month defines opening balance
        if (!openingCaptured) {
          openingBalance = summary.openingBalance;
          openingCaptured = true;
        }

        newReceipts += summary.receipts;
        totalExpenses += summary.expenses;
      });
    }

    final totalIncome = openingBalance + newReceipts;
    final netBalance = totalIncome - totalExpenses;

    final cardBackgroundColor = CupertinoColors.systemBackground.resolveFrom(
      context,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey
                .resolveFrom(context)
                .withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summaryRow(
            context,
            "Opening Balance",
            openingBalance,
            color: CupertinoColors.systemCyan,
          ),
          Divider(
            height: 10,
            color: CupertinoColors.separator.resolveFrom(context),
          ),
          _summaryRow(
            context,
            "New Incomes",
            newReceipts,
            color: CupertinoColors.activeGreen,
          ),
          Divider(
            height: 10,
            color: CupertinoColors.separator.resolveFrom(context),
          ),
          _summaryRow(
            context,
            "Total Incomes",
            totalIncome,
            color: CupertinoColors.activeGreen.highContrastColor,
          ),
          Divider(
            height: 10,
            color: CupertinoColors.separator.resolveFrom(context),
          ),
          _summaryRow(
            context,
            "Total Expenses",
            totalExpenses,
            color: CupertinoColors.systemRed,
          ),
          Divider(
            height: 10,
            color: CupertinoColors.separator.resolveFrom(context),
          ),
          _summaryRow(
            context,
            "Net Balance",
            netBalance,
            color: netBalance >= 0
                ? CupertinoColors.activeBlue
                : CupertinoColors.systemRed,
          ),
        ],
      ),
    );
  }
}
