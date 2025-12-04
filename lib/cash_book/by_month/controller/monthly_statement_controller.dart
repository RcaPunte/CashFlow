import 'package:cashledger/cash_book/controller/cash_book_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final monthlyStatementProvider =
    FutureProvider.family<MonthlyStatement, DateTime>((ref, month) async {
      final entries = await ref.watch(entriesListProvider.future);

      final year = month.year;
      final mon = month.month;

      final start = DateTime(year, mon, 1);
      final end = DateTime(year, mon + 1, 0);

      double opening = 0;
      double receipts = 0;
      double expenses = 0;

      final accountMap = <String, AccountSummary>{};

      for (final e in entries) {
        final date = DateTime.parse(e['date']);
        final amt = (e['amount'] ?? 0).toDouble();
        final type = e['type'];
        final accountName = e['accounts']?['name'] ?? 'Unknown';

        // Build account summary
        accountMap.putIfAbsent(accountName, () => AccountSummary());

        if (date.isBefore(start)) {
          if (type == 'debit')
            opening += amt;
          else
            opening -= amt;
        } else if (!date.isBefore(start) && !date.isAfter(end)) {
          if (type == 'debit') {
            receipts += amt;
            accountMap[accountName]!.receipts += amt;
          } else {
            expenses += amt;
            accountMap[accountName]!.expenses += amt;
          }
        }
      }

      return MonthlyStatement(
        opening: opening,
        receipts: receipts,
        totalReceipts: opening + receipts,
        expenses: expenses,
        accountSummary: accountMap,
      );
    });

class MonthlyStatement {
  final double opening;
  final double receipts;
  final double totalReceipts;
  final double expenses;
  final Map<String, AccountSummary> accountSummary;

  MonthlyStatement({
    required this.opening,
    required this.receipts,
    required this.totalReceipts,
    required this.expenses,
    required this.accountSummary,
  });
}

class AccountSummary {
  double receipts = 0;
  double expenses = 0;
}
