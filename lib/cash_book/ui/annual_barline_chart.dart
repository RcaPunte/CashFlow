import 'package:cashledger/cash_book/model/monthly_chart_item.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AnnualBarLineChart extends StatelessWidget {
  final List<MonthlyChartItem> data;

  const AnnualBarLineChart({super.key, required this.data});
  String formatNumber(double value) {
    if (value >= 1000) return "${(value / 1000).toStringAsFixed(0)}k";
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5,
        borderRadius: BorderRadius.circular(14),
      ),
      child: BarChart(_barData),

      // Stack(
      //   children: [
      //     BarChart(_barData),
      //     // IgnorePointer(child: LineChart(_lineData)),
      //   ],
      // ),
    );
  }

  /// BAR
  BarChartData get _barData => BarChartData(
    barGroups: _buildBarGroups(),
    borderData: FlBorderData(show: false),
    gridData: const FlGridData(show: true),
    titlesData: FlTitlesData(
      rightTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          getTitlesWidget: (value, meta) {
            return Text(
              formatNumber(value),
              style: const TextStyle(fontSize: 10, color: Colors.black),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            return Text(
              //  "${value ~/ 1}", // or format as 10k
              formatNumber(value),
              style: const TextStyle(
                fontSize: 10, // <<< SMALL FONT
                color: Colors.black,
              ),
            );
          },
        ),
      ),
      //leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 32,
          getTitlesWidget: (value, meta) {
            final i = value.toInt();
            if (i < 0 || i >= data.length) return const SizedBox();
            return Text(
              data[i].monthLabel,
              style: const TextStyle(fontSize: 11),
            );
          },
        ),
      ),
    ),
  );

  /// LINE
  // LineChartData get _lineData => LineChartData(
  //   borderData: FlBorderData(show: false),
  //   gridData: const FlGridData(show: false),
  //   titlesData: const FlTitlesData(show: false),
  //   lineBarsData: [
  //     LineChartBarData(
  //       isCurved: true,
  //       color: Colors.orange,
  //       barWidth: 3,
  //       dotData: const FlDotData(show: true),
  //       spots: [
  //         for (int i = 0; i < data.length; i++)
  //           FlSpot(i.toDouble(), data[i].closingBalance),
  //       ],
  //     ),
  //   ],
  // );

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(data.length, (i) {
      final m = data[i];

      return BarChartGroupData(
        x: i,
        groupVertically: false,
        barRods: [
          BarChartRodData(
            toY: m.receipts,
            color: Colors.green,
            width: 10,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: m.expenses,
            color: Colors.red,
            width: 10,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }
}
