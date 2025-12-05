import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cashledger/cash_book/by_month/model/monthly_cash_summary.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'
    show rootBundle; // Required for loading font

// NOTE: You must have a font file (e.g., 'assets/fonts/Roboto-Regular.ttf')
// that supports the Rupee symbol in your Flutter project's assets folder,
// and it must be declared in your pubspec.yaml.

Future<File> exportMonthlyPdf(MonthlyCashSummary m) async {
  final pdf = pw.Document();

  // 1. Load Font supporting Rupee symbol
  // Replace 'assets/fonts/Roboto-Regular.ttf' with your actual font asset path.
  final fontData = await rootBundle.load(
    'assets/Roboto-VariableFont_wdth,wght.ttf',
  );
  final ttf = pw.Font.ttf(fontData);

  // Helper function to format currency
  final currencyFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  // 2. Aggregate Data and prepare rows (as before)
  final Map<String, List<double>> aggregatedData = {};

  void aggregate(String account, double inAmount, double outAmount) {
    aggregatedData.putIfAbsent(account, () => [0.0, 0.0]);
    aggregatedData[account]![0] += inAmount;
    aggregatedData[account]![1] += outAmount;
  }

  m.receiptsByAccount.forEach((account, amount) {
    aggregate(account, amount, 0.0);
  });

  m.expensesByAccount.forEach((account, amount) {
    aggregate(account, 0.0, amount);
  });

  final List<List<String>> tableRows = aggregatedData.entries.map((entry) {
    final String account = entry.key;
    final double inAmount = entry.value[0];
    final double outAmount = entry.value[1];

    final String inText = inAmount > 0
        ? currencyFormatter.format(inAmount)
        : "";
    final String outText = outAmount > 0
        ? currencyFormatter.format(outAmount)
        : "";

    return [account, inText, outText];
  }).toList();

  tableRows.sort((a, b) => a[0].compareTo(b[0]));

  final List<List<String>> finalData = [
    ["Particulars (Account)", "IN (₹)", "OUT (₹)"],
    ...tableRows,
  ];

  final String totalIn = currencyFormatter.format(m.receipts);
  final String totalOut = currencyFormatter.format(m.expenses);

  finalData.add(["TOTAL", totalIn, totalOut]);

  // PDF Content Generation
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Report Header - Apply font
          pw.Text(
            "Monthly Cashbook Report - ${m.monthKey}",
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              font: ttf, // APPLY FONT HERE
            ),
          ),
          pw.SizedBox(height: 16),

          // Summary Section - Apply font to amounts
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F0F0F0'),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Opening Balance: ${currencyFormatter.format(m.openingBalance)}",
                  style: pw.TextStyle(
                    fontSize: 14,
                    font: ttf,
                  ), // APPLY FONT HERE
                ),
                pw.Text(
                  "Total Receipts: ${currencyFormatter.format(m.receipts)}",
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.green700,
                    font: ttf,
                  ), // APPLY FONT HERE
                ),
                pw.Text(
                  "Total Expenses: ${currencyFormatter.format(m.expenses)}",
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.red700,
                    font: ttf,
                  ), // APPLY FONT HERE
                ),
                pw.Text(
                  "Closing Balance: ${currencyFormatter.format(m.closingBalance)}",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    font: ttf,
                  ), // APPLY FONT HERE
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 30),

          // Table Header - Apply font to section title
          pw.Text(
            "Account Movements (Cash Book)",
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.normal,
              font: ttf, // APPLY FONT HERE
            ),
          ),
          pw.SizedBox(height: 8),

          // Combined Account Movements Table
          pw.Table.fromTextArray(
            headerAlignment: pw.Alignment.centerLeft,
            cellAlignment: pw.Alignment.centerRight,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              font: ttf,
            ), // APPLY FONT HERE
            cellStyle: pw.TextStyle(fontSize: 10, font: ttf), // APPLY FONT HERE
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey700,
            ),

            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
            },

            data: finalData,

            cellDecoration: (context, rowNum, colNum) {
              if (rowNum == finalData.length - 1) {
                return const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(width: 1.5, color: PdfColors.black),
                    bottom: pw.BorderSide(width: 1.5, color: PdfColors.black),
                  ),
                  color: PdfColors.grey200,
                );
              }
              return pw.BoxDecoration();
            },

            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
            },

            // cellStyle: (rowNum, columnNum) {
            //   if (rowNum == finalData.length - 1) {
            //     return pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, font: ttf); // APPLY FONT HERE
            //   }
            //   return pw.TextStyle(fontSize: 10, font: ttf); // ENSURE FONT FOR ALL CELLS
            // },
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
