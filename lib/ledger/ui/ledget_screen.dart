import 'package:cashledger/account/model/account_model.dart';
import 'package:cashledger/ledger/controller/ledget_controller.dart';
import 'package:cashledger/ledger/model/ledger_entry.dart';
import 'package:cashledger/ledger/ui/widgets/ledger_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'dart:collection';
import 'package:cashledger/account/model/account_model.dart';
import 'package:cashledger/ledger/controller/ledget_controller.dart';
import 'package:cashledger/ledger/ui/widgets/ledger_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// enum LedgerSortField { date, amount, type }

// enum SortDirection { asc, desc }

// class LedgerScreen extends ConsumerStatefulWidget {
//   const LedgerScreen({super.key});

//   @override
//   ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
// }

// class _LedgerScreenState extends ConsumerState<LedgerScreen> {
//   String selectedAccountId = '';
//   late DateTime from;
//   late DateTime to;

//   // Sorting state
//   LedgerSortField sortField = LedgerSortField.date;
//   SortDirection sortDirection = SortDirection.desc; // default newest first

//   final DateFormat monthHeaderFormat = DateFormat('MMMM yyyy');
//   final DateFormat rowDateFormat = DateFormat('dd MMM yy');

//   @override
//   void initState() {
//     super.initState();
//     final now = DateTime.now();
//     from = DateTime(now.year, now.month, 1);
//     to = DateTime(now.year, now.month + 1, 0);
//     _applyFilters();
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

//   void _showAccountPicker(BuildContext context, List<AccountModel> accounts) {
//     showCupertinoModalPopup(
//       context: context,
//       builder: (_) => Container(
//         height: 260,
//         color: CupertinoColors.systemBackground.resolveFrom(context),
//         child: CupertinoPicker(
//           itemExtent: 32,
//           onSelectedItemChanged: (index) {
//             setState(() => selectedAccountId = accounts[index].id);
//             _applyFilters();
//           },
//           children: accounts.map((a) => Text(a.name)).toList(),
//         ),
//       ),
//     );
//   }

//   Future<void> _pickDate({
//     required DateTime initial,
//     required ValueChanged<DateTime> onChanged,
//   }) async {
//     await showCupertinoModalPopup(
//       context: context,
//       builder: (ctx) => SizedBox(
//         height: 260,
//         child: CupertinoDatePicker(
//           mode: CupertinoDatePickerMode.date,
//           initialDateTime: initial,
//           onDateTimeChanged: onChanged,
//         ),
//       ),
//     );
//     _applyFilters();
//   }

//   LinkedHashMap<String, List<T>> _groupByMonth<T>(
//     List<T> entries,
//     DateTime Function(T) dateExtractor,
//   ) {
//     // temporary normal map to collect items
//     final Map<String, List<T>> temp = {};

//     for (final e in entries) {
//       final d = dateExtractor(e);
//       final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';

//       temp.putIfAbsent(key, () => []).add(e);
//     }

//     // sort keys reverse chronological
//     final sortedKeys = temp.keys.toList()..sort((a, b) => b.compareTo(a));

//     // Create LinkedHashMap and insert in sorted order
//     final LinkedHashMap<String, List<T>> result =
//         LinkedHashMap<String, List<T>>();

//     for (final key in sortedKeys) {
//       result[key] = temp[key]!;
//     }

//     return result;
//   }

//   // ---- Sort ledger entries list according to active sortField/direction
//   List<T> _sortLedgerList<T>(
//     List<T> list,
//     num Function(T) amountExtractor,
//     DateTime Function(T) dateExtractor,
//     String Function(T) typeExtractor,
//   ) {
//     final copy = List<T>.from(list);
//     int cmp<TVal extends Comparable>(TVal a, TVal b) => a.compareTo(b);

