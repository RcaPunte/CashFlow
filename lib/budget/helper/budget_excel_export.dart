import 'dart:io';
import 'package:cashledger/budget/model/budget_item_model.dart';
import 'package:cashledger/budget/model/budget_model.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

/// Export budget report as Excel (.xlsx)
Future<void> exportBudgetExcel({
  required Budget budget,
  required List<BudgetItem> items,
  bool parentOnly = false,
}) async {
  final workbook = xlsio.Workbook();
  final sheet = workbook.worksheets[0];
  sheet.name = 'Budget ${budget.yearLabel}';

  // ── Totals ──
  double totalBudgeted = 0;
  double totalActual = 0;
  double totalPrevious = 0;
  for (final item in items) {
    totalBudgeted += item.budgetedAmount;
    totalActual += item.actualAmount ?? 0;
    totalPrevious += item.previousActual;
  }
  final totalVariance = totalActual - totalBudgeted;
  final utilization =
      totalBudgeted == 0 ? 0 : (totalActual / totalBudgeted) * 100;

  // ── Title ──
  sheet.getRangeByName('A1:F1')
    ..setText('Budget Report — ${budget.name}')
    ..merge()
    ..cellStyle.bold = true;
  sheet.getRangeByName('A1:F1').cellStyle.fontSize = 14;

  sheet.getRangeByName('A2:F2')
    ..setText(
        '${budget.yearLabel} | ${budget.type.label} | ${budget.yearType.shortLabel} | Status: ${budget.status.label}')
    ..merge()
    ..cellStyle.fontSize = 10;

  if (budget.notes != null && budget.notes!.isNotEmpty) {
    sheet.getRangeByName('A3:F3')
      ..setText(budget.notes!)
      ..merge()
      ..cellStyle.fontSize = 9
      ..cellStyle.italic = true;
  }

  // ── Summary Section ──
  int row = 5;
  final summaryItems = [
    ['Total Budgeted', totalBudgeted.toStringAsFixed(2)],
    ['Total Actual (YTD)', totalActual.toStringAsFixed(2)],
    ['Previous Year Total', totalPrevious.toStringAsFixed(2)],
    ['Variance', totalVariance.toStringAsFixed(2)],
    ['Utilization %', '${utilization.toStringAsFixed(1)}%'],
    ['Remaining Balance', (totalBudgeted - totalActual).toStringAsFixed(2)],
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
    'Account',
    'Previous Year',
    'Budgeted',
    'Actual',
    'Variance',
    'Utilization %',
  ];
  final headerRow = row;
  for (int c = 0; c < headers.length; c++) {
    final cell = sheet.getRangeByIndex(row, c + 1);
    cell.setText(headers[c]);
    cell.cellStyle.bold = true;
    cell.cellStyle.backColor = '#D9E1F2';
    cell.cellStyle.hAlign = xlsio.HAlignType.center;
  }
  row++;

  // ── Data Rows ──
  for (final item in items) {
    sheet.getRangeByIndex(row, 1).setText(item.accountName ?? '—');
    sheet.getRangeByIndex(row, 2).setNumber(item.previousActual > 0 ? item.previousActual : 0);
    sheet.getRangeByIndex(row, 3).setNumber(item.budgetedAmount);
    sheet.getRangeByIndex(row, 4).setNumber(item.actualAmount ?? 0);

    final variance = item.variance;
    if (variance != null) {
      final vCell = sheet.getRangeByIndex(row, 5);
      vCell.setNumber(variance);
      if (variance > 0) {
        vCell.cellStyle.fontColor = '#CC0000';
      } else if (variance < 0) {
        vCell.cellStyle.fontColor = '#008000';
      }
    }

    final util = item.utilizationPercent;
    if (util != null) {
      final uCell = sheet.getRangeByIndex(row, 6);
      uCell.setText('${util.toStringAsFixed(1)}%');
      if (util > 100) {
        uCell.cellStyle.fontColor = '#CC0000';
      } else {
        uCell.cellStyle.fontColor = '#008000';
      }
    }
    row++;
  }

  // ── Totals Row ──
  final totalsRow = row;
  sheet.getRangeByIndex(row, 1).setText('TOTAL');
  sheet.getRangeByIndex(row, 1).cellStyle.bold = true;
  sheet.getRangeByIndex(row, 2).setNumber(totalPrevious);
  sheet.getRangeByIndex(row, 3).setNumber(totalBudgeted);
  sheet.getRangeByIndex(row, 4).setNumber(totalActual);
  sheet.getRangeByIndex(row, 5).setNumber(totalVariance);
  sheet.getRangeByIndex(row, 6).setText('${utilization.toStringAsFixed(1)}%');

  for (int c = 1; c <= row; c++) {
    sheet.getRangeByIndex(totalsRow, c).cellStyle.bold = true;
  }

  // ── Auto-fit columns ──
  for (int c = 1; c <= 6; c++) {
    sheet.autoFitColumn(c);
  }

  final List<int> bytes = workbook.saveAsStream();
  workbook.dispose();

  final fileName =
      'budget_${budget.yearLabel}_${budget.type.name}.xlsx'.replaceAll(' ', '_');

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
      text: 'Budget Excel Export — ${budget.name}',
    ));
  } else {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
      text: 'Budget Excel Export — ${budget.name}',
    ));
  }
}