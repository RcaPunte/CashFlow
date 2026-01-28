import 'dart:io';
import 'package:cashledger/ledger/model/ledger_entry.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
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

    final tableRows = <List<String>>[];

    for (final e in entries) {
      if (e.type == 'debit') {
        totalIn += e.amount;
        running += e.amount;
      } else {
        totalOut += e.amount;
        running -= e.amount;
      }

      tableRows.add([
        df.format(e.date),
        e.description!,
        e.type == 'debit' ? e.amount.toStringAsFixed(2) : '',
        e.type == 'credit' ? e.amount.toStringAsFixed(2) : '',
        running.toStringAsFixed(2),
      ]);
    }

    final closingBalance = running;

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          /// 🔹 Title
          pw.Text(
            "Ledger Statement",
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            "Account : $title",
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),

          /// 🔹 Opening Balance
          pw.Text(
            'Opening Balance: ${openingBalance.toStringAsFixed(2)}',
            style: const pw.TextStyle(fontSize: 12),
          ),

          pw.SizedBox(height: 16),

          /// 🔹 Ledger Table
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(width: .5),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellPadding: const pw.EdgeInsets.all(6),
            headers: ['Date', 'Description', 'In', 'Out', 'Balance'],
            data: tableRows,
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
                _summaryRow('Total In', totalIn),
                _summaryRow('Total Out', totalOut),
                pw.Divider(),
                _summaryRow('Closing Balance', closingBalance, bold: true),
              ],
            ),
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/ledger_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );

    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }

  /// 🔹 Summary Row Helper
  static pw.Widget _summaryRow(
    String label,
    double value, {
    bool bold = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value.toStringAsFixed(2),
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
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

    sheet.getRangeByName('A1:E1')
      ..setText('Ledger Statement')
      ..merge();

    sheet.getRangeByName('A3').setText('Date');
    sheet.getRangeByName('B3').setText('Description');
    sheet.getRangeByName('C3').setText('In');
    sheet.getRangeByName('D3').setText('Out');
    sheet.getRangeByName('E3').setText('Balance');

    double running = openingBalance;
    int row = 4;

    for (final e in entries) {
      running += e.type == 'debit' ? e.amount : -e.amount;

      sheet.getRangeByIndex(row, 1).setText(df.format(e.date));
      sheet.getRangeByIndex(row, 2).setText(e.description);
      sheet.getRangeByIndex(row, 3).setNumber(e.type == 'debit' ? e.amount : 0);
      sheet
          .getRangeByIndex(row, 4)
          .setNumber(e.type == 'credit' ? e.amount : 0);
      sheet.getRangeByIndex(row, 5).setNumber(running);

      row++;
    }

    final bytes = workbook.saveAsStream();
    workbook.dispose();

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/ledger_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );

    await file.writeAsBytes(bytes, flush: true);
    await OpenFilex.open(file.path);
  }
}