//     copy.sort((a, b) {
//       int res = 0;
//       switch (sortField) {
//         case LedgerSortField.amount:
//           final na = amountExtractor(a);
//           final nb = amountExtractor(b);
//           res = na.compareTo(nb);
//           break;
//         case LedgerSortField.type:
//           final ta = typeExtractor(a);
//           final tb = typeExtractor(b);
//           res = ta.compareTo(tb);
//           break;
//         case LedgerSortField.date:
//         default:
//           final da = dateExtractor(a);
//           final db = dateExtractor(b);
//           res = da.compareTo(db);
//       }
//       return sortDirection == SortDirection.asc ? res : -res;
//     });

//     return copy;
//   }

//   void _toggleSort(LedgerSortField field) {
//     setState(() {
//       if (sortField == field) {
//         // toggle direction
//         sortDirection = sortDirection == SortDirection.asc
//             ? SortDirection.desc
//             : SortDirection.asc;
//       } else {
//         sortField = field;
//         // default directions: date desc, amount desc, type asc
//         sortDirection = (field == LedgerSortField.type)
//             ? SortDirection.asc
//             : SortDirection.desc;
//       }
//     });
//   }

//   Widget _sortIconFor(LedgerSortField field) {
//     if (sortField != field) return const SizedBox(width: 16);
//     return Icon(
//       sortDirection == SortDirection.asc
//           ? CupertinoIcons.arrow_up
//           : CupertinoIcons.arrow_down,
//       size: 12,
//       color: CupertinoColors.systemGrey,
//     );
//   }

//   String _monthLabelFromKey(String key) {
//     final parts = key.split('-');
//     final y = int.parse(parts[0]);
//     final m = int.parse(parts[1]);
//     return monthHeaderFormat.format(DateTime(y, m));
//   }

//   @override
//   Widget build(BuildContext context) {
//     final ledger = ref.watch(ledgerControllerProvider); // List<LedgerEntry>
//     final accountsAsync = ref.watch(accountListProvider);

//     // Apply sorting to ledger list before grouping
//     final sortedLedger = _sortLedgerList<LedgerEntry>(
//       ledger,
//       (e) => e.amount,
//       (e) => e.date,
//       (e) => e.type,
//     );

//     // Group by month using entry.date
//     final grouped = _groupByMonth<LedgerEntry>(sortedLedger, (e) => e.date);

//     // Running balance should be computed per account or overall from opening balance.
//     // For simplicity here we compute running balance starting at 0 and apply sorted order.
//     // If you have opening balance per account, compute that and add here.
//     double runningBalanceInitial = 0; // replace if fetching opening balance
//     // We'll compute per section sequentially, but preserve continuity across months.
//     double runningBalance = runningBalanceInitial;

//     return Material(
//       child: CupertinoPageScaffold(
//         navigationBar: const CupertinoNavigationBar(middle: Text("Ledger")),
//         child: SafeArea(
//           child: Column(
//             children: [
//               // ---------------------------
//               // FILTER BAR
//               // ---------------------------
//               Padding(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 8,
//                 ),
//                 child: Row(
//                   children: [
//                     // Account picker
//                     Expanded(
//                       child: accountsAsync.when(
//                         data: (accounts) => CupertinoButton(
//                           padding: EdgeInsets.zero,
//                           child: Text(
//                             selectedAccountId.isEmpty
//                                 ? 'All Accounts'
//                                 : accounts
//                                       .firstWhere(
//                                         (a) => a.id == selectedAccountId,
//                                       )
//                                       .name,
//                             style: const TextStyle(fontSize: 15),
//                           ),
//                           onPressed: () =>
//                               _showAccountPicker(context, accounts),
//                         ),
//                         loading: () => const CupertinoActivityIndicator(),
//                         error: (_, __) =>
//                             const Text("Error", style: TextStyle(fontSize: 14)),
//                       ),
//                     ),

