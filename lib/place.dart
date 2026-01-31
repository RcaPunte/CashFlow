import 'dart:io';
import 'dart:ui' as ui;

import 'package:cashledger/cash_book/by_month/controller/monthly_summary_provider.dart';
import 'package:cashledger/cash_book/by_month/helper/monthly_export_excell.dart';
import 'package:cashledger/cash_book/by_month/helper/monthly_pdf_export.dart';
import 'package:cashledger/cash_book/by_month/model/monthly_cash_summary.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Colors, Divider; // Only for chart colors
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
  // Share and Build methods (omitted for brevity)
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

  void _openShareActionSheet(MonthlyCashSummary m) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          'Share Report: ${DateFormat('MMMM yyyy').format(widget.date)}',
        ),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            child: const Text('Share as Image (PNG)'),
            onPressed: () async {
              Navigator.pop(context);
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
          CupertinoActionSheetAction(
            child: const Text('Export & Share as PDF'),
            onPressed: () async {
              Navigator.pop(context);
              //   final file = await exportMonthlyPdf(m);
              //   await Share.shareXFiles([XFile(file.path)]);
            },
          ),
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

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(monthlySummaryProvider(widget.date));

    return CupertinoPageScaffold(
      child: summaryAsync.when(
        loading: () =>
            const Center(child: CupertinoActivityIndicator(radius: 18)),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (summary) => CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: const Text('Monthly Summary'),
              middle: Text(DateFormat('MMMM yyyy').format(widget.date)),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _openShareActionSheet(summary),
                child: const Icon(CupertinoIcons.ellipsis_circle),
              ),
            ),
            SliverToBoxAdapter(
              child: RepaintBoundary(
                key: _repaintKey,
                child: Container(
                  color: CupertinoColors.systemGroupedBackground,
                  child: _buildReportContent(summary),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────
  // Report Content (UPDATED FOOTER)
  // ─────────────────────────────────────
  Widget _buildReportContent(MonthlyCashSummary m) {
    // 1. Map to store aggregated data: {AccountName: [TotalIn, TotalOut]}
    final Map<String, List<double>> aggregatedData = {};

    // Helper function to initialize and update totals
    void aggregate(String account, double inAmount, double outAmount) {
      aggregatedData.putIfAbsent(account, () => [0.0, 0.0]);
      aggregatedData[account]![0] += inAmount;
      aggregatedData[account]![1] += outAmount;
    }

    // 2. Aggregate Receipts
    m.receiptsByAccount.forEach((account, amount) {
      aggregate(account, amount, 0.0);
    });

    // 3. Aggregate Expenses
    m.expensesByAccount.forEach((account, amount) {
      aggregate(account, 0.0, amount);
    });

    // 4. Build the consolidated list of tiles
    final List<Widget> combinedAccountTiles = aggregatedData.entries
        .map(
          (entry) => _DoubleEntryTile(
            account: entry.key,
            inAmount: entry.value[0],
            outAmount: entry.value[1],
          ),
        )
        .toList();

    // 5. Sort the list by account name
    combinedAccountTiles.sort((a, b) {
      final titleA = (a as _DoubleEntryTile).account;
      final titleB = (b as _DoubleEntryTile).account;
      return titleA.compareTo(titleB);
    });

    // 6. Define the Combined Footer. If there are tiles, show totals; otherwise, show 'No transactions' message.
    final Widget combinedFooter = combinedAccountTiles.isEmpty
        ? const Text('No transactions recorded for this month.')
        : _buildDoubleEntryFooter(m.receipts, m.expenses);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Header
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

        // 4. Summary Card (Balance Overview)
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

        // 6. COMBINED Account Movements (Double-Entry Style)
        CupertinoListSection.insetGrouped(
          // Header row to label the columns
          header: _buildDoubleEntryHeader(context),
          // Pass the new footer widget
          footer: combinedFooter,
          children: combinedAccountTiles,
        ),
      ],
    );
  }

  // ─────────────────────────────────────
  // NEW WIDGET: Footer for Double Entry Columns
  // ─────────────────────────────────────
  Widget _buildDoubleEntryFooter(double totalIn, double totalOut) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );

    return Padding(
      // Padding matches the standard list section footer padding
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Divider for visual separation from the last tile
          Divider(
            height: 1,
            color: CupertinoColors.separator.resolveFrom(context),
            indent: 0,
            endIndent: 0,
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Total Label
              const Expanded(
                child: Text(
                  'TOTAL',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),

              // Total IN (Receipts)
              SizedBox(
                width: 80, // Match column width
                child: Text(
                  currencyFormatter.format(totalIn),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.systemGreen,
                  ),
                ),
              ),

              const SizedBox(width: 8), // Padding
              // Total OUT (Expenses)
              SizedBox(
                width: 80, // Match column width
                child: Text(
                  currencyFormatter.format(totalOut),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.systemRed,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────
  // New Header for Double Entry Columns (Slight adjustment for alignment)
  // ─────────────────────────────────────
  Widget _buildDoubleEntryHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 20, bottom: 5, top: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              'PARTICULARS (Account)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              'IN (₹)',
              textAlign: TextAlign.right, // Align right to match the amount
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemGreen,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              'OUT (₹)',
              textAlign: TextAlign.right, // Align right to match the amount
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────
  // Reusable List Tiles and Chart (omitted for brevity)
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

  // ─────────────────────────────────────
  // Bar Chart with enhanced production UI
  // ─────────────────────────────────────
  Widget _buildCupertinoStyleBarChart(MonthlyCashSummary m) {
    // Determine the max Y value for the chart's scale
    final double maxYValue =
        (m.receipts > m.expenses ? m.receipts : m.expenses) * 1.2;

    // Use a formatter for clean currency display on the Y-axis
    final currencyFormatter = NumberFormat.compactSimpleCurrency(
      locale: 'en_IN',
      name: '₹',
    );

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxYValue > 0
            ? maxYValue
            : 100, // Ensure maxY is at least 100 if data is zero
        // 1. Enable Tooltips for interactivity (essential for production)
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            // Use system background for tooltips
            // tooltipBgColor: CupertinoColors.systemGrey.withOpacity(0.9),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              // Show the exact formatted amount in the tooltip
              final amount = rod.toY;
              return BarTooltipItem(
                currencyFormatter.format(amount),
                const TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              );
            },
          ),
        ),

        // 2. Titles Data (Axis Labels)
        titlesData: FlTitlesData(
          show: true,
          // Left Titles (Y-Axis) - Show numerical scale
          leftTitles: AxisTitles(
            //  drawBehindEverything: true,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50, // Give space for labels
              getTitlesWidget: (value, meta) {
                // Only show labels for common intervals (e.g., quarters)
                if (value == meta.max || value == meta.min || value == 0) {
                  return const Text('');
                }

                // Show 4 intermediate labels
                final double interval = (meta.max - meta.min) / 4;
                if ((value % interval) < 1.0) {
                  // Check if value is close to an interval mark
                  return SideTitleWidget(
                    meta: meta,
                    space: 8,
                    child: Text(
                      currencyFormatter.format(value),
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          // Hide Top and Right Axis
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),

          // Bottom Titles (X-Axis) - Receipts/Expenses labels
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final text = value.toInt() == 0 ? 'Receipts' : 'Expenses';
                final color = value.toInt() == 0
                    ? CupertinoColors.systemGreen
                    : CupertinoColors.systemRed;
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // 3. Grid Data - Add subtle horizontal lines for context
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: CupertinoColors.separator.withOpacity(0.6),
              strokeWidth: 0.5,
              dashArray: [5, 5],
            );
          },
        ),

        // 4. Border Data - Add a strong line at the bottom (x=0)
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: CupertinoColors.separator, width: 1),
          ),
        ),

        // 5. Bar Groups (Keep colors/data mapping, improve labels)
        barGroups: [
          // Receipts
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: m.receipts,
                color: CupertinoColors.systemGreen.withOpacity(0.85),
                width: 40, // Slightly wider bars
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                // Show value label on top of the bar
                rodStackItems: [
                  BarChartRodStackItem(
                    0,
                    m.receipts,
                    CupertinoColors.systemGreen.withOpacity(0.85),
                    //  BorderSide.none,
                  ),
                ],

                // Add title to show amount on top
              ),
            ],
          ),
          // Expenses
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: m.expenses,
                color: CupertinoColors.systemRed.withOpacity(0.85),
                width: 40, // Slightly wider bars
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                rodStackItems: [
                  BarChartRodStackItem(
                    0,
                    m.expenses,
                    CupertinoColors.systemRed.withOpacity(0.85),
                    //  BorderSide.none,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────
// WIDGET: Double Entry Custom Tile (Modified text size/alignment for better spacing)
// ─────────────────────────────────────
class _DoubleEntryTile extends StatelessWidget {
  final String account;
  final double inAmount; // Receipts / Debit to Cash
  final double outAmount; // Expenses / Credit from Cash

  const _DoubleEntryTile({
    required this.account,
    required this.inAmount,
    required this.outAmount,
  });

  String _formatAmount(double amount) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return amount == 0 ? '' : currencyFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ), // Reduced vertical padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Account Name (Particulars)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),

          // 2. IN Amount Column
          SizedBox(
            width: 80, // Fixed width for alignment
            child: Text(
              _formatAmount(inAmount),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: inAmount > 0 ? FontWeight.w400 : FontWeight.normal,
                color: inAmount > 0
                    ? CupertinoColors.systemGreen
                    : CupertinoColors.label,
              ),
            ),
          ),

          const SizedBox(width: 8), // Padding between columns
          // 3. OUT Amount Column
          SizedBox(
            width: 80, // Fixed width for alignment
            child: Text(
              _formatAmount(outAmount),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: outAmount > 0 ? FontWeight.w400 : FontWeight.normal,
                color: outAmount > 0
                    ? CupertinoColors.systemRed
                    : CupertinoColors.label,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// class MonthlyReportScreen extends ConsumerStatefulWidget {
//   final DateTime date; // e.g., 2025-01-01

//   const MonthlyReportScreen({super.key, required this.date});

//   @override
//   ConsumerState<MonthlyReportScreen> createState() =>
//       _MonthlyReportScreenState();
// }

// class _MonthlyReportScreenState extends ConsumerState<MonthlyReportScreen> {
//   final GlobalKey _repaintKey = GlobalKey();

//   // ─────────────────────────────────────
//   // Share as PNG Logic (Kept mostly the same)
//   // ─────────────────────────────────────
//   Future<XFile?> _captureWidgetAsImage() async {
//     try {
//       final boundary =
//           _repaintKey.currentContext!.findRenderObject()
//               as RenderRepaintBoundary;
//       final image = await boundary.toImage(pixelRatio: 3.0);
//       final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
//       final bytes = byteData!.buffer.asUint8List();

//       final dir = await getTemporaryDirectory();
//       final file = File(
//         '${dir.path}/monthly_report_${widget.date.year}_${widget.date.month}.png',
//       );
//       await file.writeAsBytes(bytes);
//       return XFile(file.path);
//     } catch (e) {
//       if (mounted) {
//         // Show an error pop-up if image capture fails
//         showCupertinoDialog(
//           context: context,
//           builder: (_) => CupertinoAlertDialog(
//             title: const Text('Capture Failed'),
//             content: Text('Could not generate image. Error: ${e.toString()}'),
//             actions: [
//               CupertinoDialogAction(
//                 child: const Text('OK'),
//                 onPressed: () => Navigator.pop(context),
//               ),
//             ],
//           ),
//         );
//       }
//       return null;
//     }
//   }

//   // ─────────────────────────────────────
//   // Action Sheet for Sharing
//   // ─────────────────────────────────────
//   void _openShareActionSheet(MonthlyCashSummary m) {
//     showCupertinoModalPopup<void>(
//       context: context,
//       builder: (BuildContext context) => CupertinoActionSheet(
//         title: Text(
//           'Share Report: ${DateFormat('MMMM yyyy').format(widget.date)}',
//         ),
//         actions: <CupertinoActionSheetAction>[
//           // 1. Share as Image (PNG)
//           CupertinoActionSheetAction(
//             child: const Text('Share as Image (PNG)'),
//             onPressed: () async {
//               Navigator.pop(context); // Close the sheet
//               final xFile = await _captureWidgetAsImage();
//               if (xFile != null) {
//                 await Share.shareXFiles(
//                   [xFile],
//                   subject:
//                       'Cashbook Report – ${DateFormat('MMMM yyyy').format(widget.date)}',
//                 );
//               }
//             },
//           ),
//           // 2. Share as PDF
//           CupertinoActionSheetAction(
//             child: const Text('Export & Share as PDF'),
//             onPressed: () async {
//               Navigator.pop(context);
//               final file = await exportMonthlyPdf(m);
//               await Share.shareXFiles([XFile(file.path)]);
//             },
//           ),
//           // 3. Share as Excel
//           CupertinoActionSheetAction(
//             child: const Text('Export & Share as Excel (XLSX)'),
//             onPressed: () async {
//               Navigator.pop(context);
//               final file = await exportMonthlyExcel(m);
//               await Share.shareXFiles([XFile(file.path)]);
//             },
//           ),
//         ],
//         cancelButton: CupertinoActionSheetAction(
//           isDefaultAction: true,
//           onPressed: () {
//             Navigator.pop(context);
//           },
//           child: const Text('Cancel'),
//         ),
//       ),
//     );
//   }

//   // ─────────────────────────────────────
//   // Build Method (Uses CustomScrollView for Large Title)
//   // ─────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     final summaryAsync = ref.watch(monthlySummaryProvider(widget.date));

//     return CupertinoPageScaffold(
//       // 1. Use CustomScrollView with CupertinoSliverNavigationBar for large title
//       child: summaryAsync.when(
//         loading: () =>
//             const Center(child: CupertinoActivityIndicator(radius: 18)),
//         error: (err, _) => Center(child: Text('Error: $err')),
//         data: (summary) => CustomScrollView(
//           slivers: [
//             CupertinoSliverNavigationBar(
//               // Large title for the main screen header
//               largeTitle: const Text('Monthly Summary'),
//               // Small title that appears when scrolled up
//               middle: Text(DateFormat('MMMM yyyy').format(widget.date)),
//               trailing: CupertinoButton(
//                 padding: EdgeInsets.zero,
//                 // Use the action icon for a cleaner look
//                 onPressed: () => _openShareActionSheet(summary),
//                 child: const Icon(CupertinoIcons.ellipsis_circle),
//               ),
//             ),

//             // 2. Main report (captured for image share)
//             SliverToBoxAdapter(
//               child: RepaintBoundary(
//                 key: _repaintKey,
//                 child: Container(
//                   color: CupertinoColors
//                       .systemGroupedBackground, // Match background
//                   child: _buildReportContent(summary),
//                 ),
//               ),
//             ),

//             // 3. Final Spacer
//             const SliverToBoxAdapter(child: SizedBox(height: 30)),
//           ],
//         ),
//       ),
//     );
//   }

//   // ─────────────────────────────────────
//   // Report Content (iOS-native look)
//   // ─────────────────────────────────────
//   Widget _buildReportContent(MonthlyCashSummary m) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Date Header (below large title)
//         Padding(
//           padding: const EdgeInsets.only(left: 20, top: 12, bottom: 8),
//           child: Text(
//             DateFormat('MMMM yyyy').format(widget.date),
//             style: const TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.w700,
//               color: CupertinoColors.secondaryLabel,
//             ),
//           ),
//         ),

//         // 4. Summary Card
//         CupertinoListSection.insetGrouped(
//           header: const Text('Balance Overview'),
//           children: [
//             _summaryTile(
//               'Opening Balance',
//               m.openingBalance,
//               icon: CupertinoIcons.arrow_down_right,
//             ),
//             _summaryTile(
//               'Total Receipts',
//               m.receipts,
//               color: CupertinoColors.systemGreen,
//               icon: CupertinoIcons.plus_circle_fill,
//             ),
//             _summaryTile(
//               'Total Expenses',
//               m.expenses,
//               color: CupertinoColors.systemRed,
//               icon: CupertinoIcons.minus_circle_fill,
//             ),
//             _summaryTile(
//               'Closing Balance',
//               m.closingBalance,
//               bold: true,
//               icon: CupertinoIcons.creditcard_fill,
//             ),
//           ],
//         ),
//         const SizedBox(height: 20),

//         // 5. Chart Header & Widget
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'Receipts vs Expenses',
//                 style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
//               ),
//               const SizedBox(height: 16),
//               SizedBox(height: 240, child: _buildCupertinoStyleBarChart(m)),
//             ],
//           ),
//         ),
//         const SizedBox(height: 28),

//         // 6. Receipts by Account
//         CupertinoListSection.insetGrouped(
//           header: const Text('Receipts by Account'),
//           footer: m.receiptsByAccount.isEmpty
//               ? const Text('No receipts recorded for this month.')
//               : null,
//           children: m.receiptsByAccount.entries
//               .map(
//                 (e) =>
//                     _accountTile(e.key, e.value, CupertinoColors.systemGreen),
//               )
//               .toList(),
//         ),

//         // 7. Expenses by Account
//         CupertinoListSection.insetGrouped(
//           header: const Text('Expenses by Account'),
//           footer: m.expensesByAccount.isEmpty
//               ? const Text('No expenses recorded for this month.')
//               : null,
//           children: m.expensesByAccount.entries
//               .map(
//                 (e) => _accountTile(e.key, e.value, CupertinoColors.systemRed),
//               )
//               .toList(),
//         ),
//       ],
//     );
//   }

//   // ─────────────────────────────────────
//   // Reusable List Tiles
//   // ─────────────────────────────────────
//   Widget _summaryTile(
//     String title,
//     double amount, {
//     Color? color,
//     bool bold = false,
//     IconData? icon,
//   }) {
//     final effectiveColor = amount < 0 && !bold
//         ? CupertinoColors.systemRed
//         : color;

//     return CupertinoListTile(
//       leading: icon != null
//           ? Icon(icon, color: effectiveColor ?? CupertinoColors.systemBlue)
//           : null,
//       title: Text(
//         title,
//         style: TextStyle(
//           fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
//         ),
//       ),
//       trailing: Text(
//         '₹${amount.toStringAsFixed(2)}',
//         style: TextStyle(
//           color: effectiveColor,
//           fontWeight: bold ? FontWeight.bold : FontWeight.w600,
//           fontSize: 17,
//         ),
//       ),
//     );
//   }

//   Widget _accountTile(String account, double amount, Color tint) {
//     return CupertinoListTile(
//       title: Text(account),
//       trailing: Text(
//         '₹${amount.toStringAsFixed(2)}',
//         style: TextStyle(color: tint, fontWeight: FontWeight.w600),
//       ),
//     );
//   }

//   // ─────────────────────────────────────
//   // Bar Chart with iOS-style minimal look (Kept the same)
//   // ─────────────────────────────────────
//   Widget _buildCupertinoStyleBarChart(MonthlyCashSummary m) {
//     return BarChart(
//       BarChartData(
//         alignment: BarChartAlignment.spaceAround,
//         maxY: (m.receipts > m.expenses ? m.receipts : m.expenses) * 1.2,
//         barTouchData: BarTouchData(enabled: false),
//         titlesData: FlTitlesData(
//           leftTitles: const AxisTitles(
//             sideTitles: SideTitles(showTitles: false),
//           ),
//           rightTitles: const AxisTitles(
//             sideTitles: SideTitles(showTitles: false),
//           ),
//           topTitles: const AxisTitles(
//             sideTitles: SideTitles(showTitles: false),
//           ),
//           bottomTitles: AxisTitles(
//             sideTitles: SideTitles(
//               showTitles: true,
//               reservedSize: 32,
//               getTitlesWidget: (value, meta) {
//                 final text = value.toInt() == 0 ? 'Receipts' : 'Expenses';
//                 return SideTitleWidget(
//                   meta: meta,
//                   child: Text(text, style: const TextStyle(fontSize: 13)),
//                 );
//               },
//             ),
//           ),
//         ),
//         gridData: const FlGridData(show: false),
//         borderData: FlBorderData(show: false),
//         barGroups: [
//           BarChartGroupData(
//             x: 0,
//             barRods: [
//               BarChartRodData(
//                 toY: m.receipts,
//                 color: CupertinoColors.systemGreen,
//                 width: 36,
//                 borderRadius: const BorderRadius.vertical(
//                   top: Radius.circular(8),
//                 ),
//               ),
//             ],
//           ),
//           BarChartGroupData(
//             x: 1,
//             barRods: [
//               BarChartRodData(
//                 toY: m.expenses,
//                 color: CupertinoColors.systemRed,
//                 width: 36,
//                 borderRadius: const BorderRadius.vertical(
//                   top: Radius.circular(8),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
