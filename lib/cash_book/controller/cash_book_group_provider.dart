import 'dart:collection';
import 'package:cashledger/cash_book/controller/cash_book_controller.dart';
import 'package:cashledger/opening_balance/controller/opening_balance_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final groupedEntriesProvider = Provider((ref) {
  final entries = ref.watch(entriesListProvider).value ?? [];

  final map = <String, List<Map<String, dynamic>>>{};

  for (final e in entries) {
    final d = DateTime.parse(e['date']);
    final key = "${d.year}-${d.month.toString().padLeft(2, '0')}";
    map.putIfAbsent(key, () => []).add(e);
  }

  final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));

  final grouped = LinkedHashMap.fromIterable(
    sortedKeys,
    key: (k) => k,
    value: (k) => map[k]!,
  );

  return grouped;
});

/// Monthly totals provider
// final monthlyTotalsProvider = Provider((ref) {
//   final grouped = ref.watch(groupedEntriesProvider);

//   final totals = <String, Map<String, double>>{};

//   grouped.forEach((key, list) {
//     double receipts = 0;
//     double expenses = 0;

//     for (var e in list) {
//       final amt = (e['amount'] ?? 0).toDouble();
//       if (e['type'] == 'debit') {
//         receipts += amt;
//       } else {
//         expenses += amt;
//       }
//     }

//     totals[key] = {
//       'receipts': receipts,
//       'expenses': expenses,
//       'balance': receipts - expenses,
//     };
//   });

//   return totals;
// });

final monthlyTotalsProvider = Provider((ref) {
  final grouped = ref.watch(groupedEntriesProvider);
  final yearOpeningAsync = ref.watch(yearOpeningBalanceProvider);

  // If opening balance not loaded yet, return empty
  if (!yearOpeningAsync.hasValue) return <String, Map<String, double>>{};

  final yearOpeningBalance = yearOpeningAsync.value!;
  final totals = <String, Map<String, double>>{};

  // --------------------------------------------------
  // 1️⃣ Calculate receipts & expenses per month
  // --------------------------------------------------
  grouped.forEach((key, list) {
    double receipts = 0;
    double expenses = 0;

    for (var e in list) {
      final amt = (e['amount'] ?? 0).toDouble();
      if (e['type'] == 'debit') {
        receipts += amt;
      } else {
        expenses += amt;
      }
    }

    totals[key] = {
      'receipts': receipts,
      'expenses': expenses,
      'openingBalance': 0,
      'balance': 0,
    };
  });

  // --------------------------------------------------
  // 2️⃣ Sort months chronologically (ASC)
  // --------------------------------------------------
  final sortedKeys = totals.keys.toList()..sort((a, b) => a.compareTo(b));

  // --------------------------------------------------
  // 3️⃣ Rolling balance with JANUARY OVERRIDE
  // --------------------------------------------------
  double previousClosing = yearOpeningBalance;

  for (int i = 0; i < sortedKeys.length; i++) {
    final key = sortedKeys[i];
    final monthData = totals[key]!;

    final month = int.parse(key.split('-')[1]);

    // JANUARY → manual opening balance
    if (month == 1) {
      monthData['openingBalance'] = yearOpeningBalance;
    } else {
      monthData['openingBalance'] = previousClosing;
    }

    monthData['balance'] =
        monthData['openingBalance']! +
        monthData['receipts']! -
        monthData['expenses']!;

    previousClosing = monthData['balance']!;
  }

  return totals;
});

// final monthlyTotalsProvider = Provider((ref) {
//   final grouped = ref.watch(groupedEntriesProvider);

//   final totals = <String, Map<String, double>>{};

//   // Step 1: Calculate receipts and expenses per month
//   grouped.forEach((key, list) {
//     double receipts = 0;
//     double expenses = 0;

//     for (var e in list) {
//       final amt = (e['amount'] ?? 0).toDouble();
//       if (e['type'] == 'debit') {
//         receipts += amt;
//       } else {
//         expenses += amt;
//       }
//     }

//     totals[key] = {
//       'receipts': receipts,
//       'expenses': expenses,
//       'openingBalance': 0, // placeholder, filled later
//       'balance': receipts - expenses,
//     };
//   });

//   // Step 2: Sort keys chronologically (YYYY-MM)
//   final sortedKeys = totals.keys.toList()..sort((a, b) => a.compareTo(b));

//   // Step 3: Calculate rolling balances
//   double previousClosing = 0;
//   for (final key in sortedKeys) {
//     final monthData = totals[key]!;
//     monthData['openingBalance'] = previousClosing;
//     monthData['balance'] =
//         previousClosing + monthData['receipts']! - monthData['expenses']!;
//     previousClosing = monthData['balance']!;
//   }

//   return totals;
// });