//                     // From date
//                     CupertinoButton(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 6,
//                         vertical: 4,
//                       ),
//                       child: Column(
//                         children: [
//                           Text(
//                             "From",
//                             style: TextStyle(color: CupertinoColors.activeBlue),
//                           ),
//                           Text(
//                             DateFormat('MMM d, yy').format(from),
//                             style: const TextStyle(fontSize: 13),
//                           ),
//                         ],
//                       ),
//                       onPressed: () => _pickDate(
//                         initial: from,
//                         onChanged: (d) => setState(() => from = d),
//                       ),
//                     ),

//                     // To date
//                     CupertinoButton(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 6,
//                         vertical: 4,
//                       ),
//                       child: Column(
//                         children: [
//                           Text(
//                             "To",
//                             style: TextStyle(color: CupertinoColors.activeBlue),
//                           ),
//                           Text(
//                             DateFormat('MMM d, yy').format(to),
//                             style: const TextStyle(fontSize: 13),
//                           ),
//                         ],
//                       ),
//                       onPressed: () => _pickDate(
//                         initial: to,
//                         onChanged: (d) => setState(() => to = d),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               // ---------------------------
//               // TABLE HEADER (clickable for sorts)
//               // ---------------------------
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   vertical: 8,
//                   horizontal: 12,
//                 ),
//                 color: CupertinoColors.systemGrey5,
//                 child: Row(
//                   children: [
//                     // Date (sortable)
//                     SizedBox(
//                       width: MediaQuery.of(context).size.width * 0.14,
//                       child: GestureDetector(
//                         onTap: () => _toggleSort(LedgerSortField.date),
//                         child: Row(
//                           children: [
//                             const Text(
//                               'Date',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 12,
//                               ),
//                             ),
//                             const SizedBox(width: 6),
//                             _sortIconFor(LedgerSortField.date),
//                           ],
//                         ),
//                       ),
//                     ),

//                     // Description (not sortable)
//                     const Expanded(
//                       child: Text(
//                         'Description',
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),

//                     // Dr (amount sortable)
//                     SizedBox(
//                       width: MediaQuery.of(context).size.width * 0.16,
//                       child: GestureDetector(
//                         onTap: () => _toggleSort(LedgerSortField.amount),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           children: [
//                             const Text(
//                               'Dr',
//                               textAlign: TextAlign.right,
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 12,
//                               ),
//                             ),
//                             const SizedBox(width: 6),
//                             _sortIconFor(LedgerSortField.amount),
//                           ],
//                         ),
//                       ),
//                     ),

//                     // Cr (type sortable)
//                     SizedBox(
//                       width: MediaQuery.of(context).size.width * 0.16,
//                       child: GestureDetector(
//                         onTap: () => _toggleSort(LedgerSortField.type),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           children: [
//                             const Text(
//                               'Cr',
//                               textAlign: TextAlign.right,
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 12,
//                               ),
//                             ),
//                             const SizedBox(width: 6),
//                             _sortIconFor(LedgerSortField.type),
//                           ],
//                         ),
//                       ),
//                     ),

//                     // Balance
//                     SizedBox(
//                       width: MediaQuery.of(context).size.width * 0.18,
//                       child: const Text(
//                         'Balance',
//                         textAlign: TextAlign.right,
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               // ---------------------------
//               // LEDGER LIST (grouped by month with sticky headers)
//               // ---------------------------
//               Expanded(
//                 child: grouped.isEmpty
//                     ? Center(
//                         child: Text(
//                           'No entries',
//                           style: TextStyle(color: CupertinoColors.inactiveGray),
//                         ),
//                       )
//                     : CustomScrollView(
//                         slivers: [
//                           for (final section in grouped.entries) ...[
//                             SliverPersistentHeader(
//                               pinned: true,
//                               delegate: _MonthHeaderDelegate(
//                                 monthKey: section.key,
//                                 height: 56,
//                                 monthLabel: _monthLabelFromKey(section.key),
//                               ),
//                             ),
//                             SliverList(
//                               delegate: SliverChildBuilderDelegate((
//                                 context,
//                                 index,
//                               ) {
//                                 final e = section.value[index];

