// import 'dart:io';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:cashledger/cash_book/by_month/model/monthly_cash_summary.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:intl/intl.dart';
// import 'package:flutter/services.dart'
//     show rootBundle; // Required for loading font

// // NOTE: You must have a font file (e.g., 'assets/fonts/Roboto-Regular.ttf')
// // that supports the Rupee symbol in your Flutter project's assets folder,
// // and it must be declared in your pubspec.yaml.

// Future<File> exportMonthlyPdf(MonthlyCashSummary m) async {
//   final pdf = pw.Document();

//   // 1. Load Font supporting Rupee symbol
//   // Replace 'assets/fonts/Roboto-Regular.ttf' with your actual font asset path.
//   final fontData = await rootBundle.load(
//     'assets/Roboto-VariableFont_wdth,wght.ttf',
//   );
//   final ttf = pw.Font.ttf(fontData);

//   // Helper function to format currency
//   final currencyFormatter = NumberFormat.currency(
//     locale: 'en_IN',
//     symbol: '₹',
//     decimalDigits: 2,
//   );

//   // 2. Aggregate Data and prepare rows (as before)
//   final Map<String, List<double>> aggregatedData = {};

//   void aggregate(String account, double inAmount, double outAmount) {
//     aggregatedData.putIfAbsent(account, () => [0.0, 0.0]);
//     aggregatedData[account]![0] += inAmount;
//     aggregatedData[account]![1] += outAmount;
//   }

//   m.receiptsByAccount.forEach((account, amount) {
//     aggregate(account, amount, 0.0);
//   });

//   m.expensesByAccount.forEach((account, amount) {
//     aggregate(account, 0.0, amount);
//   });

//   final List<List<String>> tableRows = aggregatedData.entries.map((entry) {
//     final String account = entry.key;
//     final double inAmount = entry.value[0];
//     final double outAmount = entry.value[1];

//     final String inText = inAmount > 0
//         ? currencyFormatter.format(inAmount)
//         : "";
//     final String outText = outAmount > 0
//         ? currencyFormatter.format(outAmount)
//         : "";

//     return [account, inText, outText];
//   }).toList();

//   tableRows.sort((a, b) => a[0].compareTo(b[0]));

//   final List<List<String>> finalData = [
//     ["Particulars (Account)", "IN (₹)", "OUT (₹)"],
//     ...tableRows,
//   ];

//   final String totalIn = currencyFormatter.format(m.receipts);
//   final String totalOut = currencyFormatter.format(m.expenses);

//   finalData.add(["TOTAL", totalIn, totalOut]);

//   // PDF Content Generation
//   pdf.addPage(
//     pw.Page(
//       pageFormat: PdfPageFormat.a4,
//       build: (context) => pw.Column(
//         crossAxisAlignment: pw.CrossAxisAlignment.start,
//         children: [
//           // Report Header - Apply font
//           pw.Text(
//             "Monthly Cashbook Report - ${m.monthKey}",
//             style: pw.TextStyle(
//               fontSize: 24,
//               fontWeight: pw.FontWeight.bold,
//               font: ttf, // APPLY FONT HERE
//             ),
//           ),
//           pw.SizedBox(height: 16),

//           // Summary Section - Apply font to amounts
//           pw.Container(
//             padding: const pw.EdgeInsets.all(8),
//             decoration: pw.BoxDecoration(
//               color: PdfColor.fromHex('#F0F0F0'),
//               borderRadius: pw.BorderRadius.circular(4),
//             ),
//             child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 pw.Text(
//                   "Opening Balance: ${currencyFormatter.format(m.openingBalance)}",
//                   style: pw.TextStyle(
//                     fontSize: 14,
//                     font: ttf,
//                   ), // APPLY FONT HERE
//                 ),
//                 pw.Text(
//                   "Total Receipts: ${currencyFormatter.format(m.receipts)}",
//                   style: pw.TextStyle(
//                     fontSize: 14,
//                     color: PdfColors.green700,
//                     font: ttf,
//                   ), // APPLY FONT HERE
//                 ),
//                 pw.Text(
//                   "Total Expenses: ${currencyFormatter.format(m.expenses)}",
//                   style: pw.TextStyle(
//                     fontSize: 14,
//                     color: PdfColors.red700,
//                     font: ttf,
//                   ), // APPLY FONT HERE
//                 ),
//                 pw.Text(
//                   "Closing Balance: ${currencyFormatter.format(m.closingBalance)}",
//                   style: pw.TextStyle(
//                     fontSize: 16,
//                     fontWeight: pw.FontWeight.bold,
//                     font: ttf,
//                   ), // APPLY FONT HERE
//                 ),
//               ],
//             ),
//           ),

//           pw.SizedBox(height: 30),

