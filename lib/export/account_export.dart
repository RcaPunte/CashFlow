import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column;

class AccountExportUtils {
  /// Open export options (PDF + Excel)
  static Future<void> openExportSheet({
    required context,
    required Map<String, Map<String, double>> totals,
    required List<dynamic> accounts,
  }) async {
    DateTime selectedMonth = DateTime.now();

    // await showCupertinoModalPopup(
    //   context: context,
    //   builder: (_) => Material(
    //     child: CupertinoDatePicker(
    //       mode: CupertinoDatePickerMode.monthYear,
    //       initialDateTime: selectedMonth,
    //       onDateTimeChanged: (v) => selectedMonth = v,
    //     ),
    //   ),
    // );

    final monthLabel = DateFormat('MMMM yyyy').format(selectedMonth);

    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text('Export Accounts ($monthLabel)'),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('Export as PDF'),
            onPressed: () async {
              await exportToPDF(
                totals: totals,
                accounts: accounts,
                monthLabel: monthLabel,
              );
              Navigator.pop(context);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Export as Excel'),
            onPressed: () async {
              await exportToExcel(
                totals: totals,
                accounts: accounts,
                monthLabel: monthLabel,
              );
              Navigator.pop(context);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  // -------------------- PDF EXPORT ----------------------

  static Future<void> exportToPDF({
    required Map<String, Map<String, double>> totals,
    required List<dynamic> accounts,
    required String monthLabel,
  }) async {
    final pdf = pw.Document();

    // Optional: include logo
    final logoBytes = await _tryLoadLogo();

    final totalIn = totals.values.fold(0.0, (s, v) => s + (v['in'] ?? 0));
    final totalOut = totals.values.fold(0.0, (s, v) => s + (v['out'] ?? 0));
    final netBalance = totalIn - totalOut;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => _buildHeader(monthLabel, logoBytes),
        footer: (context) => _buildFooter(),
        build: (context) => [
          pw.Table.fromTextArray(
            headers: [
              'Account Name',
              'Total In (₹)',
              'Total Out (₹)',
              'Balance (₹)',
            ],
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
            columnWidths: {
              0: const pw.FlexColumnWidth(2.5),
              1: const pw.FlexColumnWidth(1.2),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(1.2),
            },
            data: [
              for (final acc in accounts)
                [
                  acc.name,
                  (totals[acc.id]?['in'] ?? 0).toStringAsFixed(2),
                  (totals[acc.id]?['out'] ?? 0).toStringAsFixed(2),
                  ((totals[acc.id]?['in'] ?? 0) - (totals[acc.id]?['out'] ?? 0))
                      .toStringAsFixed(2),
                ],
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total In: ₹${totalIn.toStringAsFixed(2)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Total Out: ₹${totalOut.toStringAsFixed(2)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Net: ₹${netBalance.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    final dir = await getTemporaryDirectory();
    final path = "${dir.path}/cashbook_$monthLabel.pdf";
    final file = File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(await pdf.save());

    await Share.shareXFiles([
      XFile(file.path),
    ], text: "Cashbook PDF Export ($monthLabel)");
    // await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static pw.Widget _buildHeader(String monthLabel, Uint8List? logoBytes) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          if (logoBytes != null)
            pw.Image(pw.MemoryImage(logoBytes), height: 40),
          pw.Text(
            'Account Summary Report\n$monthLabel',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.right,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Generated on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
      ),
    );
  }

  static Future<Uint8List?> _tryLoadLogo() async {
    try {
      final data = await rootBundle.load('assets/logo.png');
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  // -------------------- EXCEL EXPORT ----------------------

  static Future<void> exportToExcel({
    required Map<String, Map<String, double>> totals,
    required List<dynamic> accounts,
    required String monthLabel,
  }) async {
    final workbook = Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Accounts - $monthLabel';

    // Title Row
    sheet.getRangeByIndex(1, 1).setText('Account Summary Report – $monthLabel');
    sheet.getRangeByIndex(1, 1, 1, 4).merge();
    sheet.getRangeByIndex(1, 1).cellStyle.fontSize = 16;
    sheet.getRangeByIndex(1, 1).cellStyle.bold = true;

    // Headers
    final headers = [
      'Account Name',
      'Total In (₹)',
      'Total Out (₹)',
      'Balance (₹)',
    ];
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.getRangeByIndex(3, i + 1);
      cell.setText(headers[i]);
      cell.cellStyle.bold = true;
      cell.cellStyle.backColor = '#E0E0E0';
    }

    // Data rows
    for (int i = 0; i < accounts.length; i++) {
      final acc = accounts[i];
      sheet.getRangeByIndex(i + 4, 1).setText(acc.name);
      sheet.getRangeByIndex(i + 4, 2).setNumber(totals[acc.id]?['in'] ?? 0);
      sheet.getRangeByIndex(i + 4, 3).setNumber(totals[acc.id]?['out'] ?? 0);
      sheet
          .getRangeByIndex(i + 4, 4)
          .setNumber(
            (totals[acc.id]?['in'] ?? 0) - (totals[acc.id]?['out'] ?? 0),
          );
    }

    // Totals row
    final row = accounts.length + 5;
    final totalIn = totals.values.fold(0.0, (s, v) => s + (v['in'] ?? 0));
    final totalOut = totals.values.fold(0.0, (s, v) => s + (v['out'] ?? 0));
    final net = totalIn - totalOut;

    sheet.getRangeByIndex(row, 1).setText('Totals');
    sheet.getRangeByIndex(row, 2).setNumber(totalIn);
    sheet.getRangeByIndex(row, 3).setNumber(totalOut);
    sheet.getRangeByIndex(row, 4).setNumber(net);
    sheet.getRangeByIndex(row, 1, row, 4).cellStyle.bold = true;

    // Auto-fit
    sheet.autoFitColumn(1);

    final bytes = workbook.saveAsStream();
    workbook.dispose();

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Accounts_$monthLabel.xlsx');
    await file.writeAsBytes(bytes, flush: true);

    // await Printing.sharePdf(
    //   bytes: bytes,
    //   filename: 'Accounts_$monthLabel.xlsx',
    // );
  }
}