//                                 // update running balance:
//                                 if (e.type == 'debit') {
//                                   runningBalance += e.amount;
//                                 } else {
//                                   runningBalance -= e.amount;
//                                 }

//                                 return LedgerRowWidget(
//                                   entry: e,
//                                   runningBalance: runningBalance,
//                                   bgColor: index.isOdd
//                                       ? Colors.blueGrey.shade50
//                                       : Colors.transparent,
//                                 );
//                               }, childCount: section.value.length),
//                             ),
//                           ],
//                         ],
//                       ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // month header delegate (sticky)
// class _MonthHeaderDelegate extends SliverPersistentHeaderDelegate {
//   final String monthKey;
//   final double height;
//   final String monthLabel;

//   _MonthHeaderDelegate({
//     required this.monthKey,
//     required this.height,
//     required this.monthLabel,
//   });

//   @override
//   Widget build(
//     BuildContext context,
//     double shrinkOffset,
//     bool overlapsContent,
//   ) {
//     return Container(
//       color: CupertinoColors.systemGrey6,
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       alignment: Alignment.centerLeft,
//       child: Row(
//         children: [
//           Expanded(
//             child: Text(
//               monthLabel,
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//             ),
//           ),
//           // you can show monthly totals here if you compute them separately & pass in
//         ],
//       ),
//     );
//   }

//   @override
//   double get maxExtent => height;
//   @override
//   double get minExtent => height;
//   @override
//   bool shouldRebuild(covariant _MonthHeaderDelegate oldDelegate) {
//     return oldDelegate.monthKey != monthKey ||
//         oldDelegate.monthLabel != monthLabel;
//   }
// }
// lib/ledger/ui/ledger_screen.dart