//           // Table Header - Apply font to section title
//           pw.Text(
//             "Account Movements (Cash Book)",
//             style: pw.TextStyle(
//               fontSize: 18,
//               fontWeight: pw.FontWeight.normal,
//               font: ttf, // APPLY FONT HERE
//             ),
//           ),
//           pw.SizedBox(height: 8),

//           // Combined Account Movements Table
//           pw.Table.fromTextArray(
//             headerAlignment: pw.Alignment.centerLeft,
//             cellAlignment: pw.Alignment.centerRight,
//             headerStyle: pw.TextStyle(
//               fontWeight: pw.FontWeight.bold,
//               color: PdfColors.white,
//               font: ttf,
//             ), // APPLY FONT HERE
//             cellStyle: pw.TextStyle(fontSize: 10, font: ttf), // APPLY FONT HERE
//             headerDecoration: const pw.BoxDecoration(
//               color: PdfColors.blueGrey700,
//             ),

//             columnWidths: {
//               0: const pw.FlexColumnWidth(3),
//               1: const pw.FlexColumnWidth(1),
//               2: const pw.FlexColumnWidth(1),
//             },

//             data: finalData,

//             cellDecoration: (context, rowNum, colNum) {
//               if (rowNum == finalData.length - 1) {
//                 return const pw.BoxDecoration(
//                   border: pw.Border(
//                     top: pw.BorderSide(width: 1.5, color: PdfColors.black),
//                     bottom: pw.BorderSide(width: 1.5, color: PdfColors.black),
//                   ),
//                   color: PdfColors.grey200,
//                 );
//               }
//               return pw.BoxDecoration();
//             },

//             cellAlignments: {
//               0: pw.Alignment.centerLeft,
//               1: pw.Alignment.centerRight,
//               2: pw.Alignment.centerRight,
//             },

//             // cellStyle: (rowNum, columnNum) {
//             //   if (rowNum == finalData.length - 1) {
//             //     return pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, font: ttf); // APPLY FONT HERE
//             //   }
//             //   return pw.TextStyle(fontSize: 10, font: ttf); // ENSURE FONT FOR ALL CELLS
//             // },
//           ),
//         ],
//       ),
//     ),
//   );

//   final dir = await getTemporaryDirectory();
//   final file = File("${dir.path}/cashbook_${m.monthKey}.pdf");
//   await file.writeAsBytes(await pdf.save());
//   return file;
// }

//FOR WEB
import 'dart:typed_data'; // For Uint8List
import 'package:cashledger/cash_book/by_month/model/monthly_cash_summary.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart'; // Optional: Best for cross-platform PDF handling

// Change return type from Future<File> to Future<Uint8List>
import 'dart:typed_data';
import 'dart:html' as html;

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class AccountRow {
  final String name;
  final double inAmount;
  final double outAmount;
  final int indentLevel;
  final bool isSubAccount;

  AccountRow({
    required this.name,
    required this.inAmount,
    required this.outAmount,
    required this.indentLevel,
    required this.isSubAccount,
  });
}

Future<void> exportMonthlyPdfFromAccounts({
  required MonthlyCashSummary summary,
  required List<AccountRow> rows,
}) async {
  final pdf = pw.Document();

  // Font (supports ₹)
  final fontData = await rootBundle.load(
    'assets/Roboto-VariableFont_wdth,wght.ttf',
  );
  final font = pw.Font.ttf(fontData);

  final currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  String fmt(double v) => v == 0 ? '-' : currency.format(v);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) => [
        // ───────── HEADER ─────────
        pw.Text(
          'Monthly Cashbook Report – ${summary.monthKey}',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            font: font,
          ),
        ),
        pw.SizedBox(height: 12),

        // ───────── SUMMARY ─────────
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Opening Balance: ${currency.format(summary.openingBalance)}',
                style: pw.TextStyle(font: font),
              ),
              pw.Text(
                'New Income: ${currency.format(summary.receipts)}',
                style: pw.TextStyle(color: PdfColors.green700, font: font),
              ),
              pw.Text(
                'Total Expenses: ${currency.format(summary.expenses)}',
                style: pw.TextStyle(color: PdfColors.red700, font: font),
              ),
              pw.Divider(),
              pw.Text(
                'Closing Balance: ${currency.format(summary.closingBalance)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 24),

        // ───────── TABLE HEADER ─────────
        pw.Row(
          children: [
            pw.Expanded(
              flex: 4,
              child: pw.Text(
                'PARTICULARS',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font),
              ),
            ),
            pw.Expanded(
              child: pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'IN',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green700,
                    font: font,
                  ),
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'OUT',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red700,
                    font: font,
                  ),
                ),
              ),
            ),
          ],
        ),
        pw.Divider(),

        // ───────── ACCOUNT ROWS ─────────
        ...rows.map((r) {
          final inPct = summary.receipts == 0
              ? 0
              : (r.inAmount / summary.receipts) * 100;

          final outPct = summary.expenses == 0
              ? 0
              : (r.outAmount / summary.expenses) * 100;

          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Row(
              children: [
                // Account name with indentation
                pw.Expanded(
                  flex: 4,
                  child: pw.Padding(
                    padding: pw.EdgeInsets.only(left: r.indentLevel * 12),
                    child: pw.Text(
                      r.name,
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 11,
                        color: r.isSubAccount
                            ? PdfColors.grey700
                            : PdfColors.black,
                      ),
                    ),
                  ),
                ),

                // IN column
                pw.Expanded(
                  child: pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      fmt(r.inAmount),
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 11,
                        color: r.inAmount == 0
                            ? PdfColors.grey
                            : PdfColors.green700,
                        fontWeight: r.indentLevel == 0
                            ? pw.FontWeight.bold
                            : pw.FontWeight.normal,
                      ),
                    ),
                  ),
                ),

                // OUT column
                pw.Expanded(
                  child: pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      fmt(r.outAmount),
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 11,
                        color: r.outAmount == 0
                            ? PdfColors.grey
                            : PdfColors.red700,
                        fontWeight: r.indentLevel == 0
                            ? pw.FontWeight.bold
                            : pw.FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    ),
  );

  // ───────── WEB DOWNLOAD ─────────
  final bytes = await pdf.save();
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..setAttribute('download', 'cashbook_${summary.monthKey}.pdf')
    ..click();

  html.Url.revokeObjectUrl(url);
}

