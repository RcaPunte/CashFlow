import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cashledger/cash_book/by_month/controller/monthly_statement_controller.dart';
import 'package:cashledger/cash_book/by_month/controller/monthly_summary_provider.dart';
import 'package:cashledger/cash_book/by_month/helper/monthly_export_excell.dart';
import 'package:cashledger/cash_book/by_month/helper/monthly_pdf_export.dart';
import 'package:cashledger/cash_book/by_month/model/monthly_cash_summary.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors; // Only for chart colors
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class MonthlyReportScreen extends ConsumerStatefulWidget {
  final DateTime date; // e.g., 2025-01-01

  const MonthlyReportScreen({super.key, required this.date});

  @override
  ConsumerState<MonthlyReportScreen> createState() =>
      _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends ConsumerState<MonthlyReportScreen> {
  final GlobalKey _repaintKey = GlobalKey();

  // ─────────────────────────────────────
  // Share as PNG Logic (Kept mostly the same)
  // ─────────────────────────────────────
  Future<XFile?> _captureWidgetAsImage() async {
    try {
      final boundary =
          _repaintKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/monthly_report_${widget.date.year}_${widget.date.month}.png',
      );
      await file.writeAsBytes(bytes);
      return XFile(file.path);
    } catch (e) {
      if (mounted) {
        // Show an error pop-up if image capture fails
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('Capture Failed'),
            content: Text('Could not generate image. Error: ${e.toString()}'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
      return null;
    }
  }

  // ─────────────────────────────────────
  // Action Sheet for Sharing
  // ─────────────────────────────────────
  void _openShareActionSheet(MonthlyCashSummary m) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          'Share Report: ${DateFormat('MMMM yyyy').format(widget.date)}',
        ),
        actions: <CupertinoActionSheetAction>[
          // 1. Share as Image (PNG)
          CupertinoActionSheetAction(
            child: const Text('Share as Image (PNG)'),
            onPressed: () async {
              Navigator.pop(context); // Close the sheet
              final xFile = await _captureWidgetAsImage();
              if (xFile != null) {
                await Share.shareXFiles(
                  [xFile],
                  subject:
                      'Cashbook Report – ${DateFormat('MMMM yyyy').format(widget.date)}',
                );
              }
            },
          ),
          // 2. Share as PDF
          CupertinoActionSheetAction(
            child: const Text('Export & Share as PDF'),
            onPressed: () async {
              Navigator.pop(context);
              final file = await exportMonthlyPdf(m);
              await Share.shareXFiles([XFile(file.path)]);
            },
          ),
          // 3. Share as Excel
          CupertinoActionSheetAction(
            child: const Text('Export & Share as Excel (XLSX)'),
            onPressed: () async {
              Navigator.pop(context);
              final file = await exportMonthlyExcel(m);
              await Share.shareXFiles([XFile(file.path)]);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  // ─────────────────────────────────────
  // Build Method (Uses CustomScrollView for Large Title)
  // ─────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(monthlySummaryProvider(widget.date));

    return CupertinoPageScaffold(
      // 1. Use CustomScrollView with CupertinoSliverNavigationBar for large title
      child: summaryAsync.when(
        loading: () =>
            const Center(child: CupertinoActivityIndicator(radius: 18)),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (summary) => CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              // Large title for the main screen header
              largeTitle: const Text('Monthly Summary'),
              // Small title that appears when scrolled up
              middle: Text(DateFormat('MMMM yyyy').format(widget.date)),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                // Use the action icon for a cleaner look
                onPressed: () => _openShareActionSheet(summary),
                child: const Icon(CupertinoIcons.ellipsis_circle),
              ),
            ),

            // 2. Main report (captured for image share)
            SliverToBoxAdapter(
              child: RepaintBoundary(
                key: _repaintKey,
                child: Container(
                  color: CupertinoColors
                      .systemGroupedBackground, // Match background
                  child: _buildReportContent(summary),
                ),
              ),
            ),

            // 3. Final Spacer
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────
  // Report Content (iOS-native look)
  // ─────────────────────────────────────
  Widget _buildReportContent(MonthlyCashSummary m) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Header (below large title)
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 12, bottom: 8),
          child: Text(
            DateFormat('MMMM yyyy').format(widget.date),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ),

        // 4. Summary Card
        CupertinoListSection.insetGrouped(
          header: const Text('Balance Overview'),
          children: [
            _summaryTile(
              'Opening Balance',
              m.openingBalance,
              icon: CupertinoIcons.arrow_down_right,
            ),
            _summaryTile(
              'Total Receipts',
              m.receipts,
              color: CupertinoColors.systemGreen,
              icon: CupertinoIcons.plus_circle_fill,
            ),
            _summaryTile(
              'Total Expenses',
              m.expenses,
              color: CupertinoColors.systemRed,
              icon: CupertinoIcons.minus_circle_fill,
            ),
            _summaryTile(
              'Closing Balance',
              m.closingBalance,
              bold: true,
              icon: CupertinoIcons.creditcard_fill,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 5. Chart Header & Widget
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Receipts vs Expenses',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              SizedBox(height: 240, child: _buildCupertinoStyleBarChart(m)),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // 6. Receipts by Account
        CupertinoListSection.insetGrouped(
          header: const Text('Receipts by Account'),
          footer: m.receiptsByAccount.isEmpty
              ? const Text('No receipts recorded for this month.')
              : null,
          children: m.receiptsByAccount.entries
              .map(
                (e) =>
                    _accountTile(e.key, e.value, CupertinoColors.systemGreen),
              )
              .toList(),
        ),

        // 7. Expenses by Account
        CupertinoListSection.insetGrouped(
          header: const Text('Expenses by Account'),
          footer: m.expensesByAccount.isEmpty
              ? const Text('No expenses recorded for this month.')
              : null,
          children: m.expensesByAccount.entries
              .map(
                (e) => _accountTile(e.key, e.value, CupertinoColors.systemRed),
              )
              .toList(),
        ),
      ],
    );
  }

  // ─────────────────────────────────────
  // Reusable List Tiles
  // ─────────────────────────────────────
  Widget _summaryTile(
    String title,
    double amount, {
    Color? color,
    bool bold = false,
    IconData? icon,
  }) {
    final effectiveColor = amount < 0 && !bold
        ? CupertinoColors.systemRed
        : color;

    return CupertinoListTile(
      leading: icon != null
          ? Icon(icon, color: effectiveColor ?? CupertinoColors.systemBlue)
          : null,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: Text(
        '₹${amount.toStringAsFixed(2)}',
        style: TextStyle(
          color: effectiveColor,
          fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          fontSize: 17,
        ),
      ),
    );
  }

  Widget _accountTile(String account, double amount, Color tint) {
    return CupertinoListTile(
      title: Text(account),
      trailing: Text(
        '₹${amount.toStringAsFixed(2)}',
        style: TextStyle(color: tint, fontWeight: FontWeight.w600),
      ),
    );
  }

  // ─────────────────────────────────────
  // Bar Chart with iOS-style minimal look (Kept the same)
  // ─────────────────────────────────────
  Widget _buildCupertinoStyleBarChart(MonthlyCashSummary m) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (m.receipts > m.expenses ? m.receipts : m.expenses) * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final text = value.toInt() == 0 ? 'Receipts' : 'Expenses';
                return SideTitleWidget(
                  meta: meta,
                  child: Text(text, style: const TextStyle(fontSize: 13)),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: m.receipts,
                color: CupertinoColors.systemGreen,
                width: 36,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: m.expenses,
                color: CupertinoColors.systemRed,
                width: 36,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
