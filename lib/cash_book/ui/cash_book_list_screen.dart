import 'package:cashledger/cash_book/controller/cash_book_controller.dart';
import 'package:cashledger/cash_book/controller/cash_book_filter.dart';
import 'package:cashledger/cash_book/controller/cash_book_group_provider.dart';
import 'package:cashledger/cash_book/ui/widget/financial_yeaer_selector.dart';
import 'package:cashledger/export/export_utility.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'cash_book_add_edit_screen.dart';

class CashbookScreen extends ConsumerStatefulWidget {
  const CashbookScreen({super.key});

  @override
  ConsumerState<CashbookScreen> createState() => _CashbookScreenState();
}

class _CashbookScreenState extends ConsumerState<CashbookScreen> {
  final DateFormat monthHeaderFormat = DateFormat('MMMM yyyy');
  final DateFormat rowDateFormat = DateFormat('dd MMM yyyy');
  final NumberFormat _amountFormat = NumberFormat('#,##,##0.00', 'en_IN');

  String _monthLabelFromKey(String key) {
    final parts = key.split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    return monthHeaderFormat.format(DateTime(y, m));
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(entriesListProvider);

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFFFFFFFF)
            .withValues(alpha: 0.96),
        middle: const Text('Cash Book',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const YearSelector(),
            const SizedBox(width: 4),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.arrow_counterclockwise,
                  size: 22, color: Color(0xFF007AFF)),
              onPressed: () => ref.invalidate(entriesListProvider),
            ),
            const SizedBox(width: 4),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF007AFF).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(CupertinoIcons.add, size: 18,
                    color: CupertinoColors.white),
              ),
              onPressed: () => Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => const AddEntryScreen()),
              ),
            ),
          ],
        ),
      ),
      child: entriesAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(CupertinoIcons.exclamationmark_triangle,
                    size: 28, color: Color(0xFFFF3B30)),
              ),
              const SizedBox(height: 16),
              const Text('Failed to load entries',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C1E))),
              const SizedBox(height: 4),
              const Text('Please check your connection and try again',
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8E8E93))),
              const SizedBox(height: 16),
              CupertinoButton.filled(
                onPressed: () => ref.invalidate(entriesListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (entries) => _buildContent(context, ref, entries),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref,
      List<Map<String, dynamic>> entries) {
    final grouped = ref.watch(groupedEntriesProvider);
    final totals = ref.watch(monthlyTotalsProvider);

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(CupertinoIcons.doc_text, size: 34,
                  color: CupertinoColors.white),
            ),
            const SizedBox(height: 20),
            const Text('No Entries Yet',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C1C1E))),
            const SizedBox(height: 6),
            const Text('Start tracking by adding your first entry',
                style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8E8E93))),
          ],
        ),
      );
    }

    // Compute year-to-date totals
    double ytdReceipts = 0;
    double ytdExpenses = 0;
    for (final e in entries) {
      final amt = (e['amount'] ?? 0).toDouble();
      if (e['type'] == 'debit') {
        ytdReceipts += amt;
      } else {
        ytdExpenses += amt;
      }
    }
    final ytdBalance = ytdReceipts - ytdExpenses;

    return CustomScrollView(
      slivers: [
         SliverToBoxAdapter(
          child: SizedBox(height: 50),
        ),
        // Year-to-date KPI cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: _KpiCard(
                    label: 'Total Receipts',
                    amount: ytdReceipts,
                    color: const Color(0xFF34C759),
                    icon: CupertinoIcons.arrow_down_left_circle_fill,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _KpiCard(
                    label: 'Total Expenses',
                    amount: ytdExpenses,
                    color: const Color(0xFFFF3B30),
                    icon: CupertinoIcons.arrow_up_right_circle_fill,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _KpiCard(
                    label: 'Balance',
                    amount: ytdBalance,
                    color: ytdBalance >= 0
                        ? const Color(0xFF007AFF)
                        : const Color(0xFFFF3B30),
                    icon: CupertinoIcons.chart_bar_circle_fill,
                    isBalance: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Search + filter bar
        SliverToBoxAdapter(child: _buildSearchFilterBar(context, ref)),
        // Monthly sections
        for (final section in grouped.entries) ...[
          SliverPersistentHeader(
            pinned: true,
            delegate: _MonthHeaderDelegate(
              monthKey: section.key,
              totals: totals[section.key] ?? const {},
              height: 48,
              monthLabel: _monthLabelFromKey(section.key),
              entries: section.value,
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final e = section.value[i];
                final isDebit = e['type'] == 'debit';
                final isFirst = i == 0;
                final isLast = i == section.value.length - 1;
                return Container(
                  margin: EdgeInsets.fromLTRB(
                    12,
                    isFirst ? 4 : 0,
                    12,
                    isLast ? 8 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: isFirst ? const Radius.circular(12) : Radius.zero,
                      topRight: isFirst ? const Radius.circular(12) : Radius.zero,
                      bottomLeft: isLast ? const Radius.circular(12) : Radius.zero,
                      bottomRight: isLast ? const Radius.circular(12) : Radius.zero,
                    ),
                    border: Border(
                      left: BorderSide(
                          color: CupertinoColors.separator.withValues(alpha: 0.4),
                          width: 0.5),
                      right: BorderSide(
                          color: CupertinoColors.separator.withValues(alpha: 0.4),
                          width: 0.5),
                      bottom: BorderSide(
                          color: CupertinoColors.separator.withValues(alpha: 0.4),
                          width: 0.5),
                    ),
                  ),
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    borderRadius: BorderRadius.zero,
                    onPressed: () => Navigator.push(
                      context,
                      CupertinoPageRoute(
                          builder: (_) => AddEntryScreen(entry: e)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDebit
                                ? const Color(0xFF34C759)
                                    .withValues(alpha: 0.1)
                                : const Color(0xFFFF3B30)
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isDebit
                                ? CupertinoIcons.arrow_down_left
                                : CupertinoIcons.arrow_up_right,
                            size: 18,
                            color: isDebit
                                ? const Color(0xFF34C759)
                                : const Color(0xFFFF3B30),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e['description'] ?? 'No description',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1C1C1E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${rowDateFormat.format(DateTime.parse(e['date']))} · ${e['accounts']?['name'] ?? 'Unknown'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          isDebit ? '+ ₹' : '- ₹',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDebit
                                ? const Color(0xFF34C759)
                                : const Color(0xFFFF3B30),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _amountFormat.format(e['amount'] ?? 0),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDebit
                                ? const Color(0xFF34C759)
                                : const Color(0xFFFF3B30),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(CupertinoIcons.chevron_right,
                            size: 14, color: Color(0xFFC7C7CC)),
                      ],
                    ),
                  ),
                );
              },
              childCount: section.value.length,
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _buildSearchFilterBar(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: CupertinoColors.separator.withValues(alpha: 0.3),
                    width: 0.5),
              ),
              child: CupertinoSearchTextField(
                placeholder: 'Search entries...',
                backgroundColor: CupertinoColors.transparent,
                style: const TextStyle(fontSize: 14),
                onChanged: (v) =>
                    ref.read(cashbookFilterProvider.notifier).setSearch(v),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: CupertinoColors.separator.withValues(alpha: 0.3),
                  width: 0.5),
            ),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: const Icon(CupertinoIcons.sort_down, size: 20,
                  color: Color(0xFF007AFF)),
              onPressed: () => _openSortSheet(context, ref),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: CupertinoColors.separator.withValues(alpha: 0.3),
                  width: 0.5),
            ),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: const Icon(CupertinoIcons.slider_horizontal_3, size: 20,
                  color: Color(0xFF007AFF)),
              onPressed: () => _openFilterSheet(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  void _openSortSheet(BuildContext context, WidgetRef ref) {
    final filter = ref.read(cashbookFilterProvider);
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Sort By'),
        actions: [
          _sortAction(
              context, ref, 'date_desc', filter.sort == 'date_desc',
              'Date (Newest First)'),
          _sortAction(
              context, ref, 'date_asc', filter.sort == 'date_asc',
              'Date (Oldest First)'),
          _sortAction(
              context, ref, 'amount_desc', filter.sort == 'amount_desc',
              'Amount (High to Low)'),
          _sortAction(
              context, ref, 'amount_asc', filter.sort == 'amount_asc',
              'Amount (Low to High)'),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _openFilterSheet(BuildContext context, WidgetRef ref) {
    final filter = ref.read(cashbookFilterProvider);
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Filter Entry Type'),
        message: CupertinoSegmentedControl(
          groupValue: filter.type,
          children: const {
            'all': Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Text('All'),
            ),
            'debit': Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Text('Receipts'),
            ),
            'credit': Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Text('Expenses'),
            ),
          },
          onValueChanged: (v) {
            ref.read(cashbookFilterProvider.notifier).setType(v);
            Navigator.pop(context);
          },
        ),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              ref.read(cashbookFilterProvider.notifier).clearFilters();
              Navigator.pop(context);
            },
            child: const Text('Clear Filters'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ),
    );
  }

  CupertinoActionSheetAction _sortAction(BuildContext context, WidgetRef ref,
      String value, bool selected, String label) {
    return CupertinoActionSheetAction(
      onPressed: () {
        ref.read(cashbookFilterProvider.notifier).setSort(value);
        Navigator.pop(context);
      },
      child: Text(
        selected ? '✓  $label' : label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

// ============================================================
// KPI CARD
// ============================================================
class _KpiCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final bool isBalance;

  const _KpiCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    this.isBalance = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: CupertinoColors.separator.withValues(alpha: 0.3),
            width: 0.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const Spacer(),
              if (isBalance)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    amount >= 0 ? 'NET' : 'DEF',
                    style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 0.5),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8E8E93),
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1)),
          const SizedBox(height: 2),
          Text(
            '₹ ${NumberFormat('#,##,###').format(amount.round())}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MONTH HEADER DELEGATE
// ============================================================
class _MonthHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String monthKey;
  final Map<String, double> totals;
  final double height;
  final String monthLabel;
  final List<Map<String, dynamic>> entries;

  _MonthHeaderDelegate({
    required this.monthKey,
    required this.totals,
    required this.height,
    required this.monthLabel,
    required this.entries,
  });

  final NumberFormat _fmt = NumberFormat('#,##,##0', 'en_IN');

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final openingBalance = totals['openingBalance'] ?? 0.0;
    final receipts = totals['receipts'] ?? 0.0;
    final expenses = totals['expenses'] ?? 0.0;
    final balance = totals['balance'] ?? 0.0;
    final dateFmt = DateFormat('MMMM yyyy').format(
        DateTime.parse('$monthKey-01'));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: const BoxDecoration(
        color: Color(0xFFF2F2F7),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(dateFmt,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C1C1E),
                  letterSpacing: -0.2)),
          const Spacer(),
          _statChip('Open', openingBalance, const Color(0xFF8E8E93)),
          const SizedBox(width: 6),
          _statChip('R', receipts, const Color(0xFF34C759)),
          const SizedBox(width: 6),
          _statChip('E', expenses, const Color(0xFFFF3B30)),
          const SizedBox(width: 6),
          _statChip('Bal', balance,
              balance >= 0 ? const Color(0xFF007AFF) : const Color(0xFFFF3B30),
              bold: true),
          const SizedBox(width: 2),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => ExportUtils.openDirectExport(
              context: context,
              entries: entries,
              openingBl: openingBalance,
            ),
            child: const Icon(CupertinoIcons.square_arrow_up,
                size: 18, color: Color(0xFF8E8E93)),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, double value, Color color,
      {bool bold = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label ',
            style: TextStyle(
                fontSize: 10,
                color: const Color(0xFF8E8E93).withValues(alpha: 0.8),
                fontWeight: FontWeight.w500)),
        Text(
          _fmt.format(value),
          style: TextStyle(
            fontSize: 10,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  double get maxExtent => height;
  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _MonthHeaderDelegate old) =>
      old.monthKey != monthKey || old.totals != totals;
}