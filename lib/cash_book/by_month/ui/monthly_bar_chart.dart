import 'package:cashledger/cash_book/by_month/model/monthly_cash_summary.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';

class MonthlyBarChart extends StatelessWidget {
  final MonthlyCashSummary summary;

  const MonthlyBarChart({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        titlesData: FlTitlesData(show: true),
        barGroups: [
          BarChartGroupData(
            x: 1,
            barRods: [BarChartRodData(toY: summary.receipts)],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [BarChartRodData(toY: summary.expenses)],
          ),
        ],
      ),
    );
  }
}
