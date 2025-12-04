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

enum LedgerSortField { date, amount, type }

enum SortDirection { asc, desc }

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  String selectedAccountId = '';
  late DateTime from;
  late DateTime to;

  // Sorting state
  LedgerSortField sortField = LedgerSortField.date;
  SortDirection sortDirection = SortDirection.desc;

  final DateFormat _monthHeaderFormat = DateFormat('MMMM yyyy');
  final DateFormat _dateFormat = DateFormat('MMM d, yy');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Default to start of current month to end of current month
    from = DateTime(now.year, now.month, 1);
    to = DateTime(now.year, now.month + 1, 0);
    _applyFilters();
  }

  // --- Data & Filter Logic ---
  void _applyFilters() {
    ref
        .read(ledgerControllerProvider.notifier)
        .fetchLedger(
          from: from,
          to: to,
          accountId: selectedAccountId.isEmpty ? null : selectedAccountId,
        );
  }

  void _showAccountPicker(BuildContext context, List<AccountModel> accounts) {
    // Add an "All Accounts" option at the start
    final List<AccountModel> displayAccounts = [
      AccountModel(id: '', name: 'All Accounts', accountType: ''),
      ...accounts,
    ];

    int initialIndex = displayAccounts.indexWhere(
      (a) => a.id == selectedAccountId,
    );
    if (initialIndex == -1) initialIndex = 0;

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 260,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                'Select Account',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 32,
                scrollController: FixedExtentScrollController(
                  initialItem: initialIndex,
                ),
                onSelectedItemChanged: (index) {
                  setState(() => selectedAccountId = displayAccounts[index].id);
                  // Apply filters immediately upon selection
                  _applyFilters();
                },
                children: displayAccounts
                    .map(
                      (a) => Center(
                        child: Text(
                          a.name,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({
    required DateTime initial,
    required ValueChanged<DateTime> onChanged,
    required String title,
  }) async {
    DateTime tempDate = initial;
    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  onChanged(tempDate);
                  Navigator.pop(ctx);
                },
                child: const Text(
                  'Done',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(
              height: 256,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initial,
                onDateTimeChanged: (d) => tempDate = d,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Grouping and Sorting Logic (Kept mostly the same) ---
  LinkedHashMap<String, List<T>> _groupByMonth<T>(
    List<T> entries,
    DateTime Function(T) dateExtractor,
  ) {
    // ... (Your grouping logic) ...
    final Map<String, List<T>> temp = {};
    for (final e in entries) {
      final d = dateExtractor(e);
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      temp.putIfAbsent(key, () => []).add(e);
    }
    final sortedKeys = temp.keys.toList()..sort((a, b) => b.compareTo(a));
    final LinkedHashMap<String, List<T>> result =
        LinkedHashMap<String, List<T>>();
    for (final key in sortedKeys) {
      result[key] = temp[key]!;
    }
    return result;
  }

  List<T> _sortLedgerList<T>(
    List<T> list,
    num Function(T) amountExtractor,
    DateTime Function(T) dateExtractor,
    String Function(T) typeExtractor,
  ) {
    // ... (Your sorting logic) ...
    final copy = List<T>.from(list);
    copy.sort((a, b) {
      int res = 0;
      switch (sortField) {
        case LedgerSortField.amount:
          final na = amountExtractor(a);
          final nb = amountExtractor(b);
          res = na.compareTo(nb);
          break;
        case LedgerSortField.type:
          final ta = typeExtractor(a);
          final tb = typeExtractor(b);
          res = ta.compareTo(tb);
          break;
        case LedgerSortField.date:
        default:
          final da = dateExtractor(a);
          final db = dateExtractor(b);
          res = da.compareTo(db);
      }
      return sortDirection == SortDirection.asc ? res : -res;
    });
    return copy;
  }

  void _toggleSort(LedgerSortField field) {
    setState(() {
      if (sortField == field) {
        sortDirection = sortDirection == SortDirection.asc
            ? SortDirection.desc
            : SortDirection.asc;
      } else {
        sortField = field;
        sortDirection = (field == LedgerSortField.type)
            ? SortDirection.asc
            : SortDirection.desc;
      }
    });
  }

  Widget _sortIconFor(LedgerSortField field) {
    if (sortField != field) return const SizedBox(width: 16);
    return Icon(
      sortDirection == SortDirection.asc
          ? CupertinoIcons.chevron_up
          : CupertinoIcons.chevron_down,
      size: 10,
      color: CupertinoColors.activeBlue,
    );
  }

  String _monthLabelFromKey(String key) {
    final parts = key.split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    return _monthHeaderFormat.format(DateTime(y, m));
  }

  // --- Running Balance Fix ---
  // To ensure correct running balance, it must be computed sequentially
  // across all entries (in sorted order). We will compute the final list
  // with running balances before the CustomScrollView.

  List<LedgerEntryWithBalance> _computeRunningBalance(
    List<LedgerEntry> sortedLedger,
  ) {
    // IMPORTANT: Replace this 0.0 with the actual starting balance for the account/period.
    double runningBalance = 0.0;

    final List<LedgerEntryWithBalance> result = [];

    // The ledger should ideally be sorted oldest to newest (asc date) for correct balance calculation.
    // If the list is sorted desc, we need to sort it asc first, calculate the balance, then revert.

    // We will assume the entries in `sortedLedger` are already sorted according to the user's
    // preference, but for balance calculation, we temporarily ensure date ascending.
    final List<LedgerEntry> balanceCalculationList = List.from(sortedLedger);
    balanceCalculationList.sort((a, b) => a.date.compareTo(b.date));

    for (final e in balanceCalculationList) {
      if (e.type == 'debit') {
        runningBalance += e.amount;
      } else {
        runningBalance -= e.amount;
      }
      // Store the balance with the entry
      result.add(
        LedgerEntryWithBalance(entry: e, runningBalance: runningBalance),
      );
    }

    // Now, return the results sorted back to the user's preferred order
    if (sortDirection == SortDirection.desc &&
        sortField == LedgerSortField.date) {
      result.sort((a, b) => b.entry.date.compareTo(a.entry.date));
    }

    // Re-sort the final list based on the actual user sort preference:
    final sortedResult = List<LedgerEntryWithBalance>.from(result);
    sortedResult.sort((a, b) {
      // Use the original sorting logic on the entry fields
      int res = 0;
      switch (sortField) {
        case LedgerSortField.amount:
          res = a.entry.amount.compareTo(b.entry.amount);
          break;
        case LedgerSortField.type:
          res = a.entry.type.compareTo(b.entry.type);
          break;
        case LedgerSortField.date:
        default:
          res = a.entry.date.compareTo(b.entry.date);
      }
      return sortDirection == SortDirection.asc ? res : -res;
    });

    return sortedResult;
  }

  // Custom model to hold entry and computed balance
  // This helps separate the logic from the presentation
  double currentRunningBalance = 0.0;
  List<LedgerEntryWithBalance> allEntriesWithBalance = [];

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerControllerProvider);
    final accountsAsync = ref.watch(accountListProvider);

    // 1. Sort the raw ledger list
    final sortedLedger = _sortLedgerList<LedgerEntry>(
      ledger,
      (e) => e.amount,
      (e) => DateTime.parse(e.date.toString()), // Assuming e.date is a String
      (e) => e.type,
    );

    // 2. Compute the running balance
    final allEntriesWithBalance = _computeRunningBalance(ledger);

    // 3. Re-sort the final list (which has balances) for presentation
    final presentationList = _sortLedgerList<LedgerEntryWithBalance>(
      allEntriesWithBalance,
      (e) => e.entry.amount,
      (e) => DateTime.parse(e.entry.date.toString()),
      (e) => e.entry.type,
    );

    // 4. Group by month for presentation
    final grouped = _groupByMonth<LedgerEntryWithBalance>(
      presentationList,
      (e) => DateTime.parse(e.entry.date.toString()),
    );

    // Reset the running balance to initial for the display loop.
    currentRunningBalance = 0.0;

    return Material(
      child: CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text("Account Ledger"),
        ), // Clearer title
        child: Column(
          children: [
            // ---------------------------
            // FILTER BAR
            // ---------------------------
            _buildFilterBar(context, accountsAsync),

            // ---------------------------
            // TABLE HEADER (sticky, clickable for sorts)
            // ---------------------------
            _buildTableHeader(context),

            // ---------------------------
            // LEDGER LIST (grouped by month with sticky headers)
            // ---------------------------
            Expanded(
              child: grouped.isEmpty
                  ? Center(
                      child: Text(
                        'No ledger entries found for this period and account.',
                        style: TextStyle(color: CupertinoColors.inactiveGray),
                      ),
                    )
                  : CustomScrollView(
                      slivers: [
                        for (final section in grouped.entries) ...[
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _MonthHeaderDelegate(
                              monthLabel: _monthLabelFromKey(section.key),
                              // Use systemGroupedBackground for contrast with systemBackground body
                              backgroundColor:
                                  CupertinoColors.systemGroupedBackground,
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final entryWithBalance = section.value[index];
                              return LedgerRowWidget(
                                entry: entryWithBalance.entry,
                                runningBalance: entryWithBalance.runningBalance,
                                bgColor: index.isOdd
                                    ? Colors.blueGrey.shade50
                                    : Colors.white,
                                // Use a cleaner visual separation than alternating colors
                                // bgColor: Colors.transparent,
                              );
                            }, childCount: section.value.length),
                          ),
                        ],
                        const SliverToBoxAdapter(child: SizedBox(height: 30)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────
  // Filter Bar Widget
  // ─────────────────────────────────────
  Widget _buildFilterBar(
    BuildContext context,
    AsyncValue<List<AccountModel>> accountsAsync,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemGroupedBackground,
        border: Border(
          bottom: BorderSide(color: CupertinoColors.separator, width: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Account Filter
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.35,
              child: accountsAsync.when(
                data: (accounts) {
                  final selectedAccountName = selectedAccountId.isEmpty
                      ? 'All Accounts'
                      : accounts
                            .firstWhere((a) => a.id == selectedAccountId)
                            .name;
                  return CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: CupertinoColors.systemGrey5,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: Text(
                            selectedAccountName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(CupertinoIcons.chevron_down, size: 12),
                      ],
                    ),
                    onPressed: () => _showAccountPicker(context, accounts),
                  );
                },
                loading: () => const CupertinoActivityIndicator(),
                error: (_, __) => const Text(
                  "Error loading accounts",
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),

            // Date Filters
            Row(
              children: [
                _dateFilterButton(
                  context,
                  label: "From",
                  date: from,
                  onChanged: (d) => setState(() => from = d),
                ),
                const SizedBox(width: 8),
                _dateFilterButton(
                  context,
                  label: "To",
                  date: to,
                  onChanged: (d) => setState(() => to = d),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateFilterButton(
    BuildContext context, {
    required String label,
    required DateTime date,
    required ValueChanged<DateTime> onChanged,
  }) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: CupertinoColors.systemGrey5,
      borderRadius: BorderRadius.circular(8),
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
            _dateFormat.format(date),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      onPressed: () => _pickDate(
        initial: date,
        onChanged: onChanged,
        title: 'Select $label Date',
      ),
    );
  }

  // ─────────────────────────────────────
  // Table Header Widget
  // ─────────────────────────────────────
  Widget _buildTableHeader(BuildContext context) {
    // Defines the proportional width of columns
    final double dateWidth = MediaQuery.of(context).size.width * 0.15;
    final double descriptionWidth = MediaQuery.of(context).size.width * 0.3;
    final double amountWidth =
        MediaQuery.of(context).size.width * 0.14; // Dr/Cr
    final double balanceWidth = MediaQuery.of(context).size.width * 0.18;

    // Use a neutral background that contrasts slightly with the list background
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: CupertinoColors.systemGrey4,
      child: Row(
        children: [
          // Date (sortable)
          _sortableHeader(
            label: 'Date',
            field: LedgerSortField.date,
            width: dateWidth,
            alignment: Alignment.centerLeft,
          ),

          // Description (Fixed width/Expanded)
          SizedBox(
            width: descriptionWidth,
            child: const Text(
              'Description',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),

          const Spacer(), // Used to center the amounts/balance section
          // Dr (Amount sortable)
          _sortableHeader(
            label: 'Dr',
            field: LedgerSortField.amount,
            width: amountWidth,
            alignment: Alignment.centerRight,
            isAmount: true,
          ),

          // Cr (Type sortable)
          _sortableHeader(
            label: 'Cr',
            field: LedgerSortField.type,
            width: amountWidth,
            alignment: Alignment.centerRight,
          ),

          // Balance (Fixed width)
          SizedBox(
            width: balanceWidth,
            child: const Text(
              'Balance',
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // Reusable sortable header component
  Widget _sortableHeader({
    required String label,
    required LedgerSortField field,
    required double width,
    required Alignment alignment,
    bool isAmount = false,
  }) {
    return GestureDetector(
      onTap: () => _toggleSort(field),
      child: Container(
        width: width,
        alignment: alignment,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: alignment == Alignment.centerRight
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
            if (sortField == field) ...[
              const SizedBox(width: 4),
              _sortIconFor(field),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────
// Custom Model for Balance Computation
// ─────────────────────────────────────

// Helper class to pass both the entry and its computed running balance
class LedgerEntryWithBalance {
  final LedgerEntry entry;
  final double runningBalance;

  LedgerEntryWithBalance({required this.entry, required this.runningBalance});
}

// ─────────────────────────────────────
// Month Header Delegate (Sticky)
// ─────────────────────────────────────
class _MonthHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String monthLabel;
  final Color backgroundColor;

  _MonthHeaderDelegate({
    required this.monthLabel,
    required this.backgroundColor,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      // Use the injected background color
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Text(
        monthLabel,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: CupertinoColors.label,
        ),
      ),
    );
  }

  @override
  double get maxExtent => 44; // Standard header height
  @override
  double get minExtent => 44;
  @override
  bool shouldRebuild(covariant _MonthHeaderDelegate oldDelegate) {
    return oldDelegate.monthLabel != monthLabel ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
