import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/supabase_init.dart';
import 'app/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppSupabase.initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return CupertinoApp.router(
      debugShowCheckedModeBanner: false,
      title: "Cashbook App",
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: CupertinoColors.activeBlue,
        barBackgroundColor: CupertinoColors.systemGrey6,
        scaffoldBackgroundColor: CupertinoColors.systemGrey6,
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(fontSize: 16, color: CupertinoColors.black),
          navLargeTitleTextStyle: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.black,
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}
// class MyApp extends ConsumerWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final router = ref.watch(appRouterProvider);

//     return MaterialApp.router(
//       debugShowCheckedModeBanner: false,
//       title: "Cashbook App",
//       routerConfig: router,
//     );
//   }
// }


    // final ledger = ref.watch(ledgerControllerProvider);
    // final accountsAsync = ref.watch(accountListProvider);

    // // 1. Compute the running balance
    // final allEntriesWithBalance = _computeRunningBalance(ledger);

    // // 2. Group by month for presentation and calculate monthly totals
    // final grouped = _groupByMonth(allEntriesWithBalance, (e) => e.entry.date);

    // // 3. Calculate Overall Totals
    // final overallTotalIn = ledger
    //     .where((e) => e.type == 'debit')
    //     .fold(0.0, (sum, e) => sum + e.amount);
    // final overallTotalOut = ledger
    //     .where((e) => e.type == 'credit')
    //     .fold(0.0, (sum, e) => sum + e.amount);

    // // 4. Get the final running balance (last entry in the list, regardless of group)
    // final closingBalance = allEntriesWithBalance.isNotEmpty
    //     ? allEntriesWithBalance.last.runningBalance
    //     : 0.0;



// group

  //  for (final group in grouped.values) ...[
  //                         SliverPersistentHeader(
  //                           pinned = true,
  //                           delegate = _MonthHeaderDelegate11(
  //                             monthLabel: _monthLabelFromKey(group.monthKey),
  //                             totalIn: group.totalIn,
  //                             totalOut: group.totalOut,
  //                             backgroundColor:
  //                                 CupertinoColors.systemGroupedBackground,
  //                           ),
  //                         ),
  //                         SliverList(
  //                           delegate = SliverChildBuilderDelegate((
  //                             context,
  //                             index,
  //                           ) {
  //                             final entryWithBalance = group.entries[index];
  //                             return LedgerRowWidget(
  //                               entry: entryWithBalance.entry,
  //                               runningBalance: entryWithBalance.runningBalance,
  //                               // Alternating background for better readability
  //                               bgColor: index.isOdd
  //                                   ? CupertinoColors.systemBackground
  //                                   : CupertinoColors.systemGrey6,
  //                             );
  //                           }, childCount: group.entries.length),
  //                         ),
  //                       ],

//                         class MonthlyLedgerGroup {
//   final String monthKey;
//   final List<LedgerEntryWithBalance> entries;
//   final double totalIn;
//   final double totalOut;

//   MonthlyLedgerGroup({
//     required this.monthKey,
//     required this.entries,
//     this.totalIn = 0.0,
//     this.totalOut = 0.0,
//   });
// }
//   
// LinkedHashMap<String, MonthlyLedgerGroup> _groupByMonth(
//     List<LedgerEntryWithBalance> entries,
//     DateTime Function(LedgerEntryWithBalance) dateExtractor,
//   ) {
//     final Map<String, List<LedgerEntryWithBalance>> groupedEntries = {};
//     final Map<String, double> monthlyTotalIn = {};
//     final Map<String, double> monthlyTotalOut = {};

//     for (final ewb in entries) {
//       final e = ewb.entry;
//       final d = dateExtractor(ewb);
//       final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';

//       groupedEntries.putIfAbsent(key, () => []).add(ewb);

//       // Calculate totals during grouping
//       if (e.type == 'debit') {
//         // Assuming 'debit' means money IN
//         monthlyTotalIn[key] = (monthlyTotalIn[key] ?? 0.0) + e.amount;
//       } else if (e.type == 'credit') {
//         // Assuming 'credit' means money OUT
//         monthlyTotalOut[key] = (monthlyTotalOut[key] ?? 0.0) + e.amount;
//       }
//     }

//     // Sort keys descending (newest month first)
//     final sortedKeys = groupedEntries.keys.toList()
//       ..sort((a, b) => b.compareTo(a));

//     final LinkedHashMap<String, MonthlyLedgerGroup> result = LinkedHashMap();
//     for (final key in sortedKeys) {
//       result[key] = MonthlyLedgerGroup(
//         monthKey: key,
//         entries: groupedEntries[key]!,
//         totalIn: monthlyTotalIn[key] ?? 0.0,
//         totalOut: monthlyTotalOut[key] ?? 0.0,
//       );
//     }
//     return result;
//   }

// -----------------------------------------------------------------------------
// MONTH HEADER DELEGATE (Sticky Header with Monthly Totals)
// -----------------------------------------------------------------------------
