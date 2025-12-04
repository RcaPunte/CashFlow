import 'dart:collection';
import 'package:cashledger/cash_book/controller/cash_book_controller.dart';
import 'package:cashledger/cash_book/controller/cash_book_filter.dart';
import 'package:cashledger/cash_book/controller/cash_book_group_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';

import 'cash_book_add_edit_screen.dart';

class CashbookScreen extends ConsumerStatefulWidget {
  const CashbookScreen({super.key});

  @override
  ConsumerState<CashbookScreen> createState() => _CashbookScreenState();
}

class _CashbookScreenState extends ConsumerState<CashbookScreen> {
  final DateFormat monthHeaderFormat = DateFormat('MMMM yyyy');
  final DateFormat rowDateFormat = DateFormat('dd MMM yyyy');

  // CSV builder
  List<List<dynamic>> _buildCsvRows(
    LinkedHashMap<String, List<Map<String, dynamic>>> grouped,
    Map<String, Map<String, double>> totals,
  ) {
    final rows = <List<dynamic>>[];
    rows.add(['Month', 'Date', 'Description', 'Account', 'Type', 'Amount']);
    grouped.forEach((monthKey, list) {
      final parts = monthKey.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final monthLabel = DateFormat('MMMM yyyy').format(DateTime(year, month));

      rows.add([monthLabel, '', '', '', '', '']);
      for (var e in list) {
        rows.add([
          monthLabel,
          e['date'],
          e['description'] ?? '',
          e['accounts']?['name'] ?? '',
          e['type'],
          (e['amount'] ?? 0).toString(),
        ]);
      }
      final t = totals[monthKey]!;
      rows.add([
        monthLabel,
        'Monthly Receipts',
        '',
        '',
        '',
        t['receipts']!.toStringAsFixed(2),
      ]);
      rows.add([
        monthLabel,
        'Monthly Expenses',
        '',
        '',
        '',
        t['expenses']!.toStringAsFixed(2),
      ]);
      rows.add([
        monthLabel,
        'Monthly Balance',
        '',
        '',
        '',
        t['balance']!.toStringAsFixed(2),
      ]);
      rows.add([]);
    });
    return rows;
  }

  Future<void> _exportCsvFromGrouped(
    LinkedHashMap<String, List<Map<String, dynamic>>> grouped,
    Map<String, Map<String, double>> totals,
  ) async {
    final rows = _buildCsvRows(grouped, totals);
    final csv = const ListToCsvConverter().convert(rows);
    await Share.share(csv, subject: 'Cashbook Export');
  }

  String _monthLabelFromKey(String key) {
    final parts = key.split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    return monthHeaderFormat.format(DateTime(y, m));
  }

