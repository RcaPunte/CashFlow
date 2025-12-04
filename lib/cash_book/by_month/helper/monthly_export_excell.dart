import 'dart:io';
import 'package:cashledger/cash_book/by_month/model/monthly_cash_summary.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;
import 'package:path_provider/path_provider.dart';

Future<File> exportMonthlyExcel(MonthlyCashSummary m) async {
  final xls.Workbook workbook = xls.Workbook();
  final sheet = workbook.worksheets[0];
  sheet.name = "Summary";

  sheet.getRangeByName('A1').setText("Month");
  sheet.getRangeByName('B1').setText(m.monthKey);

  sheet.getRangeByName('A2').setText("Opening Balance");
  sheet.getRangeByName('B2').setNumber(m.openingBalance);

  sheet.getRangeByName('A3').setText("Receipts");
  sheet.getRangeByName('B3').setNumber(m.receipts);

  sheet.getRangeByName('A4').setText("Expenses");
  sheet.getRangeByName('B4').setNumber(m.expenses);

  sheet.getRangeByName('A5').setText("Closing Balance");
  sheet.getRangeByName('B5').setNumber(m.closingBalance);

  int row = 7;
  sheet.getRangeByName('A$row').setText("Receipts by Account");
  row++;

  sheet.getRangeByName('A$row').setText("Account");
  sheet.getRangeByName('B$row').setText("Amount");
  row++;

  m.receiptsByAccount.forEach((acc, amt) {
    sheet.getRangeByName('A$row').setText(acc);
    sheet.getRangeByName('B$row').setNumber(amt);
    row++;
  });

  row += 1;
  sheet.getRangeByName('A$row').setText("Expenses by Account");
  row++;

  sheet.getRangeByName('A$row').setText("Account");
  sheet.getRangeByName('B$row').setText("Amount");
  row++;

  m.expensesByAccount.forEach((acc, amt) {
    sheet.getRangeByName('A$row').setText(acc);
    sheet.getRangeByName('B$row').setNumber(amt);
    row++;
  });

  final List<int> bytes = workbook.saveAsStream();
  workbook.dispose();

  final dir = await getTemporaryDirectory();
  final file = File("${dir.path}/cashbook_${m.monthKey}.xlsx");

  await file.writeAsBytes(bytes, flush: true);
  return file;
}
