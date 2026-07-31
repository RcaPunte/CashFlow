import 'dart:io';
import 'package:cashledger/ledger/model/ledger_entry.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

class LedgerPdfExporter {
  static Future<void> export({
    required List<LedgerEntry> entries,
    required String title,
    required double openingBalance,
  }) async {
    final pdf = pw.Document();
    final df = DateFormat('dd MMM yyyy');

    double running = openingBalance;
    double totalIn = 0;
    double totalOut = 0;

    for (final e in entries) {
      if (e.type == 'debit') {
        totalIn += e.amount;
        running += e.amount;
      } else {
        totalOut += e.amount;
        running -= e.amount;
      }
    }

    final closingBalance = running;

    // Build table rows
    final headerRow = pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.blueAccent),
      children: [
        _headerCell('Date', alignment: pw.Alignment.center),
        _headerCell('Account', alignment: pw.Alignment.centerLeft),
        _headerCell('Particulars', alignment: pw.Alignment.centerLeft),
        _headerCell('Receipts', alignment: pw.Alignment.centerRight),
        _headerCell('Expenses', alignment: pw.Alignment.centerRight),
        _headerCell('Balance', alignment: pw.Alignment.centerRight),
      ],
    );

    final dataRows = entries.map((e) {
      final isDebit = e.type == 'debit';
      return pw.TableRow(children: [
        _cell(df.format(e.date), alignment: pw.Alignment.center),
        _cell(e.accountName, alignment: pw.Alignment.centerLeft),
        _cell(e.description ?? '', alignment: pw.Alignment.centerLeft),
        _cell(
          isDebit ? e.amount.toStringAsFixed(2) : '',
          alignment: pw.Alignment.centerRight,
          color: PdfColors.green900,
        ),
        _cell(
          !isDebit ? e.amount.toStringAsFixed(2) : '',
          alignment: pw.Alignment.centerRight,
          color: PdfColors.red900,
        ),
        _cell(
          e.type == 'debit'
              ? e.amount.toStringAsFixed(2)
              : '',
          alignment: pw.Alignment.centerRight,
          color: PdfColors.green900,
        ),
      ]);
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          /// 🔹 Title
          pw.Header(
            level: 0,
            child: pw.Text('Ledger Statement',
                style: const pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text(
            'Account: $title',
            style: const pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),

          /// 🔹 Summary bar
          pw.Row(children: [
            pw.Text('Opening: ${openingBalance.toStringAsFixed(2)}',
                style: const pw.TextStyle(fontSize: 10)),
            pw.Spacer(),
            pw.Text('In: ${totalIn.toStringAsFixed(2)}',
                style: const pw.TextStyle(fontSize: 10)),
            pw.Spacer(),
            pw.Text('Out: ${totalOut.toStringAsFixed(2)}',
                style: const pw.TextStyle(fontSize: 10)),
            pw.Spacer(),
            pw.Text('Closing: ${closingBalance.toStringAsFixed(2)}',
                style: const pw.TextStyle(
                    fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ]),
          pw.SizedBox(height: 12),

          /// 🔹 Ledger Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(72),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(3),
              3: const pw.FixedColumnWidth(70),
              4: const pw.FixedColumnWidth(70),
              5: const pw.FixedColumnWidth(70),
            },
            children: [headerRow, ...dataRows],
          ),

          pw.SizedBox(height: 16),

          /// 🔹 Summary Section
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _summaryRow('Total Receipts', totalIn),
                _summaryRow('Total Expenses', totalOut),
                pw.Divider(),
                _summaryRow('Closing Balance', closingBalance, bold: true),
              ],
            ),
          ),

          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.bottomRight,
            child: pw.Text(
              'Generated: ${DateFormat('yyyy-MM-dd hh:mm:ss').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
        ],
      ),
    );

    final pdfBytes = await pdf.save();

    final fileName =
        'ledger_${DateTime.now().millisecondsSinceEpoch}.pdf';

    if (kIsWeb) {
      await SharePlus.instance.share(ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(pdfBytes),
            name: fileName,
            mimeType: 'application/pdf',
          ),
        ],
        text: 'Ledger Statement',
      ));
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text: 'Ledger Statement',
      ));
    }
  }

  static pw.Widget _headerCell(String text,
      {pw.Alignment alignment = pw.Alignment.centerLeft}) {
    return pw.Container(
      alignment: alignment,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(text,
          style: const pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 10)),
    );
  }

  static pw.Widget _cell(String text,
      {pw.Alignment alignment = pw.Alignment.centerLeft,
      PdfColor? color,
      bool bold = false}) {
    return pw.Container(
      alignment: alignment,
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text,
          style: pw.TextStyle(
              fontSize: 9,
              color: color ?? PdfColors.black,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
  }

  static pw.Widget _summaryRow(String label, double value,
      {bool bold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: 12,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text(value.toStringAsFixed(2),
            style: pw.TextStyle(
                fontSize: 12,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ],
    );
  }
}

class LedgerExcelExporter {
  static Future<void> export({
    required List<LedgerEntry> entries,
    required double openingBalance,
  }) async {
    final workbook = Workbook();
    final sheet = workbook.worksheets[0];
    final df = DateFormat('dd MMM yyyy');

    double totalIn = 0;
    double totalOut = 0;
    double running = openingBalance;

    for (final e in entries) {
      if (e.type == 'debit') {
        totalIn += e.amount;
      } else {
        totalOut += e.amount;
      }
    }

    final closingBalance = openingBalance + totalIn - totalOut;

    // ── Title ──
    sheet.getRangeByName('A1:F1')
      ..setText('Ledger Statement')
      ..merge()
      ..cellStyle.bold = true;
    sheet.getRangeByName('A1:F1').cellStyle.fontSize = 16;

    // ── Summary Section ──
    int row = 3;
    final summaryItems = [
      ['Opening Balance', openingBalance.toStringAsFixed(2)],
      ['Total Receipts', totalIn.toStringAsFixed(2)],
      ['Total Expenses', totalOut.toStringAsFixed(2)],
      ['Closing Balance', closingBalance.toStringAsFixed(2)],
    ];
    for (final item in summaryItems) {
      sheet.getRangeByIndex(row, 1).setText(item[0]);
      sheet.getRangeByIndex(row, 1).cellStyle.bold = true;
      sheet.getRangeByIndex(row, 2).setText(item[1]);
      row++;
    }
    row++; // blank row

    // ── Header ──
    final headers = [
      'Date',
      'Account',
      'Description',
      'Receipts (₹)',
      'Expenses (₹)',
      'Balance (₹)',
    ];
    for (int c = 0; c < headers.length; c++) {
      final cell = sheet.getRangeByIndex(row, c + 1);
      cell.setText(headers[c]);
      cell.cellStyle.bold = true;
      cell.cellStyle.backColor = '#D9E1F2';
      cell.cellStyle.hAlign = HAlignType.center;
    }
    row++;

    // ── Data Rows ──
    for (final e in entries) {
      running += e.type == 'debit' ? e.amount : -e.amount;

      sheet.getRangeByIndex(row, 1).setText(df.format(e.date));
      sheet.getRangeByIndex(row, 2).setText(e.accountName);
      sheet.getRangeByIndex(row, 3).setText(e.description ?? '');
      sheet.getRangeByIndex(row, 4).setNumber(
          e.type == 'debit' ? e.amount : 0);
      sheet.getRangeByIndex(row, 5).setNumber(
          e.type == 'credit' ? e.amount : 0);
      sheet.getRangeByIndex(row, 6).setNumber(running);
      row++;
    }

    // ── Totals Row ──
    sheet.getRangeByIndex(row, 3).setText('TOTAL');
    sheet.getRangeByIndex(row, 3).cellStyle.bold = true;
    sheet.getRangeByIndex(row, 4).setNumber(totalIn);
    sheet.getRangeByIndex(row, 4).cellStyle.bold = true;
    sheet.getRangeByIndex(row, 5).setNumber(totalOut);
    sheet.getRangeByIndex(row, 5).cellStyle.bold = true;
    sheet.getRangeByIndex(row, 6).setNumber(closingBalance);
    sheet.getRangeByIndex(row, 6).cellStyle.bold = true;

    for (int c = 1; c <= 6; c++) {
      sheet.autoFitColumn(c);
    }

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final fileName =
        'ledger_${DateTime.now().millisecondsSinceEpoch}.xlsx';

    if (kIsWeb) {
      await SharePlus.instance.share(ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(bytes),
            name: fileName,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        text: 'Ledger Statement',
      ));
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text: 'Ledger Statement',
      ));
    }
  }
}