  @override
  Widget build(BuildContext context) {
    final grouped = ref.watch(groupedEntriesProvider);
    final totals = ref.watch(monthlyTotalsProvider);
    final entriesAsync = ref.watch(entriesListProvider);
    final filter = ref.watch(cashbookFilterProvider);

    // overall summary computed from entries provider (safe because entriesListProvider watched above)
    final entries = entriesAsync.asData?.value ?? [];
    final totalReceipts = entries
        .where((e) => e['type'] == 'debit')
        .fold(0.0, (s, e) => s + (e['amount'] ?? 0).toDouble());
    final totalExpenses = entries
        .where((e) => e['type'] == 'credit')
        .fold(0.0, (s, e) => s + (e['amount'] ?? 0).toDouble());
    final balance = totalReceipts - totalExpenses;

    return Material(
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Cashbook'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // CupertinoButton(
              //   padding: EdgeInsets.zero,
              //   child: const Icon(CupertinoIcons.square_arrow_up),
              //   onPressed: () => _exportCsvFromGrouped(grouped, totals),
              // ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.add),
                onPressed: () => Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const AddEntryScreen()),
                ),
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // summary
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _summaryItem(
                        'Receipts',
                        totalReceipts,
                        CupertinoColors.activeGreen,
                      ),
                      _summaryItem(
                        'Expenses',
                        totalExpenses,
                        CupertinoColors.destructiveRed,
                      ),
                      _summaryItem(
                        'Balance',
                        balance,
                        CupertinoColors.activeBlue,
                      ),
                    ],
                  ),
                ),
              ),

              // search + controls
              _buildSearchFilterBar(context, ref),

              // list
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    for (final section in grouped.entries) ...[
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _MonthHeaderDelegate(
                          monthKey: section.key,
                          totals: totals[section.key]!,
                          height: 60,
                          monthLabel: _monthLabelFromKey(section.key),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate((ctx, index) {
                          final e = section.value[index];
                          return CupertinoListTile(
                            leading: Icon(
                              e['type'] == 'debit'
                                  ? CupertinoIcons.arrow_down_circle
                                  : CupertinoIcons.arrow_up_circle,
                              color: e['type'] == 'debit'
                                  ? CupertinoColors.activeGreen
                                  : CupertinoColors.destructiveRed,
                            ),
                            title: Text(e['description'] ?? 'No description'),
                            subtitle: Text(
                              '${e['date']} • ${e['accounts']?['name'] ?? 'Unknown'}',
                            ),
                            trailing: Text(
                              '₹${(e['amount'] ?? 0).toString()}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: e['type'] == 'debit'
                                    ? CupertinoColors.activeGreen
                                    : CupertinoColors.destructiveRed,
                              ),
                            ),
                            onTap: () => Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (_) => AddEntryScreen(entry: e),
                              ),
                            ),
                          );
                        }, childCount: section.value.length),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchFilterBar(BuildContext context, WidgetRef ref) {
    // final filter = ref.watch(cashbookFilterProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: CupertinoSearchTextField(
            placeholder: 'Search description, amount, date, account...',
            onChanged: (v) =>
                ref.read(cashbookFilterProvider.notifier).setSearch(v),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CupertinoButton(
              child: Row(
                children: [
                  const Text('Sort'),
                  SizedBox(width: 10),
                  Icon(CupertinoIcons.sort_down),
                ],
              ),
              onPressed: () => _openSortSheet(context, ref),
            ),
            CupertinoButton(
              child: Row(
                children: [
                  const Text('Filter'),
                  SizedBox(width: 10),
                  Icon(CupertinoIcons.slider_horizontal_3),
                ],
              ),
              onPressed: () => _openFilterSheet(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  void _openSortSheet(BuildContext context, WidgetRef ref) {
    final filter = ref.read(cashbookFilterProvider);

    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Sort By'),
        actions: [
          _sortAction(ref, 'date_desc', filter.sort == 'date_desc', 'Date ↓'),
          _sortAction(ref, 'date_asc', filter.sort == 'date_asc', 'Date ↑'),
          _sortAction(
            ref,
            'amount_desc',
            filter.sort == 'amount_desc',
            'Amount ↓',
          ),
          _sortAction(
            ref,
            'amount_asc',
            filter.sort == 'amount_asc',
            'Amount ↑',
          ),
          _sortAction(
            ref,
            'desc_asc',
            filter.sort == 'desc_asc',
            'Description A→Z',
          ),
          _sortAction(
            ref,
            'desc_desc',
            filter.sort == 'desc_desc',
            'Description Z→A',
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  CupertinoActionSheetAction _sortAction(
    WidgetRef ref,
    String value,
    bool selected,
    String label,
  ) {
    return CupertinoActionSheetAction(
      onPressed: () {
        ref.read(cashbookFilterProvider.notifier).setSort(value);
        Navigator.pop(ref.context);
      },
      child: Text(
        selected ? '✓ $label' : label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  void _openFilterSheet(BuildContext context, WidgetRef ref) {
    final filter = ref.read(cashbookFilterProvider);

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Material(
        child: Container(
          width: double.infinity,
          color: CupertinoColors.systemBackground,
          height: 380,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text(
                'Filter',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              CupertinoSegmentedControl(
                groupValue: filter.type,
                children: const {
                  'all': Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('All'),
                  ),
                  'debit': Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('Receipt'),
                  ),
                  'credit': Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('Expense'),
                  ),
                },
                onValueChanged: (v) =>
                    ref.read(cashbookFilterProvider.notifier).setType(v),
              ),
              const SizedBox(height: 12),
              CupertinoButton(
                child: Text(
                  filter.fromDate == null
                      ? 'From Date'
                      : 'From: ${DateFormat('dd MMM yyyy').format(filter.fromDate!)}',
                ),
                onPressed: () async {
                  final picked = await showCupertinoModalPopup<DateTime>(
                    context: context,
                    builder: (_) => SizedBox(
                      height: 260,
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.date,
                        initialDateTime: filter.fromDate ?? DateTime.now(),
                        onDateTimeChanged: (d) => ref
                            .read(cashbookFilterProvider.notifier)
                            .setFromDate(d),
                      ),
                    ),
                  );
                  // popup returns nothing; setFromDate handled on change
                },
              ),
              CupertinoButton(
                child: Text(
                  filter.toDate == null
                      ? 'To Date'
                      : 'To: ${DateFormat('dd MMM yyyy').format(filter.toDate!)}',
                ),
                onPressed: () async {
                  final picked = await showCupertinoModalPopup<DateTime>(
                    context: context,
                    builder: (_) => SizedBox(
                      height: 260,
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.date,
                        initialDateTime: filter.toDate ?? DateTime.now(),
                        onDateTimeChanged: (d) => ref
                            .read(cashbookFilterProvider.notifier)
                            .setToDate(d),
                      ),
                    ),
                  );
                },
              ),
              const Spacer(),
              CupertinoButton.filled(
                child: const Text('Clear Filters'),
                onPressed: () {
                  ref.read(cashbookFilterProvider.notifier).clearFilters();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryItem(String title, double value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        Text(
          '₹${value.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// Sticky header delegate
class _MonthHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String monthKey;
  final Map<String, double> totals;
  final double height;
  final String monthLabel;

  _MonthHeaderDelegate({
    required this.monthKey,
    required this.totals,
    required this.height,
    required this.monthLabel,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: CupertinoColors.systemGrey6,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Expanded(
            child: Text(
              monthLabel,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Text(
            'R: ₹${totals['receipts']!.toStringAsFixed(2)}',
            style: const TextStyle(color: CupertinoColors.activeGreen),
          ),
          const SizedBox(width: 12),
          Text(
            'E: ₹${totals['expenses']!.toStringAsFixed(2)}',
            style: const TextStyle(color: CupertinoColors.destructiveRed),
          ),
          const SizedBox(width: 12),
          Text('B: ₹${totals['balance']!.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  @override
  double get maxExtent => height;
  @override
  double get minExtent => height;
  @override
  bool shouldRebuild(covariant _MonthHeaderDelegate oldDelegate) {
    return oldDelegate.monthKey != monthKey ||
        oldDelegate.totals != totals ||
        oldDelegate.monthLabel != monthLabel;
  }
}
