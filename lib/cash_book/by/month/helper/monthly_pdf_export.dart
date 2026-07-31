import 'dart:typed_data';
import 'package:cashledger/account/model/account_model.dart';
import 'package:cashledger/cash_book/by_month/model/monthly_cash_summary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Export monthly report as PDF (cross-platform: web & native)
/// Handles sharing internally via SharePlus
Future<void> exportMonthlyPdf({
  required MonthlyCashSummary summary,
  List<AccountModel>? accounts,
}) async {
  final pdf = pw.Document();

  final fontData = await rootBundle.load(
    'assets/Roboto-VariableFont_wdth,wght.ttf',
  );
  final font = pw.Font.ttf(fontData);

  final currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  String fmt(double v) => v == 0 ? '-' : currency.format(v);

  // Build account rows from receiptsByAccount + expensesByAccount maps
  final Map<String, Map<String, double>> accountData = {};

  summary.receiptsByAccount.forEach((accId, amt) {
    accountData.putIfAbsent(accId, () => {'in': 0, 'out': 0});
    accountData[accId]!['in'] = (accountData[accId]!['in'] ?? 0) + amt;
  });

  summary.expensesByAccount.forEach((accId, amt) {
    accountData.putIfAbsent(accId, () => {'in': 0, 'out': 0});
    accountData[accId]!['out'] = (accountData[accId]!['out'] ?? 0) + amt;
  });

  // Resolve account names — prefer accounts param, fallback to accountsById
  final Map<String, String> accNames = {};
  if (accounts != null) {
    for (final acc in accounts) {
      accNames[acc.id] = acc.name;
    }
  }
  if (summary.accountsById != null) {
    for (final entry in summary.accountsById!.entries) {
      accNames.putIfAbsent(entry.key, () => entry.value.name);
    }
  }

  final sortedKeys = accountData.keys.toList()..sort((a, b) {
    final nameA = accNames[a] ?? a;
    final nameB = accNames[b] ?? b;
    return nameA.compareTo(nameB);
  });

  final headerRow = pw.TableRow(
    decoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
    children: [
      _headerCell('Account', font, alignment: pw.Alignment.centerLeft),
      _headerCell('Receipts (₹)', font,
          alignment: pw.Alignment.centerRight),
      _headerCell('Expenses (₹)', font,
          alignment: pw.Alignment.centerRight),
    ],
  );

  final dataRows = sortedKeys.map((accId) {
    final data = accountData[accId]!;
    final name = accNames[accId] ?? accId;
    final inAmt = data['in'] ?? 0;
    final outAmt = data['out'] ?? 0;
    return pw.TableRow(children: [
      _cell(name, font, alignment: pw.Alignment.centerLeft),
      _cell(inAmt > 0 ? fmt(inAmt) : '-', font,
          alignment: pw.Alignment.centerRight,
          color: inAmt > 0 ? PdfColors.green700 : PdfColors.grey),
      _cell(outAmt > 0 ? fmt(outAmt) : '-', font,
          alignment: pw.Alignment.centerRight,
          color: outAmt > 0 ? PdfColors.red700 : PdfColors.grey),
    ]);
  }).toList();

  final totalRow = pw.TableRow(
    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
    children: [
      _cell('TOTAL', font, bold: true, alignment: pw.Alignment.centerLeft),
      _cell(fmt(summary.receipts), font,
          bold: true,
          alignment: pw.Alignment.centerRight,
          color: PdfColors.green800),
      _cell(fmt(summary.expenses), font,
          bold: true,
          alignment: pw.Alignment.centerRight,
          color: PdfColors.red800),
    ],
  );

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) => [
        pw.Header(
          level: 0,
          child: pw.Text(
            'Monthly Report – ${summary.monthKey}',
            style: pw.TextStyle(
                fontSize: 20, fontWeight: pw.FontWeight.bold, font: font),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _summaryLine(
                  'Opening Balance', summary.openingBalance, currency, font),
              _summaryLine('New Income', summary.receipts, currency, font,
                  color: PdfColors.green700),
              _summaryLine('Total Expenses', summary.expenses, currency, font,
                  color: PdfColors.red700),
              pw.Divider(),
              _summaryLine('Closing Balance', summary.closingBalance, currency,
                  font,
                  bold: true),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FixedColumnWidth(90),
            2: const pw.FixedColumnWidth(90),
          },
          children: [headerRow, ...dataRows, totalRow],
        ),
        pw.SizedBox(height: 16),
        pw.Align(
          alignment: pw.Alignment.bottomRight,
          child: pw.Text(
            'Generated: ${DateFormat('yyyy-MM-dd hh:mm:ss').format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 8, font: font),
          ),
        ),
      ],
    ),
  );

  final pdfBytes = await pdf.save();
  final fileName = 'monthly_report_${summary.monthKey}.pdf';

  await SharePlus.instance.share(ShareParams(
    files: [
      XFile.fromData(
        Uint8List.fromList(pdfBytes),
        name: fileName,
        mimeType: 'application/pdf',
      ),
    ],
    text: 'Monthly Report – ${summary.monthKey}',
  ));
}

pw.Widget _headerCell(String text, pw.Font font,
    {pw.Alignment alignment = pw.Alignment.centerLeft}) {
  return pw.Container(
    alignment: alignment,
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    child: pw.Text(text,
        style: pw.TextStyle(
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
            fontSize: 10,
            font: font)),
  );
}

pw.Widget _cell(String text, pw.Font font,
    {pw.Alignment alignment = pw.Alignment.centerLeft,
    PdfColor? color,
    bool bold = false}) {
  return pw.Container(
    alignment: alignment,
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    child: pw.Text(text,
        style: pw.TextStyle(
            fontSize: 9,
            color: color ?? PdfColors.black,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            font: font)),
  );
}

pw.Widget _summaryLine(
    String label, double value, NumberFormat currency, pw.Font font,
    {PdfColor? color, bool bold = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: 11,
                font: font,
                fontWeight:
                    bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text(currency.format(value),
            style: pw.TextStyle(
                fontSize: 11,
                font: font,
                color: color,
                fontWeight:
                    bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ],
    ),
  );
}