Future<void> exportMonthlyPdfWeb(MonthlyCashSummary m) async {
  final pdf = pw.Document();

  // Load font (works on web)
  final fontData = await rootBundle.load(
    'assets/Roboto-VariableFont_wdth,wght.ttf',
  );
  final ttf = pw.Font.ttf(fontData);

  final currencyFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  // ─────────────────────────────
  // Aggregate Account Data
  // ─────────────────────────────
  final Map<String, List<double>> aggregatedData = {};

  void aggregate(String account, double inAmount, double outAmount) {
    aggregatedData.putIfAbsent(account, () => [0.0, 0.0]);
    aggregatedData[account]![0] += inAmount;
    aggregatedData[account]![1] += outAmount;
  }

  m.receiptsByAccount.forEach((acc, amt) {
    final accName = m.accountsById![acc];
    // .accountsById![acc]?.name;

    aggregate(accName!.name ?? acc, amt, 0);
  });

  m.expensesByAccount.forEach((acc, amt) {
    aggregate(acc, 0, amt);
  });

  final rows = aggregatedData.entries.map((e) {
    return [
      e.key,
      e.value[0] > 0 ? currencyFormatter.format(e.value[0]) : '',
      e.value[1] > 0 ? currencyFormatter.format(e.value[1]) : '',
    ];
  }).toList()..sort((a, b) => a[0].compareTo(b[0]));

  final tableData = [
    ['Particulars (Account)', 'IN (₹)', 'OUT (₹)'],
    ...rows,
    [
      'TOTAL',
      currencyFormatter.format(m.receipts),
      currencyFormatter.format(m.expenses),
    ],
  ];

  // ─────────────────────────────
  // PDF Layout
  // ─────────────────────────────
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Monthly Cashbook Report - ${m.monthKey}',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              font: ttf,
            ),
          ),
          pw.SizedBox(height: 16),

          // Summary Card
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Opening Balance: ${currencyFormatter.format(m.openingBalance)}',
                  style: pw.TextStyle(font: ttf),
                ),
                pw.Text(
                  'Total Receipts: ${currencyFormatter.format(m.receipts)}',
                  style: pw.TextStyle(color: PdfColors.green700, font: ttf),
                ),
                pw.Text(
                  'Total Expenses: ${currencyFormatter.format(m.expenses)}',
                  style: pw.TextStyle(color: PdfColors.red700, font: ttf),
                ),
                pw.Text(
                  'Closing Balance: ${currencyFormatter.format(m.closingBalance)}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    font: ttf,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          pw.Text(
            'Account Movements',
            style: pw.TextStyle(fontSize: 18, font: ttf),
          ),
          pw.SizedBox(height: 8),

          pw.Table.fromTextArray(
            data: tableData,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              font: ttf,
            ),
            cellStyle: pw.TextStyle(fontSize: 10, font: ttf),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey700,
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
            },
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
            },
          ),
        ],
      ),
    ),
  );

  // ─────────────────────────────
  // WEB DOWNLOAD
  // ─────────────────────────────
  final Uint8List bytes = await pdf.save();

  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', 'cashbook_${m.monthKey}.pdf')
    ..click();

  html.Url.revokeObjectUrl(url);
}
