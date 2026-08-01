import 'dart:io';
import 'dart:typed_data';
import 'package:cashledger/budget/model/budget_item_model.dart';
import 'package:cashledger/budget/model/budget_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Export budget report as PDF
Future<void> exportBudgetPdf({
  required Budget budget,
  required List<BudgetItem> items,
  bool parentOnly = false,
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

  // Totals
  double totalBudgeted = 0;
  double totalActual = 0;
  double totalPrevious = 0;
  for (final item in items) {
    totalBudgeted += item.budgetedAmount;
    totalActual += item.actualAmount ?? 0;
    totalPrevious += item.previousActual;
  }

  final headerRow = pw.TableRow(
    decoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
    children: [
      _headerCell('Account', font),
      _headerCell('Prev Year', font, alignment: pw.Alignment.centerRight),
      _headerCell('Budgeted', font, alignment: pw.Alignment.centerRight),
      _headerCell('Actual', font, alignment: pw.Alignment.centerRight),
      _headerCell('Variance', font, alignment: pw.Alignment.centerRight),
      _headerCell('Util%', font, alignment: pw.Alignment.centerRight),
    ],
  );

  final dataRows = items.map((item) {
    final variance = item.variance;
    final util = item.utilizationPercent;

    return pw.TableRow(children: [
      _cell(item.accountName ?? '—', font),
      _cell(item.previousActual > 0 ? fmt(item.previousActual) : '-', font,
          alignment: pw.Alignment.centerRight, color: PdfColors.grey700),
      _cell(fmt(item.budgetedAmount), font, alignment: pw.Alignment.centerRight),
      _cell(
          item.actualAmount != null ? fmt(item.actualAmount!) : '-', font,
          alignment: pw.Alignment.centerRight),
      _cell(
        variance != null ? fmt(variance) : '-',
        font,
        alignment: pw.Alignment.centerRight,
        color: variance != null && variance > 0
            ? PdfColors.red700
            : PdfColors.green700,
      ),
      _cell(
        util != null ? '${util.toStringAsFixed(1)}%' : '-',
        font,
        alignment: pw.Alignment.centerRight,
        color: util != null && util > 100 ? PdfColors.red700 : PdfColors.green700,
      ),
    ]);
  }).toList();

  final totalRow = pw.TableRow(
    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
    children: [
      _cell('TOTAL', font, bold: true),
      _cell(fmt(totalPrevious), font,
          bold: true, alignment: pw.Alignment.centerRight),
      _cell(fmt(totalBudgeted), font,
          bold: true, alignment: pw.Alignment.centerRight),
      _cell(fmt(totalActual), font,
          bold: true, alignment: pw.Alignment.centerRight),
      _cell(fmt(totalActual - totalBudgeted), font,
          bold: true,
          alignment: pw.Alignment.centerRight,
          color: totalActual - totalBudgeted > 0
              ? PdfColors.red800
              : PdfColors.green800),
      _cell(
        totalBudgeted == 0
            ? '-'
            : '${((totalActual / totalBudgeted) * 100).toStringAsFixed(1)}%',
        font,
        bold: true,
        alignment: pw.Alignment.centerRight,
      ),
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
            'Budget Report — ${budget.name}',
            style: pw.TextStyle(
                fontSize: 20, fontWeight: pw.FontWeight.bold, font: font),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          '${budget.yearLabel} · ${budget.type.label} · ${budget.yearType.shortLabel}',
          style: pw.TextStyle(fontSize: 12, font: font, color: PdfColors.grey700),
        ),
        pw.Text(
          'Status: ${budget.status.label}',
          style: pw.TextStyle(fontSize: 12, font: font, color: PdfColors.grey700),
        ),
        if (budget.notes != null && budget.notes!.isNotEmpty)
          pw.Text(
            budget.notes!,
            style: pw.TextStyle(
                fontSize: 10, font: font, fontStyle: pw.FontStyle.italic),
          ),
        pw.SizedBox(height: 16),

        // ── Summary Box ──
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _summaryLine('Total Budgeted', totalBudgeted, currency, font),
              _summaryLine('Total Actual (YTD)', totalActual, currency, font,
                  color: totalActual > totalBudgeted
                      ? PdfColors.red700
                      : PdfColors.green700),
              _summaryLine('Previous Year Total', totalPrevious, currency, font,
                  color: PdfColors.grey700),
              pw.Divider(),
              _summaryLine('Remaining Balance',
                  totalBudgeted - totalActual, currency, font,
                  bold: true,
                  color: totalBudgeted - totalActual < 0
                      ? PdfColors.red700
                      : PdfColors.green700),
            ],
          ),
        ),
        pw.SizedBox(height: 20),

        // ── Data Table ──
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FixedColumnWidth(64),
            2: const pw.FixedColumnWidth(64),
            3: const pw.FixedColumnWidth(64),
            4: const pw.FixedColumnWidth(64),
            5: const pw.FixedColumnWidth(50),
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
  final fileName =
      'budget_${budget.yearLabel}_${budget.type.name}.pdf'.replaceAll(' ', '_');

  if (kIsWeb) {
    await SharePlus.instance.share(ShareParams(
      files: [
        XFile.fromData(
          Uint8List.fromList(pdfBytes),
          name: fileName,
          mimeType: 'application/pdf',
        ),
      ],
      text: 'Budget Report — ${budget.name}',
    ));
  } else {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
      text: 'Budget Report — ${budget.name}',
    ));
  }
}

pw.Widget _headerCell(String text, pw.Font font,
    {pw.Alignment alignment = pw.Alignment.centerLeft}) {
  return pw.Container(
    alignment: alignment,
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    child: pw.Text(text,
        style: pw.TextStyle(
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
            fontSize: 9,
            font: font)),
  );
}

pw.Widget _cell(String text, pw.Font font,
    {pw.Alignment alignment = pw.Alignment.centerLeft,
    PdfColor? color,
    bool bold = false}) {
  return pw.Container(
    alignment: alignment,
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    child: pw.Text(text,
        style: pw.TextStyle(
            fontSize: 8,
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