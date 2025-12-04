import 'package:cashledger/cash_book/by_month/model/monthly_cash_summary.dart';
import 'package:cashledger/cash_book/model/monthly_chart_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'monthly_summary_provider.dart';

final annualChartProvider = FutureProvider.family<List<MonthlyChartItem>, int>((
  ref,
  year,
) async {
  final List<MonthlyChartItem> list = [];

  for (int month = 1; month <= 12; month++) {
    final date = DateTime(year, month, 1);

    final summary = await ref.read(monthlySummaryProvider(date).future);

    list.add(
      MonthlyChartItem(
        monthLabel: DateFormat('MMM').format(date), // Jan, Feb, Mar...
        receipts: summary.receipts,
        expenses: summary.expenses,
        closingBalance: summary.closingBalance,
      ),
    );
  }

  return list;
});

final monthlySummaryListProvider = FutureProvider<List<MonthlyCashSummary>>((
  ref,
) async {
  final List<MonthlyCashSummary> list = [];

  for (int i = 1; i <= 12; i++) {
    final month = DateTime(DateTime.now().year, i, 1);

    final item = await ref.watch(monthlySummaryProvider(month).future);
    list.add(item);
  }

  return list;
});
