import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

class ExportUtils {
  static Future<void> openDirectExport({
    required BuildContext context,
    required List<Map<String, dynamic>> entries,
    required double openingBl,
  }) async {
    final monthLabel = DateFormat('MMMM_yyyy')
        .format(DateTime.parse(entries.first['date']));

    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text('Export Cashbook ($monthLabel)'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              ExportUtils.exportCashBookToExcel(entries, monthLabel, openingBl);
              Navigator.pop(context);
            },
            child: const Text('📊 Export as Excel'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              ExportUtils().generateCashbookPdf(
                  entries: entries, monthLabel: monthLabel, openingBl: openingBl);
              Navigator.pop(context);
            },
            child: const Text('📄 Export as PDF'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              ExportUtils.exportToCSV(entries, monthLabel);
              Navigator.pop(context);
            },
            child: const Text('📑 Export as CSV'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  static Future<void> openCashBookExportSheet({
    required BuildContext context,
    required List<Map<String, dynamic>> entries,
    required double totalReceipts,
    required double totalExpenses,
    required double openingBl,
  }) async {
    DateTime selectedDate = DateTime.now();
    await showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Container(
              height: 50,
              color: CupertinoColors.systemGrey6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context)),
                  const Text('Select Month',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () => Navigator.pop(context, selectedDate)),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.monthYear,
                initialDateTime: selectedDate,
                onDateTimeChanged: (date) => selectedDate = date,
              ),
            ),
          ],
        ),
      ),
    ).then((pickedDate) async {
      if (pickedDate == null) return;
      final monthLabel = DateFormat('MMMM_yyyy').format(pickedDate);
      showCupertinoModalPopup(
        context: context,
        builder: (_) => CupertinoActionSheet(
          title: Text('Export Cashbook ($monthLabel)'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                ExportUtils.exportCashBookToExcel(entries, monthLabel, openingBl);
                Navigator.pop(context);
              },
              child: const Text('📊 Export as Excel'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                ExportUtils().generateCashbookPdf(
                    entries: entries, monthLabel: monthLabel, openingBl: openingBl);
                Navigator.pop(context);
              },
              child: const Text('📄 Export as PDF'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                ExportUtils.exportToCSV(entries, monthLabel);
                Navigator.pop(context);
              },
              child: const Text('📑 Export as CSV'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
      );
    });
  }

  /// Export as Excel with summary header
  static Future<void> exportCashBookToExcel(
    List<Map<String, dynamic>> entries,
    String monthLabel,
    double openingBl,
  ) async {
    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = "Cashbook $monthLabel";

    double totalDebit = 0;
    double totalCredit = 0;
    for (var e in entries) {
      final amt = (e['amount'] as num?)?.toDouble() ?? 0;
      if (e['type'] == 'debit') totalDebit += amt;
      else totalCredit += amt;
    }
    final totalIncome = openingBl + totalDebit;
    final balance = totalIncome - totalCredit;

    // ── Summary Section ──
    int row = 1;
    final summaryItems = [
      ["Opening Balance", openingBl.toStringAsFixed(2)],
      ["New Income (Receipts)", totalDebit.toStringAsFixed(2)],
      ["Total Income", totalIncome.toStringAsFixed(2)],
      ["Expenditure", totalCredit.toStringAsFixed(2)],
      ["Balance", balance.toStringAsFixed(2)],
    ];
    for (final item in summaryItems) {
      sheet.getRangeByIndex(row, 4).setText(item[0]);
      sheet.getRangeByIndex(row, 4).cellStyle.bold = true;
      sheet.getRangeByIndex(row, 5).setText(item[1]);
      row++;
    }
    row++; // blank row
    final dataStartRow = row;

    // ── Transaction Header ──
    final headers = ["Date", "Description", "Account", "Debit (₹)", "Credit (₹)"];
    for (int c = 0; c < headers.length; c++) {
      final cell = sheet.getRangeByIndex(row, c + 1);
      cell.setText(headers[c]);
      cell.cellStyle.bold = true;
      cell.cellStyle.backColor = "#D9E1F2";
      cell.cellStyle.hAlign = xlsio.HAlignType.center;
    }
    row++;

    // ── Data Rows ──
    for (var e in entries) {
      final amt = (e['amount'] as num?)?.toDouble() ?? 0;
      final isDebit = e['type'] == 'debit';
      sheet.getRangeByIndex(row, 1).setText(e['date'] ?? '');
      sheet.getRangeByIndex(row, 2).setText(e['description'] ?? '');
      sheet.getRangeByIndex(row, 3).setText(e['accounts']?['name'] ?? '');
      sheet.getRangeByIndex(row, 4).setNumber(isDebit ? amt : 0);
      sheet.getRangeByIndex(row, 5).setNumber(isDebit ? 0 : amt);
      row++;
    }

    // ── Totals Row ──
    sheet.getRangeByIndex(row, 3).setText('TOTAL');
    sheet.getRangeByIndex(row, 3).cellStyle.bold = true;
    sheet.getRangeByIndex(row, 4).setNumber(totalDebit);
    sheet.getRangeByIndex(row, 4).cellStyle.bold = true;
    sheet.getRangeByIndex(row, 5).setNumber(totalCredit);
    sheet.getRangeByIndex(row, 5).cellStyle.bold = true;

    for (int c = 1; c <= 5; c++) sheet.autoFitColumn(c);

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    if (kIsWeb) {
      await Share.shareXFiles([
        XFile.fromData(Uint8List.fromList(bytes),
            name: 'cashbook_$monthLabel.xlsx',
            mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
      ], text: "Cashbook Excel Export ($monthLabel)");
    } else {
      final dir = await getTemporaryDirectory();
      final path = "${dir.path}/cashbook_$monthLabel.xlsx";
      File(path)..createSync(recursive: true)..writeAsBytesSync(bytes);
      await Share.shareXFiles([XFile(path)], text: "Cashbook Excel Export ($monthLabel)");
    }
  }

  Future<void> generateCashbookPdf({
    required List<Map<String, dynamic>> entries,
    required String monthLabel,
    required double openingBl,
  }) async {
    final pdf = pw.Document();
    double totalReceipts = 0, totalExpenses = 0;
    for (var e in entries) {
      final amt = (e['amount'] ?? 0).toDouble();
      if (e['type'] == "debit") totalReceipts += amt;
      else totalExpenses += amt;
    }
    final closingBalance = (openingBl + totalReceipts) - totalExpenses;

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) => [
        pw.Header(level: 0, child: pw.Text("Cash Book Report - $monthLabel",
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 10),
        pw.Row(children: [
          pw.Text("OB: ${openingBl.toStringAsFixed(2)}"),
          pw.Spacer(),
          pw.Text("Income: ${totalReceipts.toStringAsFixed(2)}"),
          pw.Spacer(),
          pw.Text("Expense: ${totalExpenses.toStringAsFixed(2)}"),
          pw.Spacer(),
          pw.Text("Closing: ${closingBalance.toStringAsFixed(2)}",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ]),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          columnWidths: {
            0: const pw.FixedColumnWidth(80),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FixedColumnWidth(70),
            3: const pw.FixedColumnWidth(70),
          },
          children: [
            pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blueAccent),
                children: [
                  _headerCell("Date", alignment: pw.Alignment.center),
                  _headerCell("Description", alignment: pw.Alignment.centerLeft),
                  _headerCell("Receipts", alignment: pw.Alignment.centerRight),
                  _headerCell("Expenses", alignment: pw.Alignment.centerRight),
                ]),
            ...entries.map((e) {
              final isDebit = e['type'] == "debit";
              return pw.TableRow(children: [
                _cell(DateFormat('dd MMM yyyy').format(DateTime.parse(e['date'])),
                    alignment: pw.Alignment.center),
                _cell(e['description'] ?? '', alignment: pw.Alignment.centerLeft),
                _cell(isDebit ? e['amount'].toStringAsFixed(2) : "",
                    alignment: pw.Alignment.centerRight, color: PdfColors.green900),
                _cell(!isDebit ? e['amount'].toStringAsFixed(2) : "",
                    alignment: pw.Alignment.centerRight, color: PdfColors.red900),
              ]);
            }),
            pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _cell(""), _cell("Total", bold: true, alignment: pw.Alignment.center),
                  _cell(totalReceipts.toStringAsFixed(2), color: PdfColors.green800,
                      bold: true, alignment: pw.Alignment.centerRight),
                  _cell(totalExpenses.toStringAsFixed(2), color: PdfColors.red800,
                      bold: true, alignment: pw.Alignment.centerRight),
                ]),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Align(
            alignment: pw.Alignment.bottomRight,
            child: pw.Text(
                "Generated At ${DateFormat('yyyy-MM-dd hh:mm:ss').format(DateTime.now())}",
                style: const pw.TextStyle(fontSize: 8))),
      ],
    ));

    final pdfBytes = await pdf.save();
    if (kIsWeb) {
      await Share.shareXFiles([
        XFile.fromData(Uint8List.fromList(pdfBytes),
            name: 'cashbook_$monthLabel.pdf', mimeType: 'application/pdf'),
      ], text: "Cashbook PDF Export ($monthLabel)");
    } else {
      final dir = await getTemporaryDirectory();
      final path = "${dir.path}/cashbook_$monthLabel.pdf";
      File(path)..createSync(recursive: true)..writeAsBytesSync(pdfBytes);
      await Share.shareXFiles([XFile(path)], text: "Cashbook PDF Export ($monthLabel)");
    }
  }

  pw.Widget _headerCell(String text, {pw.Alignment alignment = pw.Alignment.centerLeft}) =>
      pw.Container(
          alignment: alignment,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: pw.Text(text,
              style: const pw.TextStyle(color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold, fontSize: 11)));

  pw.Widget _cell(String text, {pw.Alignment alignment = pw.Alignment.centerLeft,
    PdfColor? color, bool bold = false}) =>
      pw.Container(
          alignment: alignment,
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(text,
              style: pw.TextStyle(fontSize: 10,
                  color: color ?? PdfColors.black,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)));

  static Future<void> exportToCSV(
      List<Map<String, dynamic>> entries, String monthLabel) async {
    final csvContent = StringBuffer();
    csvContent.writeln("Date,Description,Account,Type,Amount");
    for (final e in entries) {
      csvContent.writeln(
          "${e['date']},${e['description'] ?? ''},${e['accounts']?['name'] ?? ''},${e['type']},${e['amount'] ?? 0}");
    }
    if (kIsWeb) {
      await Share.shareXFiles([
        XFile.fromData(Uint8List.fromList(csvContent.toString().codeUnits),
            name: 'cashbook_$monthLabel.csv', mimeType: 'text/csv'),
      ], text: "Cashbook CSV Export ($monthLabel)");
    } else {
      final dir = await getTemporaryDirectory();
      final path = "${dir.path}/cashbook_$monthLabel.csv";
      File(path)..createSync(recursive: true)..writeAsStringSync(csvContent.toString());
      await Share.shareXFiles([XFile(path)], text: "Cashbook CSV Export ($monthLabel)");
    }
  }
}