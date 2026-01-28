import 'package:cashledger/cash_book/by_month/model/monthly_cash_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// final monthlySummaryProvider =
//     FutureProvider.family<MonthlyCashSummary, DateTime>((ref, date) async {
//       final supabase = Supabase.instance.client;

//       // -------------------------------
//       // Extract year and month from DateTime
//       // -------------------------------
//       final year = date.year;
//       final month = date.month;

//       // Create monthKey: "2025-03"
//       final monthKey = "$year-${month.toString().padLeft(2, '0')}";

//       // This month
//       final from = DateTime(year, month, 1);
//       final to = DateTime(year, month + 1, 0);

//       // Previous month
//       final prevFrom = DateTime(year, month - 1, 1);
//       final prevTo = DateTime(year, month, 0);

//       // -----------------------------------------------------------------
//       // 1️⃣ Opening Balance (previous month closing)
//       // -----------------------------------------------------------------
//       double openingBalance = 0;

//       final prevRows = await supabase
//           .from("entries")
//           .select()
//           .gte("date", prevFrom.toIso8601String())
//           .lte("date", prevTo.toIso8601String());

//       for (final e in prevRows) {
//         final type = e['type'];
//         final amt = (e['amount'] as num).toDouble();

//         if (type == 'debit') {
//           openingBalance += amt;
//         } else {
//           openingBalance -= amt;
//         }
//       }

//       // -----------------------------------------------------------------
//       // 2️⃣ This Month Entries
//       // -----------------------------------------------------------------
//       final rows = await supabase
//           .from("entries")
//           .select("*, accounts(name)")
//           .gte("date", from.toIso8601String())
//           .lte("date", to.toIso8601String())
//           .order("date", ascending: true);

//       double receipts = 0;
//       double expenses = 0;

//       final receiptsByAccount = <String, double>{};
//       final expensesByAccount = <String, double>{};

//       for (final e in rows) {
//         final type = e['type'];
//         final amt = (e['amount'] as num).toDouble();
//         final accountName = e['accounts']['name'] ?? "Unknown";

//         if (type == 'debit') {
//           // Receipt
//           receipts += amt;
//           receiptsByAccount.update(
//             accountName,
//             (v) => v + amt,
//             ifAbsent: () => amt,
//           );
//         } else {
//           // Expense
//           expenses += amt;
//           expensesByAccount.update(
//             accountName,
//             (v) => v + amt,
//             ifAbsent: () => amt,
//           );
//         }
//       }

//       // -----------------------------------------------------------------
//       // 3️⃣ Closing Balance
//       // -----------------------------------------------------------------
//       final closingBalance = openingBalance + receipts - expenses;

//       return MonthlyCashSummary(
//         monthKey: monthKey,
//         openingBalance: openingBalance,
//         receipts: receipts,
//         expenses: expenses,
//         closingBalance: closingBalance,
//         receiptsByAccount: receiptsByAccount,
//         expensesByAccount: expensesByAccount,
//       );
//     });
final monthlySummaryProvider =
    FutureProvider.family<MonthlyCashSummary, DateTime>((ref, date) async {
      final supabase = Supabase.instance.client;

      final year = date.year;
      final month = date.month;

      final monthKey = "$year-${month.toString().padLeft(2, '0')}";

      // Month start → end
      final monthFrom = DateTime(year, month, 1);
      final monthTo = DateTime(year, month + 1, 0);

      // ------------------------------------------------------------
      // 1. OPENING BALANCE (all entries BEFORE this month)
      // ------------------------------------------------------------
      double openingBalance = 0;

      final prevRows = await supabase
          .from("entries")
          .select("type, amount")
          .lt("date", monthFrom.toIso8601String());

      for (final e in prevRows) {
        final amt = (e['amount'] as num).toDouble();
        openingBalance += e['type'] == 'debit' ? amt : -amt;
      }

      // ------------------------------------------------------------
      // 2. THIS MONTH'S TRANSACTIONS
      // ------------------------------------------------------------
      final rows = await supabase
          .from("entries")
          .select("*, accounts(name)")
          .gte("date", monthFrom.toIso8601String())
          .lte("date", monthTo.toIso8601String())
          .order("date", ascending: true);

      double receipts = 0;
      double expenses = 0;

      final receiptsByAcc = <String, double>{};
      final expensesByAcc = <String, double>{};

      for (final e in rows) {
        final type = e['type'];
        final amt = (e['amount'] as num).toDouble();
        final accountName = e['accounts']['name'] ?? "Unknown";

        if (type == 'debit') {
          receipts += amt;
          receiptsByAcc.update(
            accountName,
            (v) => v + amt,
            ifAbsent: () => amt,
          );
        } else {
          expenses += amt;
          expensesByAcc.update(
            accountName,
            (v) => v + amt,
            ifAbsent: () => amt,
          );
        }
      }

      // ------------------------------------------------------------
      // 3. CALCULATE CLOSING BALANCE
      // opening + receipts - expenses
      // ------------------------------------------------------------
      final closingBalance = openingBalance + receipts - expenses;

      return MonthlyCashSummary(
        monthKey: monthKey,
        openingBalance: openingBalance,
        receipts: receipts,
        expenses: expenses,
        closingBalance: closingBalance,
        receiptsByAccount: receiptsByAcc,
        expensesByAccount: expensesByAcc,
      );
    });
