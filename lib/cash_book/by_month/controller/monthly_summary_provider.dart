import 'package:cashledger/cash_book/by_month/model/monthly_cash_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final monthlySummaryProvider =
    FutureProvider.family<MonthlyCashSummary, DateTime>((ref, date) async {
      try {
        final supabase = Supabase.instance.client;

        final year = date.year;
        final month = date.month;

        final monthKey = "$year-${month.toString().padLeft(2, '0')}";

        // Month start → end
        final monthFrom = DateTime(year, month, 1);
        final monthTo = DateTime(year, month + 1, 0);
        double openingBalance = 0;

        // final year = selectedDate.year;
        // final month = selectedDate.month;

        // ------------------------------------------------------------
        // 1️⃣ JANUARY → USE MANUAL OPENING BALANCE
        // ------------------------------------------------------------
        if (month == 1) {
          final res = await supabase
              .from('opening_balances')
              .select('amount')
              .eq('year', year);
          for (final e in res) {
            final amt = (e['amount'] as num).toDouble();
            openingBalance += amt;
          }
          //openingBalance = (res['amount'] as num).toDouble();
        }
        // ------------------------------------------------------------
        // 2️⃣ OTHER MONTHS → SAME YEAR ONLY
        // ------------------------------------------------------------
        else {
          final yearStart = DateTime(year, 1, 1);
          final monthStart = DateTime(year, month, 1);

          final prevRows = await supabase
              .from('entries')
              .select('type, amount')
              .gte('date', yearStart.toIso8601String())
              .lt('date', monthStart.toIso8601String());

          for (final e in prevRows) {
            final amt = (e['amount'] as num).toDouble();

            openingBalance += e['type'] == 'debit' ? amt : -amt;
          }
        }

        // final prevRows = await supabase
        //     .from("entries")
        //     .select("type, amount")
        //     .lt("date", DateTime(2025, 12, 31).toIso8601String());
        // final prevRows = await supabase
        //     .from("entries")
        //     .select("type, amount")
        //     .lt("date", monthFrom.toIso8601String());
        // for (final e in prevRows) {
        //   final amt = (e['amount'] as num).toDouble();
        //   openingBalance += e['type'] == 'debit' ? amt : -amt;
        // }

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
      } catch (e) {
        return MonthlyCashSummary(
          monthKey: "${date.year}-${date.month.toString().padLeft(2, '0')}",
          openingBalance: 0,
          receipts: 0,
          expenses: 0,
          closingBalance: 0,
          receiptsByAccount: {},
          expensesByAccount: {},
        );
      }
    });
