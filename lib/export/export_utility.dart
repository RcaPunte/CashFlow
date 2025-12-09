import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'dart:html' as html;

class ExportUtils {
  static Future<void> openDirectExport({
    required BuildContext context,
    required List<Map<String, dynamic>> entries,
    required double openingBl,
  }) async {
    // DateTime selectedDate = DateTime.now();

    final monthLabel = DateFormat(
      'MMMM_yyyy',
    ).format(DateTime.parse(entries.first['date']));

    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text('Export Cashbook ($monthLabel)'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              ExportUtils.exportCashBookToExcel(entries, monthLabel);
              Navigator.pop(context);
            },
            child: const Text('📊 Export as Excel'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              if (kIsWeb) {
                ExportUtils().generateCashbookPdfWeb(
                  entries: entries,
                  monthLabel: monthLabel,
                  openingBl: openingBl,
                );
              } else {
                ExportUtils().generateCashbookPdf(
                  entries: entries,
                  monthLabel: monthLabel,
                  openingBl: openingBl,
                );
              }
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
      builder: (_) {
        return Container(
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
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Select Month',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () => Navigator.pop(context, selectedDate),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.monthYear,
                  initialDateTime: selectedDate,
                  onDateTimeChanged: (date) {
                    selectedDate = date;
                  },
                ),
              ),
            ],
          ),
        );
      },
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
                ExportUtils.exportCashBookToExcel(entries, monthLabel);
                Navigator.pop(context);
              },
              child: const Text('📊 Export as Excel'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                ExportUtils().generateCashbookPdf(
                  entries: entries,
                  monthLabel: monthLabel,
                  openingBl: openingBl,
                );
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

  /// ✅ Export as Excel using Syncfusion
  static Future<void> exportCashBookToExcel(
    List<Map<String, dynamic>> entries,
    String monthLabel,
  ) async {
    // Create a new workbook
    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = "Cashbook $monthLabel";

    // Header Row
    final headers = ["Date", "Description", "Receipts", "Expenses", "Amount"];
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.getRangeByIndex(1, i + 1);
      cell.setText(headers[i]);
      cell.cellStyle.bold = true;
      cell.cellStyle.backColor = "#D9E1F2";
      cell.cellStyle.hAlign = xlsio.HAlignType.center;
    }

    // Data Rows
    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      sheet.getRangeByIndex(i + 2, 1).setText(e['date'] ?? '');
      sheet.getRangeByIndex(i + 2, 2).setText(e['description'] ?? '');
      sheet
          .getRangeByIndex(i + 2, 3)
          .setNumber(
            double.tryParse(e['type'] == "debit" ? e['amount'] : 0) ?? 0,
          );
      sheet
          .getRangeByIndex(i + 2, 4)
          .setNumber(double.tryParse(e['type'] == "credit" ? e['amount'] : 0));
      //  sheet.getRangeByIndex(i + 2, 3).setText(   e['type'] == "debit" ? e['amount'] : 0);
      //  sheet.getRangeByIndex(i + 2, 4).setText(e['type'] == "credit" ? e['amount'] : 0);

      // sheet
      //     .getRangeByIndex(i + 2, 5)
      //     .setNumber(double.tryParse(e['amount']?.toString() ?? '0') ?? 0);
    }

    // Auto-fit columns
    sheet.autoFitColumn(1);
    sheet.autoFitColumn(2);
    sheet.autoFitColumn(3);
    sheet.autoFitColumn(4);
    sheet.autoFitColumn(5);

    // Footer Summary (if applicable)
    final totalRow = entries.length + 3;
    sheet.getRangeByIndex(totalRow, 4).setText("Total");
    sheet.getRangeByIndex(totalRow, 4).cellStyle.bold = true;
    sheet
        .getRangeByIndex(totalRow, 5)
        .setFormula(
          "=SUM(E2:E${entries.length + 1})",
        ); // Summing all amounts in column E

    // Save and share
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final dir = await getTemporaryDirectory();
    final path = "${dir.path}/cashbook_$monthLabel.xlsx";
    final file = File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);

    await Share.shareXFiles([
      XFile(file.path),
    ], text: "Cashbook Excel Export ($monthLabel)");
  }

  /// ✅ Export as PDF

  static Future<void> exportCashBookToPDF1(
    List<Map<String, dynamic>> entries,
    String monthLabel,
  ) async {
    final pdf = pw.Document();

    // Calculate totals
    final totalReceipts = entries
        .where((e) => e['type'] == 'debit')
        .fold<double>(0, (sum, e) => sum + (e['amount'] ?? 0).toDouble());

    final totalExpenses = entries
        .where((e) => e['type'] == 'credit')
        .fold<double>(0, (sum, e) => sum + (e['amount'] ?? 0).toDouble());

    final balance = totalReceipts - totalExpenses;

    // Format date in table rows
    final dateFormat = DateFormat('dd MMM yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              "Cashbook Report – $monthLabel",
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),

          // 🧾 Transaction Table
          pw.Table.fromTextArray(
            headers: ["Date", "Description", "Receipts", "Expenses"],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFFFFFFFF),
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF007AFF),
            ),
            cellAlignment: pw.Alignment.centerLeft,
            data: entries.map((e) {
              return [
                dateFormat.format(DateTime.parse(e['date'])),
                e['description'] ?? '',
                e['type'] == "debit" ? e['amount'].toStringAsFixed(2) : '',
                e['type'] == "credit" ? e['amount'].toStringAsFixed(2) : '',
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 20),

          // 🧮 Summary Row Section
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromInt(0xFFCCCCCC)),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Summary",
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF007AFF),
                  ),
                ),
                pw.Divider(),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Total Receipts:"),
                    pw.Text(
                      "₹${totalReceipts.toStringAsFixed(2)}",
                      style: const pw.TextStyle(
                        color: PdfColor.fromInt(0xFF00A86B),
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Total Expenses:"),
                    pw.Text(
                      "₹${totalExpenses.toStringAsFixed(2)}",
                      style: const pw.TextStyle(
                        color: PdfColor.fromInt(0xFFFF3B30),
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "Closing Balance:",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      "₹${balance.toStringAsFixed(2)}",
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: balance >= 0
                            ? const PdfColor.fromInt(0xFF00A86B)
                            : const PdfColor.fromInt(0xFFFF3B30),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Save or share PDF file
    // Example:
    // final output = await getTemporaryDirectory();
    // final file = File("${output.path}/Cashbook_$monthLabel.pdf");
    // await file.writeAsBytes(await pdf.save());
    // await Share.shareXFiles([XFile(file.path)], text: 'Cashbook $monthLabel');
  }

  Future<void> generateCashbookPdfWeb({
    required List<Map<String, dynamic>> entries,
    required String monthLabel,
    required double openingBl,
  }) async {
    final pdf = pw.Document();

    double totalReceipts = 0;
    double totalExpenses = 0;

    for (var e in entries) {
      if (e['type'] == "debit") {
        totalReceipts += (e['amount'] ?? 0).toDouble();
      } else if (e['type'] == "credit") {
        totalExpenses += (e['amount'] ?? 0).toDouble();
      }
    }

    final closingBalance = (openingBl + totalReceipts) - totalExpenses;

    final textStyle = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              "Kanan Corps SAY Cash Book Report - $monthLabel",
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Text("Opening Balance : $openingBl", style: textStyle),
              pw.Spacer(),
              pw.Text("Total Income : $totalReceipts", style: textStyle),
              pw.Spacer(),
              pw.Text("Total Expenses : $totalExpenses", style: textStyle),
              pw.Spacer(),
              pw.Text("Closing Balance : $closingBalance", style: textStyle),
            ],
          ),
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
                  _headerCell(
                    "Description",
                    alignment: pw.Alignment.centerLeft,
                  ),
                  _headerCell("Receipts", alignment: pw.Alignment.centerRight),
                  _headerCell("Expenses", alignment: pw.Alignment.centerRight),
                ],
              ),
              ...entries.map((e) {
                final isDebit = e['type'] == "debit";
                final isCredit = e['type'] == "credit";
                return pw.TableRow(
                  children: [
                    _cell(
                      DateFormat(
                        'dd MMM yyyy',
                      ).format(DateTime.parse(e['date'])),
                      alignment: pw.Alignment.center,
                    ),
                    _cell(
                      e['description'] ?? '',
                      alignment: pw.Alignment.centerLeft,
                    ),
                    _cell(
                      isDebit ? e['amount'].toStringAsFixed(2) : "",
                      alignment: pw.Alignment.centerRight,
                      color: PdfColors.green900,
                    ),
                    _cell(
                      isCredit ? e['amount'].toStringAsFixed(2) : "",
                      alignment: pw.Alignment.centerRight,
                      color: PdfColors.red900,
                    ),
                  ],
                );
              }),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _cell(""),
                  _cell("Total", bold: true, alignment: pw.Alignment.center),
                  _cell(
                    totalReceipts.toStringAsFixed(2),
                    alignment: pw.Alignment.centerRight,
                    bold: true,
                    color: PdfColors.green800,
                  ),
                  _cell(
                    totalExpenses.toStringAsFixed(2),
                    alignment: pw.Alignment.centerRight,
                    bold: true,
                    color: PdfColors.red800,
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Align(
            alignment: pw.Alignment.bottomRight,
            child: pw.Text(
              "Generated At ${DateFormat('yyyy-MM-dd hh:mm:ss').format(DateTime.now())}",
              style: pw.TextStyle(fontSize: 8),
            ),
          ),
        ],
      ),
    );

    // 📌 WEB DOWNLOAD — Important Part
    final bytes = await pdf.save();

    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..download = "Cashbook_Report_$monthLabel.pdf"
      ..click();

    html.Url.revokeObjectUrl(url); // Cleanup
  }

  Future<void> generateCashbookPdf({
    required List<Map<String, dynamic>> entries,
    required String monthLabel,
    required double openingBl,
  }) async {
    final pdf = pw.Document();

    // Calculate totals
    double totalReceipts = 0;
    double totalExpenses = 0;
    for (var e in entries) {
      if (e['type'] == "debit") {
        totalReceipts += (e['amount'] ?? 0).toDouble();
      } else if (e['type'] == "credit") {
        totalExpenses += (e['amount'] ?? 0).toDouble();
      }
    }
    final closingBalance = (openingBl + totalReceipts) - totalExpenses;
    final textStyle = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
    );
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              "Kanan Corps SAY Cash Book Report - $monthLabel",
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Text("Opening Balance : $openingBl", style: textStyle),
              pw.Spacer(),
              pw.Text("Total Income : $totalReceipts", style: textStyle),
              pw.Spacer(),
              pw.Text("Total Expenses : $totalExpenses", style: textStyle),
              pw.Spacer(),
              pw.Text("Closing Balance : $closingBalance", style: textStyle),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FixedColumnWidth(80), // Date
              1: const pw.FlexColumnWidth(3), // Description
              2: const pw.FixedColumnWidth(70), // Receipts
              3: const pw.FixedColumnWidth(70), // Expenses
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blueAccent),
                children: [
                  _headerCell("Date", alignment: pw.Alignment.center),
                  _headerCell(
                    "Description",
                    alignment: pw.Alignment.centerLeft,
                  ),
                  _headerCell("Receipts", alignment: pw.Alignment.centerRight),
                  _headerCell("Expenses", alignment: pw.Alignment.centerRight),
                ],
              ),

              // Data rows
              ...entries.map((e) {
                final isDebit = e['type'] == "debit";
                final isCredit = e['type'] == "credit";
                return pw.TableRow(
                  children: [
                    _cell(
                      DateFormat(
                        'dd MMM yyyy',
                      ).format(DateTime.parse(e['date'])),
                      alignment: pw.Alignment.center,
                    ),
                    _cell(
                      e['description'] ?? '',
                      alignment: pw.Alignment.centerLeft,
                    ),
                    _cell(
                      isDebit ? "${e['amount'].toStringAsFixed(2)}" : "",
                      color: PdfColors.green900,
                      alignment: pw.Alignment.centerRight,
                    ),
                    _cell(
                      isCredit ? "${e['amount'].toStringAsFixed(2)}" : "",
                      color: PdfColors.red900,
                      alignment: pw.Alignment.centerRight,
                    ),
                  ],
                );
              }),

              // Totals row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _cell("", alignment: pw.Alignment.centerLeft),
                  _cell("Total", bold: true, alignment: pw.Alignment.center),
                  _cell(
                    totalReceipts.toStringAsFixed(2),
                    alignment: pw.Alignment.centerRight,
                    color: PdfColors.green800,
                    bold: true,
                  ),
                  _cell(
                    totalExpenses.toStringAsFixed(2),
                    alignment: pw.Alignment.centerRight,
                    color: PdfColors.red800,
                    bold: true,
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Align(
            alignment: pw.Alignment.bottomRight,
            child: pw.Text(
              "Generated At ${DateFormat('yyyy-MM-dd hh:mm:ss').format(DateTime.now())}",
              style: pw.TextStyle(fontSize: 8),
            ),
          ),
        ],
      ),
    );

    // Save PDF to device
    // final dir = await getApplicationDocumentsDirectory();
    // final file = File("${dir.path}/Cashbook_Report_$monthLabel.pdf");
    // await file.writeAsBytes(await pdf.save());
    // print("✅ PDF saved at: ${file.path}");

    final dir = await getTemporaryDirectory();
    final path = "${dir.path}/cashbook_$monthLabel.pdf";
    final file = File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(await pdf.save());

    await Share.shareXFiles([
      XFile(file.path),
    ], text: "Cashbook PDF Export ($monthLabel)");
  }

  pw.Widget _headerCell(
    String text, {
    pw.Alignment alignment = pw.Alignment.centerLeft,
  }) {
    return pw.Container(
      alignment: alignment,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  pw.Widget _cell(
    String text, {
    pw.Alignment alignment = pw.Alignment.centerLeft,
    PdfColor? color,
    bool bold = false,
  }) {
    return pw.Container(
      alignment: alignment,
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          color: color ?? PdfColors.black,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static Future<void> exportCashBookToPDF(
    List<Map<String, dynamic>> entries,
    String monthLabel,
  ) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM, yy');
    final totalReceipts = entries
        .where((e) => e['type'] == 'debit')
        .fold<double>(0, (sum, e) => sum + (e['amount'] ?? 0).toDouble());

    final totalExpenses = entries
        .where((e) => e['type'] == 'credit')
        .fold<double>(0, (sum, e) => sum + (e['amount'] ?? 0).toDouble());

    final balance = totalReceipts - totalExpenses;
    pdf.addPage(
      pw.MultiPage(
        margin: pw.EdgeInsets.symmetric(horizontal: 30),
        build: (context) => [
          pw.Header(level: 0, text: "Cashbook Report – $monthLabel"),

          pw.Table.fromTextArray(
            //cellAlignment: pw.Alignment.center,
            columnWidths: {
              0: const pw.FixedColumnWidth(70), // 👈 Date column fixed width
              1: const pw.FlexColumnWidth(3), // Description expands
              2: const pw.FixedColumnWidth(68), // Receipts
              3: const pw.FixedColumnWidth(68), // Expenses
            },
            cellStyle: pw.TextStyle(fontSize: 10),
            headers: ["Date", "Description", "Receipts", "Expenses"],
            data: entries.map((e) {
              return [
                dateFormat.format(DateTime.parse(e['date'])),
                e['description'] ?? '',
                e['type'] == "debit" ? e['amount'].toStringAsFixed(2) : '',
                e['type'] == "credit" ? e['amount'].toStringAsFixed(2) : '',
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 20),

          // 🧮 Summary Row Section
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromInt(0xFFCCCCCC)),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Summary",
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF007AFF),
                  ),
                ),
                pw.Divider(),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Total Receipts:"),
                    pw.Text(
                      "₹${totalReceipts.toStringAsFixed(2)}",
                      style: const pw.TextStyle(
                        color: PdfColor.fromInt(0xFF00A86B),
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Total Expenses:"),
                    pw.Text(
                      "₹${totalExpenses.toStringAsFixed(2)}",
                      style: const pw.TextStyle(
                        color: PdfColor.fromInt(0xFFFF3B30),
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "Closing Balance:",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      "₹${balance.toStringAsFixed(2)}",
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: balance >= 0
                            ? const PdfColor.fromInt(0xFF00A86B)
                            : const PdfColor.fromInt(0xFFFF3B30),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
  }

  /// ✅ Export as Image
  // static Future<void> exportAsImage(
  //   ScreenshotController controller,
  //   String monthLabel,
  // ) async {
  //   final Uint8List? image = await controller.capture();
  //   if (image == null) return;

  //   final dir = await getTemporaryDirectory();
  //   final path = "${dir.path}/cashbook_$monthLabel.png";
  //   final file = File(path)..writeAsBytesSync(image);

  //   await Share.shareXFiles([
  //     XFile(file.path),
  //   ], text: "Cashbook Image Export ($monthLabel)");
  // }

  /// ✅ Export as CSV
  static Future<void> exportToCSV(
    List<Map<String, dynamic>> entries,
    String monthLabel,
  ) async {
    final csvContent = StringBuffer();
    csvContent.writeln("Date,Description,Account,Type,Amount");

    for (final e in entries) {
      csvContent.writeln(
        "${e['date']},${e['description'] ?? ''},${e['accounts']?['name'] ?? ''},${e['type']},${e['amount'] ?? 0}",
      );
    }

    final dir = await getTemporaryDirectory();
    final path = "${dir.path}/cashbook_$monthLabel.csv";
    final file = File(path)
      ..createSync(recursive: true)
      ..writeAsStringSync(csvContent.toString());

    await Share.shareXFiles([
      XFile(file.path),
    ], text: "Cashbook CSV Export ($monthLabel)");
  }
}
