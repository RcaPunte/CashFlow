import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cashledger/cash_book/by_month/model/monthly_cash_summary.dart';
import 'package:path_provider/path_provider.dart';

Future<File> exportMonthlyPdf(MonthlyCashSummary m) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "Monthly Cashbook Report - ${m.monthKey}",
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),

          pw.Text("Opening Balance: Rs ${m.openingBalance}"),
          pw.Text("Receipts: Rs ${m.receipts}"),
          pw.Text("Expenses: Rs ${m.expenses}"),
          pw.Text("Closing Balance: ₹${m.closingBalance}"),

          pw.SizedBox(height: 20),
          pw.Text("Receipts by Account", style: pw.TextStyle(fontSize: 18)),
          pw.Table.fromTextArray(
            data: [
              ["Account", "Amount"],
              ...m.receiptsByAccount.entries.map(
                (e) => [e.key, e.value.toString()],
              ),
            ],
          ),

          pw.SizedBox(height: 20),
          pw.Text("Expenses by Account", style: pw.TextStyle(fontSize: 18)),
          pw.Table.fromTextArray(
            data: [
              ["Account", "Amount"],
              ...m.expensesByAccount.entries.map(
                (e) => [e.key, e.value.toString()],
              ),
            ],
          ),
        ],
      ),
    ),
  );

  final dir = await getTemporaryDirectory();
  final file = File("${dir.path}/cashbook_${m.monthKey}.pdf");
  await file.writeAsBytes(await pdf.save());
  return file;
}
