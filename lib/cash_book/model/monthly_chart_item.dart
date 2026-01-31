class MonthlyChartItem {
  final double openingBalance;
  final String monthLabel; // "Jan", "Feb"
  final double receipts;
  final double expenses;
  final double closingBalance;

  MonthlyChartItem({
    required this.openingBalance,
    required this.monthLabel,
    required this.receipts,
    required this.expenses,
    required this.closingBalance,
  });
}
