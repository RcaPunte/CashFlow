import 'package:cashledger/cash_book/by_month/model/monthly_cash_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final monthlyCashRepository = Provider((ref) {
  final db = Supabase.instance.client;
  return CashbookRepository(db);
});

class CashbookRepository {
  final SupabaseClient db;

  CashbookRepository(this.db);

  Future<MonthlyCashSummary> generateMonthlySummary(String monthKey) async {
    final parts = monthKey.split("-");
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    final first = DateTime(year, month, 1);
    final last = DateTime(year, month + 1, 0);

    final rows = await db
        .from("cashbook")
        .select()
        .gte("date", first.toIso8601String())
        .lte("date", last.toIso8601String());

    double receipts = 0;
    double expenses = 0;

    final receiptsByAccount = <String, double>{};
    final expensesByAccount = <String, double>{};

    for (final r in rows) {
      final amount = (r["amount"] ?? 0).toDouble();
      final type = r["type"]; // "DR" / "CR"
      final acc = r["account"] ?? "Unknown";

      if (type == "CR") {
        receipts += amount;
        receiptsByAccount[acc] = (receiptsByAccount[acc] ?? 0) + amount;
      } else {
        expenses += amount;
        expensesByAccount[acc] = (expensesByAccount[acc] ?? 0) + amount;
      }
    }

    // --- Opening balance from previous month
    final prevMonth = month == 1 ? 12 : month - 1;
    final prevYear = month == 1 ? year - 1 : year;
    final prevKey = '$prevYear-${prevMonth.toString().padLeft(2, "0")}';

    final prevSummary = await _calculateClosingBalance(prevKey);

    return MonthlyCashSummary(
      monthKey: monthKey,
      openingBalance: prevSummary,
      receipts: receipts,
      expenses: expenses,
      receiptsByAccount: receiptsByAccount,
      expensesByAccount: expensesByAccount,
      closingBalance: (prevSummary + receipts) - expenses,
    );
  }

  Future<double> _calculateClosingBalance(String monthKey) async {
    // You can also store it in a table for speed
    // For now we re-calc.
    final summary = await generateMonthlySummary(monthKey);
    return summary.closingBalance;
  }
}
