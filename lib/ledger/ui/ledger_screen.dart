import 'package:cashledger/account/model/account_model.dart';
import 'package:cashledger/ledger/controller/ledger_controller.dart';
import 'package:cashledger/ledger/export/ledger_export_button.dart';
import 'package:cashledger/ledger/model/ledger_entry.dart';
import 'package:cashledger/ledger/ui/widgets/ledger_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

enum LedgerViewMode { grouped, flat }

enum DateSortOrder { newestFirst, oldestFirst }

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});
  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  String selectedAccountId = '';
  String selectedAccountName = 'All Accounts';
  LedgerViewMode viewMode = LedgerViewMode.grouped;
  DateSortOrder sortOrder = DateSortOrder.newestFirst;
  late DateTime from;
  late DateTime to;
  final DateFormat _monthFormat = DateFormat('MMMM yyyy');
  final DateFormat _shortDateFormat = DateFormat('MMM d, yy');
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    from = DateTime(now.year, now.month, 1);
    to = DateTime(now.year, now.month + 1, 0);
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    ref.read(ledgerControllerProvider.notifier).fetchLedger(
          from: from,
          to: to,
          accountId: selectedAccountId.isEmpty ? null : selectedAccountId,
        );
  }

  Map<String, double> _calculateTotals(List<LedgerEntry> entries) {
    double receipts = 0;
    double expenses = 0;
    for (final e in entries) {
      if (e.type == 'debit') {
        receipts += e.amount;
      } else {
        expenses += e.amount;
      }
    }
    return {'receipts': receipts, 'expenses': expenses};
  }

  @override
  Widget build(BuildContext context) {
    final ledgerAsync = ref.watch(ledgerControllerProvider);
    final accountsAsync = ref.watch(accountListProvider);

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor:
            const Color(0xFFFFFFFF).withValues(alpha: 0.96),
        middle: const Text('Ledger',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ledgerAsync.when(
              data: (state) => ledgerExportButton(
                context: context,
                openingBalance: state.openingBalance,
                entries: state.entries,
              ),
              error: (_, __) => const SizedBox(),
              loading: () => const SizedBox(),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _applyFilters,
              child: const Icon(CupertinoIcons.arrow_counterclockwise,
                  size: 22, color: Color(0xFF007AFF)),
            ),
          ],
        ),
      ),
      child: ledgerAsync.when(
        loading: () =>
            const Center(child: CupertinoActivityIndicator(radius: 18)),
        error: (e, _) => Center(
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
              Text(
                e.toString().length > 60
                    ? '${e.toString().substring(0, 60)}...'
                    : e.toString(),
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF8E8E93)),
              ),
            ],
          ),
        ),
        data: (ledgerState) {
          final entries = [...ledgerState.entries];
          entries.sort(
            (a, b) => sortOrder == DateSortOrder.newestFirst
                ? b.date.compareTo(a.date)
                : a.date.compareTo(b.date),
          );
          final totals = _calculateTotals(entries);

          return CupertinoScrollbar(
            controller: _scrollController,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                   SliverToBoxAdapter(
                  child:SizedBox(height: 50),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildFilterBar(accountsAsync),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: _KpiTile(
                            label: 'Receipts',
                            amount: totals['receipts']!,
                            color: const Color(0xFF34C759),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _KpiTile(
                            label: 'Expenses',
                            amount: totals['expenses']!,
                            color: const Color(0xFFFF3B30),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12)),
                    ),
                    child: LedgerRowHeaderWidget(),
                  ),
                ),
                if (viewMode == LedgerViewMode.flat)
                  _buildFlatList(entries, ledgerState.openingBalance)
                else
                  ..._buildGrouped(entries, ledgerState.openingBalance),
                const SliverToBoxAdapter(child: SizedBox(height: 60)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(AsyncValue<List<AccountModel>> accountsAsync) {
    return Container(
      color: CupertinoColors.systemGroupedBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _accountSelector(accountsAsync),
              const SizedBox(width: 8),
              _dateButton('From', from, (d) {
                ref.read(selectedLedgerFromYear.notifier).state = d.year;
                setState(() => from = d);
                _applyFilters();
              }),
              const SizedBox(width: 8),
              _dateButton('To', to, (d) {
                ref.read(selectedLedgerToYear.notifier).state = d.year;
                setState(() => to = d);
                _applyFilters();
              }),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 4),
              CupertinoSegmentedControl<LedgerViewMode>(
                groupValue: viewMode,
                padding: EdgeInsets.zero,
                children: const {
                  LedgerViewMode.grouped: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text('Monthly'),
                  ),
                  LedgerViewMode.flat: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text('All'),
                  ),
                },
                onValueChanged: (v) => setState(() => viewMode = v),
              ),
              const SizedBox(width: 20),
              CupertinoSegmentedControl<DateSortOrder>(
                groupValue: sortOrder,
                padding: EdgeInsets.zero,
                children: const {
                  DateSortOrder.newestFirst: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text('Newest'),
                  ),
                  DateSortOrder.oldestFirst: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text('Oldest'),
                  ),
                },
                onValueChanged: (v) => setState(() => sortOrder = v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _accountSelector(AsyncValue<List<AccountModel>> accountsAsync) {
    return accountsAsync.when(
      loading: () => const CupertinoActivityIndicator(),
      error: (_, __) => const Text('Error'),
      data: (accounts) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _showAccountPicker(context, accounts),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: CupertinoColors.separator.withValues(alpha: 0.3),
                width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.folder, size: 16,
                  color: Color(0xFF007AFF)),
              const SizedBox(width: 6),
              Text(selectedAccountName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(width: 6),
              const Icon(CupertinoIcons.chevron_down, size: 14,
                  color: Color(0xFF8E8E93)),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccountPicker(BuildContext context, List<AccountModel> accounts) {
    int selectedIndex = selectedAccountId.isEmpty
        ? 0
        : accounts.indexWhere((a) => a.id == selectedAccountId) + 1;

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 320,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text('Select Account',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                CupertinoButton(
                  child: const Text('Done',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    setState(() {
                      if (selectedIndex == 0) {
                        selectedAccountId = '';
                        selectedAccountName = 'All Accounts';
                      } else {
                        final acc = accounts[selectedIndex - 1];
                        selectedAccountId = acc.id;
                        selectedAccountName = acc.name;
                      }
                    });
                    _applyFilters();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 36,
                scrollController:
                    FixedExtentScrollController(initialItem: selectedIndex),
                onSelectedItemChanged: (i) => selectedIndex = i,
                children: [
                  const Center(child: Text('All Accounts')),
                  ...accounts.map((a) => Center(child: Text(a.name))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverList _buildFlatList(
      List<LedgerEntry> entries, double opening) {
    double balance = opening;
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final e = entries[index];
        balance += e.type == 'debit' ? e.amount : -e.amount;
        final isLast = index == entries.length - 1;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: isLast
                  ? BorderSide.none
                  : BorderSide(
                      color: CupertinoColors.separator
                          .withValues(alpha: 0.3),
                      width: 0.5),
            ),
          ),
          child: LedgerRowWidget(entry: e, runningBalance: balance),
        );
      }, childCount: entries.length),
    );
  }

  List<Widget> _buildGrouped(
      List<LedgerEntry> entries, double openingBalance) {
    final Map<String, List<LedgerEntry>> grouped = {};
    for (final e in entries) {
      final key = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(e);
    }
    final keys = grouped.keys.toList()
      ..sort(
        (a, b) => sortOrder == DateSortOrder.newestFirst
            ? b.compareTo(a)
            : a.compareTo(b),
      );

    double running = openingBalance;
    final slivers = <Widget>[];

    for (final k in keys) {
      final monthEntries = grouped[k]!;
      final label = _monthFormat.format(
        DateTime(int.parse(k.split('-')[0]), int.parse(k.split('-')[1])),
      );

      slivers.add(
        SliverPersistentHeader(
          pinned: true,
          delegate: _MonthHeaderDelegate(
            monthLabel: label,
            totalIn: monthEntries
                .where((e) => e.type == 'debit')
                .fold(0, (a, b) => a + b.amount),
            totalOut: monthEntries
                .where((e) => e.type == 'credit')
                .fold(0, (a, b) => a + b.amount),
          ),
        ),
      );

      slivers.add(
        SliverList.builder(
          itemCount: monthEntries.length,
          itemBuilder: (_, i) {
            final e = monthEntries[i];
            running += e.type == 'debit' ? e.amount : -e.amount;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              child: LedgerRowWidget(
                entry: e,
                runningBalance: running,
              ),
            );
          },
        ),
      );
    }
    return slivers;
  }

  Widget _dateButton(
      String label, DateTime date, ValueChanged<DateTime> onChanged) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _pickDate(date, onChanged),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: CupertinoColors.separator.withValues(alpha: 0.3),
              width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.calendar, size: 14,
                color: Color(0xFF8E8E93)),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF8E8E93))),
                Text(_shortDateFormat.format(date),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _pickDate(DateTime initial, ValueChanged<DateTime> onChanged) {
    DateTime temp = initial;
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  child: const Text('Done'),
                  onPressed: () {
                    onChanged(temp);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initial,
                onDateTimeChanged: (d) => temp = d,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _KpiTile({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
      child: Row(
        children: [
          Container(
            width: 10,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8E8E93),
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(
                '₹ ${NumberFormat('#,##,###').format(amount.round())}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String monthLabel;
  final double totalIn;
  final double totalOut;
  final NumberFormat _fmt = NumberFormat('#,##,##0', 'en_IN');

  _MonthHeaderDelegate({
    required this.monthLabel,
    required this.totalIn,
    required this.totalOut,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(
      color: const Color(0xFFF2F2F7),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Text(monthLabel,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C1C1E),
                  letterSpacing: -0.2)),
          const Spacer(),
          _chip('In', totalIn, const Color(0xFF34C759)),
          const SizedBox(width: 10),
          _chip('Out', totalOut, const Color(0xFFFF3B30)),
        ],
      ),
    );
  }

  Widget _chip(String label, double value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label ',
            style: TextStyle(
                fontSize: 11,
                color: const Color(0xFF8E8E93).withValues(alpha: 0.8))),
        Text('₹${_fmt.format(value)}',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color)),
      ],
    );
  }

  @override
  double get maxExtent => 40;
  @override
  double get minExtent => 40;

  @override
  bool shouldRebuild(covariant _MonthHeaderDelegate old) =>
      old.monthLabel != monthLabel ||
      old.totalIn != totalIn ||
      old.totalOut != totalOut;
}