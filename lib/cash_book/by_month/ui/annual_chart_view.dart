import 'package:cashledger/cash_book/by_month/model/monthly_cash_summary.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';

class AnnualChart extends StatelessWidget {
  final List<MonthlyCashSummary> data;

  const AnnualChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barGroups: data.asMap().entries.map((entry) {
          final i = entry.key;
          final m = entry.value;

          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(toY: m.receipts),
              BarChartRodData(toY: m.expenses),
            ],
          );
        }).toList(),
      ),
    );
  }
}
