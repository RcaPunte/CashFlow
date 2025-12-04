import 'package:cashledger/cash_book/by_month/model/monthly_cash_summary.dart';
import 'package:cashledger/cash_book/by_month/repository/monthly_cash_book_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final annualReportProvider =
    FutureProvider.family<List<MonthlyCashSummary>, int>((ref, year) async {
      final repo = ref.watch(monthlyCashRepository);

      final summaries = <MonthlyCashSummary>[];

      for (int m = 1; m <= 12; m++) {
        final key = "$year-${m.toString().padLeft(2, '0')}";
        summaries.add(await repo.generateMonthlySummary(key));
      }

      return summaries;
    });
