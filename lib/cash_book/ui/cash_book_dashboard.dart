import 'package:cashledger/cash_book/by_month/controller/annual_chart_provider.dart';
import 'package:cashledger/cash_book/ui/annual_barline_chart.dart';
import 'package:cashledger/cash_book/ui/cash_book_add_edit_screen.dart';
import 'package:cashledger/cash_book/ui/cash_book_list_screen.dart';
import 'package:cashledger/cash_book/ui/widget/financial_yeaer_selector.dart';
import 'package:cashledger/ledger/ui/monthly_ledger_list_screen.dart';
import 'package:cashledger/user_profile/ui/widget/user_profile_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cashledger/cash_book/by_month/controller/monthly_summary_provider.dart';

const double kTabletBreakpoint = 800.0;

List<DateTime> generateMonths(int startYear) {
  final endDate = DateTime(startYear, 12, 31);
  return List.generate(
    12,
    (i) => DateTime(endDate.year, endDate.month - i, 1),
  ).reversed.toList();
}

class CashbookDashboard extends ConsumerStatefulWidget {
  const CashbookDashboard({super.key});

  @override
  ConsumerState<CashbookDashboard> createState() =>
      _CashbookDashboardState();
}

class _CashbookDashboardState extends ConsumerState<CashbookDashboard> {
  late List<DateTime> months;

  @override
  void initState() {
    super.initState();
  }

  List<DateTime> _generateMonths(int startYear) {
    final endDate = DateTime(startYear, 12, 31);
    return List.generate(
      12,
      (i) => DateTime(endDate.year, endDate.month - i, 1),
    ).reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedYear = ref.watch(yearProvider);
    months = _generateMonths(selectedYear);
    final currentYear = selectedYear;
    final annualChartAsync = ref.watch(annualChartProvider(currentYear));
    final isWideScreen =
        MediaQuery.of(context).size.width >= kTabletBreakpoint;

    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFFFFFFFF).withValues(alpha: 0.96),
        middle: const Text('Cash Book',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                ref.invalidate(annualChartProvider(currentYear));
              },
              child: const Icon(CupertinoIcons.refresh, size: 22),
            ),
            const SizedBox(width: 4),
            const UserProfileButton(),
          ],
        ),
      ),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
          // ── Year Header with Selector ──
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  isWideScreen ? 30 : 16, 8, isWideScreen ? 30 : 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text("$currentYear Summary",
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C1C1E),
                            letterSpacing: -0.2)),
                  ),
                  const SizedBox(width: 12),
                  const YearSelector(),
                ],
              ),
            ),
          ),

          // ── KPI Summary Cards ──
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isWideScreen ? 30 : 12, vertical: 4),
              child: _DashboardSummaryCards(fmt: fmt),
            ),
          ),

          // ── Annual Chart ──
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isWideScreen ? 30 : 12, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: CupertinoColors.separator
                          .withValues(alpha: 0.3),
                      width: 0.5),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF000000)
                            .withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF007AFF)
                                .withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: const Icon(
                              CupertinoIcons.chart_bar_alt_fill,
                              size: 14,
                              color: Color(0xFF007AFF)),
                        ),
                        const SizedBox(width: 10),
                        const Text('Annual Overview',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1C1C1E),
                                letterSpacing: -0.1)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: annualChartAsync.when(
                        data: (data) => AnnualBarLineChart(data: data),
                        loading: () => const Center(
                            child:
                                CupertinoActivityIndicator(
                                    radius: 16)),
                        error: (e, _) => Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      CupertinoColors.systemRed
                                          .withValues(
                                              alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(
                                          12),
                                ),
                                child: const Icon(
                                    CupertinoIcons
                                        .exclamationmark_triangle,
                                    color:
                                        CupertinoColors.systemRed,
                                    size: 20),
                              ),
                              const SizedBox(height: 8),
                              Text('Chart unavailable',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: CupertinoColors
                                          .secondaryLabel
                                          .resolveFrom(
                                              context))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Quick Actions ──
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isWideScreen ? 14 : 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('Quick Actions',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C1C1E),
                            letterSpacing: -0.1)),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: CupertinoIcons.add_circled_solid,
                          iconColor:
                              CupertinoColors.activeGreen,
                          label: 'New Entry',
                          onTap: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                  builder: (_) =>
                                      const AddEntryScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionCard(
                          icon: CupertinoIcons.list_bullet,
                          iconColor:
                              CupertinoColors.systemBlue,
                          label: 'Cashbook',
                          onTap: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                  builder: (_) =>
                                      const CashbookScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionCard(
                          icon: CupertinoIcons.chart_pie_fill,
                          iconColor:
                              CupertinoColors.systemOrange,
                          label: 'Reports',
                          onTap: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                  builder: (_) =>
                                      const MonthlyLedgerListScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

/// Action card for quick actions row
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: CupertinoColors.separator
                  .withValues(alpha: 0.25),
              width: 0.5),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF000000)
                    .withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1E),
                    letterSpacing: -0.1)),
          ],
        ),
      ),
    );
  }
}

/// Dashboard KPI summary cards
class _DashboardSummaryCards extends ConsumerWidget {
  final NumberFormat fmt;
  const _DashboardSummaryCards({required this.fmt});

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

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                  label: 'Opening Balance',
                  amount: fmt.format(openingBalance),
                  icon: CupertinoIcons.money_dollar_circle,
                  color: const Color(0xFF007AFF)),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _KpiCard(
                  label: 'New Income',
                  amount: fmt.format(newReceipts),
                  icon: CupertinoIcons.arrow_down_left,
                  color: const Color(0xFF34C759)),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _KpiCard(
                  label: 'Total Income',
                  amount: fmt.format(totalIncome),
                  icon: CupertinoIcons.plus_circle,
                  color: const Color(0xFF30B350)),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _KpiCard(
                  label: 'Expenses',
                  amount: fmt.format(totalExpenses),
                  icon: CupertinoIcons.arrow_up_right,
                  color: const Color(0xFFFF3B30)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                  label: 'Net Balance',
                  amount: fmt.format(netBalance),
                  icon: CupertinoIcons.chart_bar_circle_fill,
                  color: netBalance >= 0
                      ? const Color(0xFF007AFF)
                      : const Color(0xFFFF3B30)),
            ),
            const SizedBox(width: 6),
            Expanded(child: const SizedBox.shrink()),
            const SizedBox(width: 6),
            Expanded(child: const SizedBox.shrink()),
            const SizedBox(width: 6),
            Expanded(child: const SizedBox.shrink()),
          ],
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color color;
  const _KpiCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: CupertinoColors.separator
                .withValues(alpha: 0.25),
            width: 0.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF000000)
                  .withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(7)),
                child: Icon(icon, size: 12, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF8E8E93),
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1)),
          const SizedBox(height: 1),
          Text(amount,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: -0.3)),
        ],
      ),
    );
  }
}