import 'package:cashledger/account/model/account_model.dart';
import 'package:cashledger/ledger/controller/ledger_controller.dart';
import 'package:cashledger/ledger/export/ledger_export_button.dart';
import 'package:cashledger/ledger/model/ledger_entry.dart';
import 'package:cashledger/ledger/ui/widgets/ledger_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    from = DateTime(now.year, now.month, 1);
    to = DateTime(now.year, now.month + 1, 0);
  }

  void _applyFilters() {
    ref
        .read(ledgerControllerProvider.notifier)
        .fetchLedger(
          from: from,
          to: to,
          accountId: selectedAccountId.isEmpty ? null : selectedAccountId,
        );
  }

  /// ------------------------------------------------------------
  /// TOTAL CALCULATION
  /// ------------------------------------------------------------
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
    final scrollController = ScrollController();

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Ledger'),
        trailing: SizedBox(
          width: 200,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ledgerAsync.when(
                data: (state) => ledgerExportButton(
                  context: context,
                  openingBalance: ledgerAsync.value != null
                      ? ledgerAsync.value!.openingBalance
                      : 0,
                  entries: ledgerAsync.value!.entries,
                ),
                error: (e, a) => SizedBox(),
                loading: () => SizedBox(),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _applyFilters,
                child: const Icon(CupertinoIcons.arrow_clockwise),
              ),
            ],
          ),
        ),
      ),
      child: SafeArea(
        child: ledgerAsync.when(
          loading: () =>
              const Center(child: CupertinoActivityIndicator(radius: 18)),
          error: (e, _) => Center(child: Text('$e')),
          data: (ledgerState) {
            final entries = [...ledgerState.entries];

            entries.sort(
              (a, b) => sortOrder == DateSortOrder.newestFirst
                  ? b.date.compareTo(a.date)
                  : a.date.compareTo(b.date),
            );

            final totals = _calculateTotals(entries);

            return CupertinoScrollbar(
              controller: scrollController,
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  SliverToBoxAdapter(child: _buildFilterBar(accountsAsync)),

                  /// 🔹 OVERALL SUMMARY
                  SliverToBoxAdapter(
                    child: _buildTotalsSummary(
                      totals['receipts']!,
                      totals['expenses']!,
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 10)),
                  SliverToBoxAdapter(child: LedgerRowHeaderWidget()),

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
      ),
    );
  }

  /// ------------------------------------------------------------
  /// FILTER BAR
  /// ------------------------------------------------------------
  Widget _buildFilterBar(AsyncValue<List<AccountModel>> accountsAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: CupertinoColors.systemGroupedBackground,
      child: Column(
        children: [
          Row(
            children: [
              _accountSelector(accountsAsync),
              Spacer(),
              Row(
                children: [
                  _dateButton('From', from, (d) {
                    ref.watch(selectedLedgerFromYear.notifier).state = d.year;
                    setState(() => from = d);
                    _applyFilters();
                  }),
                  const SizedBox(width: 8),
                  _dateButton('To', to, (d) {
                    ref.watch(selectedLedgerToYear.notifier).state = d.year;
                    setState(() => to = d);
                    _applyFilters();
                  }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CupertinoSegmentedControl<LedgerViewMode>(
                groupValue: viewMode,
                padding: EdgeInsets.zero,
                children: const {
                  LedgerViewMode.grouped: Padding(
                    padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
                    child: Text('Monthly'),
                  ),
                  LedgerViewMode.flat: Padding(
                    padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
                    child: Text('All'),
                  ),
                },
                onValueChanged: (v) => setState(() => viewMode = v),
              ),
              Spacer(),
              CupertinoSegmentedControl<DateSortOrder>(
                groupValue: sortOrder,
                padding: EdgeInsets.zero,
                children: const {
                  DateSortOrder.newestFirst: Padding(
                    padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
                    child: Text('Newest'),
                  ),
                  DateSortOrder.oldestFirst: Padding(
                    padding: EdgeInsetsDirectional.symmetric(horizontal: 16),
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

  /// ------------------------------------------------------------
  /// OVERALL TOTALS CARD
  /// ------------------------------------------------------------
  Widget _buildTotalsSummary(double receipts, double expenses) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          _totalTile(
            label: 'Receipts',
            amount: receipts,
            color: CupertinoColors.systemGreen,
          ),
          const Spacer(),
          _totalTile(
            label: 'Expenses',
            amount: expenses,
            color: CupertinoColors.systemRed,
          ),
        ],
      ),
    );
  }

  Widget _totalTile({
    required String label,
    required double amount,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            color: CupertinoColors.secondaryLabel,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// ------------------------------------------------------------
  /// ACCOUNT SELECTOR
  /// ------------------------------------------------------------
  Widget _accountSelector(AsyncValue<List<AccountModel>> accountsAsync) {
    return accountsAsync.when(
      loading: () => const CupertinoActivityIndicator(),
      error: (_, __) => const Text('Account error'),
      data: (accounts) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _showAccountPicker(context, accounts),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey5,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.creditcard, size: 16),
              const SizedBox(width: 6),
              Text(
                selectedAccountName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 6),
              const Icon(CupertinoIcons.chevron_down, size: 14),
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
                const Text(
                  'Select Account',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                CupertinoButton(
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                scrollController: FixedExtentScrollController(
                  initialItem: selectedIndex,
                ),
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

  /// ------------------------------------------------------------
  /// FLAT LIST
  /// ------------------------------------------------------------
  SliverList _buildFlatList(List<LedgerEntry> entries, double opening) {
    double balance = opening;

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final e = entries[index];
        balance += e.type == 'debit' ? e.amount : -e.amount;
        return LedgerRowWidget(entry: e, runningBalance: balance);
      }, childCount: entries.length),
    );
  }

  /// ------------------------------------------------------------
  /// GROUPED LIST (MONTHLY)
  /// ------------------------------------------------------------
  List<Widget> _buildGrouped(List<LedgerEntry> entries, double openingBalance) {
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
            return LedgerRowWidget(
              entry: e,
              runningBalance: running,
              bgColor: i.isEven
                  ? CupertinoColors.systemGrey6.withOpacity(.12)
                  : CupertinoColors.transparent,
            );
          },
        ),
      );
    }
    return slivers;
  }

  /// ------------------------------------------------------------
  /// DATE PICKER
  /// ------------------------------------------------------------
  Widget _dateButton(
    String label,
    DateTime date,
    ValueChanged<DateTime> onChanged,
  ) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _pickDate(date, onChanged),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            Text(
              _shortDateFormat.format(date),
              style: const TextStyle(fontWeight: FontWeight.w600),
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

/// ------------------------------------------------------------
/// MONTH HEADER DELEGATE
/// ------------------------------------------------------------
class _MonthHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String monthLabel;
  final double totalIn;
  final double totalOut;

  _MonthHeaderDelegate({
    required this.monthLabel,
    required this.totalIn,
    required this.totalOut,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(
      color: CupertinoColors.systemGroupedBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            monthLabel,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'In  ₹${totalIn.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: CupertinoColors.systemGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Out ₹${totalOut.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: CupertinoColors.systemRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 72;
  @override
  double get minExtent => 72;

  @override
  bool shouldRebuild(covariant _MonthHeaderDelegate old) =>
      old.monthLabel != monthLabel ||
      old.totalIn != totalIn ||
      old.totalOut != totalOut;
}

// class LedgerScreen extends ConsumerStatefulWidget {
//   const LedgerScreen({super.key});

//   @override
//   ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
// }

// class _LedgerScreenState extends ConsumerState<LedgerScreen> {
//   String selectedAccountId = '';
//   late DateTime from;
//   late DateTime to;

//   final DateFormat _monthFormat = DateFormat('MMMM yyyy');
//   final DateFormat _shortDateFormat = DateFormat('MMM d, yy');

//   @override
//   void initState() {
//     super.initState();
//     final now = DateTime.now();
//     from = DateTime(now.year, now.month, 1);
//     to = DateTime(now.year, now.month + 1, 0);
//   }

//   void _applyFilters() {
//     ref
//         .read(ledgerControllerProvider.notifier)
//         .fetchLedger(
//           from: from,
//           to: to,
//           accountId: selectedAccountId.isEmpty ? null : selectedAccountId,
//         );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final ledgerAsync = ref.watch(ledgerControllerProvider);
//     final accountsAsync = ref.watch(accountListProvider);
//     final scrollController = ScrollController();
//     return CupertinoPageScaffold(
//       navigationBar: CupertinoNavigationBar(
//         //  largeTitle: true,
//         middle: const Text('Account Ledger'),
//         trailing: CupertinoButton(
//           padding: EdgeInsets.zero,
//           onPressed: _applyFilters,
//           child: const Icon(CupertinoIcons.arrow_2_circlepath),
//         ),
//       ),
//       child: SafeArea(
//         child: ledgerAsync.when(
//           loading: () =>
//               const Center(child: CupertinoActivityIndicator(radius: 18)),
//           error: (err, _) => Center(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Icon(
//                   CupertinoIcons.exclamationmark_triangle,
//                   size: 64,
//                   color: CupertinoColors.systemOrange,
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   'Failed to load ledger',
//                   style: TextStyle(color: CupertinoColors.systemRed),
//                 ),
//                 Text(
//                   '$err',
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: CupertinoColors.secondaryLabel,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 CupertinoButton.filled(
//                   onPressed: _applyFilters,
//                   child: const Text('Retry'),
//                 ),
//               ],
//             ),
//           ),
//           data: (ledgerState) {
//             final entries = ledgerState.entries;
//             final openingBalance = ledgerState.openingBalance;

//             if (entries.isEmpty) {
//               return Center(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       CupertinoIcons.doc_text_search,
//                       size: 64,
//                       color: CupertinoColors.secondaryLabel,
//                     ),
//                     const SizedBox(height: 16),
//                     const Text(
//                       'No transactions found',
//                       style: TextStyle(fontSize: 18),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Try changing the date range or account',
//                       style: TextStyle(color: CupertinoColors.secondaryLabel),
//                     ),
//                   ],
//                 ),
//               );
//             }

//             // Group by month + calculate monthly totals
//             final Map<String, List<LedgerEntry>> grouped = {};
//             final Map<String, double> monthlyIn = {};
//             final Map<String, double> monthlyOut = {};

//             for (final e in entries) {
//               final key =
//                   '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}';
//               grouped.putIfAbsent(key, () => []).add(e);

//               if (e.type == 'debit') {
//                 monthlyIn[key] = (monthlyIn[key] ?? 0) + e.amount;
//               } else {
//                 monthlyOut[key] = (monthlyOut[key] ?? 0) + e.amount;
//               }
//             }

//             final sortedKeys = grouped.keys.toList()
//               ..sort((a, b) => b.compareTo(a));

//             double runningBalance = openingBalance;

//             return CupertinoScrollbar(
//               controller: scrollController,
//               child: CustomScrollView(
//                 controller: scrollController,
//                 slivers: [
//                   // Filter Bar
//                   SliverToBoxAdapter(child: _buildFilterBar(accountsAsync)),

//                   // Monthly Sections
//                   ...sortedKeys.expand((monthKey) {
//                     final monthEntries = grouped[monthKey]!;
//                     final monthLabel = _monthFormat.format(
//                       DateTime(
//                         int.parse(monthKey.split('-')[0]),
//                         int.parse(monthKey.split('-')[1]),
//                       ),
//                     );

//                     return [
//                       // Sticky Header with Monthly Totals
//                       SliverPersistentHeader(
//                         pinned: true,
//                         delegate: _MonthHeaderDelegate(
//                           monthLabel: monthLabel,
//                           totalIn: monthlyIn[monthKey] ?? 0,
//                           totalOut: monthlyOut[monthKey] ?? 0,
//                         ),
//                       ),

//                       // Transaction Rows
//                       SliverList.builder(
//                         itemCount: monthEntries.length,
//                         itemBuilder: (context, index) {
//                           final entry = monthEntries[index];
//                           runningBalance += entry.type == 'debit'
//                               ? entry.amount
//                               : -entry.amount;

//                           return LedgerRowWidget(
//                             entry: entry,
//                             runningBalance: runningBalance,
//                             bgColor: index.isEven
//                                 ? Colors.transparent
//                                 : CupertinoColors.systemGrey6.withOpacity(0.15),
//                           );
//                         },
//                       ),
//                     ];
//                   }),

//                   const SliverToBoxAdapter(child: SizedBox(height: 60)),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildFilterBar(AsyncValue<List<AccountModel>> accountsAsync) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       color: CupertinoColors.systemGroupedBackground,
//       child: Row(
//         children: [
//           // Account Picker
//           Expanded(
//             child: accountsAsync.when(
//               data: (accounts) {
//                 final selectedName = selectedAccountId.isEmpty
//                     ? 'All Accounts'
//                     : accounts
//                           .firstWhere((a) => a.id == selectedAccountId)
//                           .name;

//                 return CupertinoButton.filled(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 12,
//                   ),
//                   onPressed: () => _showAccountPicker(context, accounts),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Flexible(
//                         child: Text(
//                           selectedName,
//                           overflow: TextOverflow.ellipsis,
//                           style: const TextStyle(fontWeight: FontWeight.w600),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       const Icon(CupertinoIcons.chevron_down, size: 16),
//                     ],
//                   ),
//                 );
//               },
//               loading: () => const CupertinoActivityIndicator(),
//               error: (_, __) => const Text('Accounts error'),
//             ),
//           ),
//           const SizedBox(width: 12),

//           // Date Range Buttons
//           _dateButton(
//             'From',
//             from,
//             (d) => setState(() {
//               from = d;
//               _applyFilters();
//             }),
//           ),
//           const SizedBox(width: 8),
//           _dateButton(
//             'To',
//             to,
//             (d) => setState(() {
//               to = d;
//               _applyFilters();
//             }),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _dateButton(
//     String label,
//     DateTime date,
//     ValueChanged<DateTime> onChanged,
//   ) {
//     return CupertinoButton(
//       padding: EdgeInsets.zero,
//       onPressed: () => _pickDate(date, onChanged),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//         decoration: BoxDecoration(
//           color: CupertinoColors.systemGrey5,
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Column(
//           children: [
//             Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 11,
//                 color: CupertinoColors.secondaryLabel,
//               ),
//             ),
//             const SizedBox(height: 2),
//             Text(
//               _shortDateFormat.format(date),
//               style: const TextStyle(fontWeight: FontWeight.w600),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showAccountPicker(BuildContext context, List<AccountModel> accounts) {
//     int selectedIndex = accounts.indexWhere((a) => a.id == selectedAccountId);
//     if (selectedIndex == -1) selectedIndex = 0;

//     showCupertinoModalPopup(
//       context: context,
//       builder: (_) => Container(
//         height: 320,
//         color: CupertinoColors.systemBackground,
//         child: Column(
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 CupertinoButton(
//                   child: const Text('Cancel'),
//                   onPressed: () => Navigator.pop(context),
//                 ),
//                 const Text(
//                   'Select Account',
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 CupertinoButton(
//                   child: const Text(
//                     'Done',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   onPressed: () {
//                     setState(
//                       () => selectedAccountId = accounts[selectedIndex].id,
//                     );
//                     _applyFilters();
//                     Navigator.pop(context);
//                   },
//                 ),
//               ],
//             ),
//             Expanded(
//               child: CupertinoPicker(
//                 itemExtent: 36,
//                 scrollController: FixedExtentScrollController(
//                   initialItem: selectedIndex,
//                 ),
//                 onSelectedItemChanged: (i) => selectedIndex = i,
//                 children: accounts
//                     .map((a) => Center(child: Text(a.name)))
//                     .toList(),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _pickDate(DateTime initial, ValueChanged<DateTime> onChanged) {
//     DateTime temp = initial;
//     showCupertinoModalPopup(
//       context: context,
//       builder: (_) => Container(
//         height: 300,
//         color: CupertinoColors.systemBackground,
//         child: Column(
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 CupertinoButton(
//                   child: const Text(
//                     'Done',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   onPressed: () {
//                     onChanged(temp);
//                     Navigator.pop(context);
//                   },
//                 ),
//               ],
//             ),
//             SizedBox(
//               height: 200,
//               child: CupertinoDatePicker(
//                 mode: CupertinoDatePickerMode.date,
//                 initialDateTime: initial,
//                 onDateTimeChanged: (d) => temp = d,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// Sticky Header with Monthly Totals
// class _MonthHeaderDelegate extends SliverPersistentHeaderDelegate {
//   final String monthLabel;
//   final double totalIn;
//   final double totalOut;

//   _MonthHeaderDelegate({
//     required this.monthLabel,
//     required this.totalIn,
//     required this.totalOut,
//   });

//   @override
//   Widget build(
//     BuildContext context,
//     double shrinkOffset,
//     bool overlapsContent,
//   ) {
//     return Container(
//       color: CupertinoColors.systemGroupedBackground,
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//       child: Row(
//         children: [
//           Text(
//             monthLabel,
//             style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//           const Spacer(),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Text(
//                 'In  ₹${totalIn.toStringAsFixed(0)}',
//                 style: TextStyle(
//                   color: CupertinoColors.systemGreen,
//                   fontWeight: FontWeight.w600,
//                   fontSize: 15,
//                 ),
//               ),
//               Text(
//                 'Out ₹${totalOut.toStringAsFixed(0)}',
//                 style: TextStyle(
//                   color: CupertinoColors.systemRed,
//                   fontWeight: FontWeight.w600,
//                   fontSize: 15,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   double get maxExtent => 78;
//   @override
//   double get minExtent => 78;

//   @override
//   bool shouldRebuild(covariant _MonthHeaderDelegate old) =>
//       old.monthLabel != monthLabel ||
//       old.totalIn != totalIn ||
//       old.totalOut != totalOut;
// }