import 'package:cashledger/account/model/account_model.dart';
import 'package:cashledger/ledger/controller/ledget_controller.dart';
import 'package:cashledger/ledger/model/ledger_entry.dart';
import 'package:cashledger/ledger/ui/widgets/ledger_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  String selectedAccountId = '';
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

  @override
  Widget build(BuildContext context) {
    final ledgerAsync = ref.watch(ledgerControllerProvider);
    final accountsAsync = ref.watch(accountListProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        //  largeTitle: true,
        middle: const Text('Account Ledger'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _applyFilters,
          child: const Icon(CupertinoIcons.arrow_2_circlepath),
        ),
      ),
      child: SafeArea(
        child: ledgerAsync.when(
          loading: () =>
              const Center(child: CupertinoActivityIndicator(radius: 18)),
          error: (err, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  size: 64,
                  color: CupertinoColors.systemOrange,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load ledger',
                  style: TextStyle(color: CupertinoColors.systemRed),
                ),
                Text(
                  '$err',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
                const SizedBox(height: 20),
                CupertinoButton.filled(
                  onPressed: _applyFilters,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (ledgerState) {
            final entries = ledgerState.entries;
            final openingBalance = ledgerState.openingBalance;

            if (entries.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.doc_text_search,
                      size: 64,
                      color: CupertinoColors.secondaryLabel,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No transactions found',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try changing the date range or account',
                      style: TextStyle(color: CupertinoColors.secondaryLabel),
                    ),
                  ],
                ),
              );
            }

            // Group by month + calculate monthly totals
            final Map<String, List<LedgerEntry>> grouped = {};
            final Map<String, double> monthlyIn = {};
            final Map<String, double> monthlyOut = {};

            for (final e in entries) {
              final key =
                  '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}';
              grouped.putIfAbsent(key, () => []).add(e);

              if (e.type == 'debit') {
                monthlyIn[key] = (monthlyIn[key] ?? 0) + e.amount;
              } else {
                monthlyOut[key] = (monthlyOut[key] ?? 0) + e.amount;
              }
            }

            final sortedKeys = grouped.keys.toList()
              ..sort((a, b) => b.compareTo(a));

            double runningBalance = openingBalance;

            return CupertinoScrollbar(
              child: CustomScrollView(
                slivers: [
                  // Filter Bar
                  SliverToBoxAdapter(child: _buildFilterBar(accountsAsync)),

                  // Monthly Sections
                  ...sortedKeys.expand((monthKey) {
                    final monthEntries = grouped[monthKey]!;
                    final monthLabel = _monthFormat.format(
                      DateTime(
                        int.parse(monthKey.split('-')[0]),
                        int.parse(monthKey.split('-')[1]),
                      ),
                    );

                    return [
                      // Sticky Header with Monthly Totals
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _MonthHeaderDelegate(
                          monthLabel: monthLabel,
                          totalIn: monthlyIn[monthKey] ?? 0,
                          totalOut: monthlyOut[monthKey] ?? 0,
                        ),
                      ),

                      // Transaction Rows
                      SliverList.builder(
                        itemCount: monthEntries.length,
                        itemBuilder: (context, index) {
                          final entry = monthEntries[index];
                          runningBalance += entry.type == 'debit'
                              ? entry.amount
                              : -entry.amount;

                          return LedgerRowWidget(
                            entry: entry,
                            runningBalance: runningBalance,
                            bgColor: index.isEven
                                ? Colors.transparent
                                : CupertinoColors.systemGrey6.withOpacity(0.15),
                          );
                        },
                      ),
                    ];
                  }),

                  const SliverToBoxAdapter(child: SizedBox(height: 60)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterBar(AsyncValue<List<AccountModel>> accountsAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: CupertinoColors.systemGroupedBackground,
      child: Row(
        children: [
          // Account Picker
          Expanded(
            child: accountsAsync.when(
              data: (accounts) {
                final selectedName = selectedAccountId.isEmpty
                    ? 'All Accounts'
                    : accounts
                          .firstWhere((a) => a.id == selectedAccountId)
                          .name;

                return CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  onPressed: () => _showAccountPicker(context, accounts),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          selectedName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(CupertinoIcons.chevron_down, size: 16),
                    ],
                  ),
                );
              },
              loading: () => const CupertinoActivityIndicator(),
              error: (_, __) => const Text('Accounts error'),
            ),
          ),
          const SizedBox(width: 12),

          // Date Range Buttons
          _dateButton(
            'From',
            from,
            (d) => setState(() {
              from = d;
              _applyFilters();
            }),
          ),
          const SizedBox(width: 8),
          _dateButton(
            'To',
            to,
            (d) => setState(() {
              to = d;
              _applyFilters();
            }),
          ),
        ],
      ),
    );
  }

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
            const SizedBox(height: 2),
            Text(
              _shortDateFormat.format(date),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountPicker(BuildContext context, List<AccountModel> accounts) {
    int selectedIndex = accounts.indexWhere((a) => a.id == selectedAccountId);
    if (selectedIndex == -1) selectedIndex = 0;

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
                    setState(
                      () => selectedAccountId = accounts[selectedIndex].id,
                    );
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
                children: accounts
                    .map((a) => Center(child: Text(a.name)))
                    .toList(),
              ),
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
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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

// Sticky Header with Monthly Totals
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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: CupertinoColors.systemGroupedBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Text(
            monthLabel,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'In  ₹${totalIn.toStringAsFixed(0)}',
                style: TextStyle(
                  color: CupertinoColors.systemGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              Text(
                'Out ₹${totalOut.toStringAsFixed(0)}',
                style: TextStyle(
                  color: CupertinoColors.systemRed,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 78;
  @override
  double get minExtent => 78;

  @override
  bool shouldRebuild(covariant _MonthHeaderDelegate old) =>
      old.monthLabel != monthLabel ||
      old.totalIn != totalIn ||
      old.totalOut != totalOut;
}
