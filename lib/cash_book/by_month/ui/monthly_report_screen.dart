// Full working example: expandable/collapsible parent → child accounts
// Tally / Zoho style
// import 'dart:html' as html;
import 'dart:io';
import 'dart:ui' as ui;
import 'package:cashledger/cash_book/by_month/controller/monthly_summary_provider.dart';
import 'package:cashledger/cash_book/by_month/helper/monthly_export_excell.dart';
import 'package:cashledger/cash_book/by_month/helper/monthly_pdf_export.dart';
import 'package:cashledger/cash_book/by_month/model/monthly_cash_summary.dart';
import 'package:cashledger/cash_book/ui/widget/financial_yeaer_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountSummaryCard extends StatelessWidget {
  final MonthlyCashSummary summary;

  const AccountSummaryCard({super.key, required this.summary});

  Widget _row(
    BuildContext context,
    String label,
    double value, {
    Color? color,
  }) {
    final resolved =
        color ??
        (value >= 0
            ? CupertinoColors.label.resolveFrom(context)
            : CupertinoColors.systemRed.resolveFrom(context));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: CupertinoColors.darkBackgroundGray, // .resolveFrom(context),
            fontSize: 14,
          ),
        ),
        Text(
          "₹${value.toStringAsFixed(2)}",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: resolved,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalIncome = summary.openingBalance + summary.receipts;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 4),
            color: CupertinoColors.systemGrey
                .resolveFrom(context)
                .withOpacity(0.2),
          ),
        ],
      ),
      child: Column(
        children: [
          _row(
            context,
            "Opening Balance",
            summary.openingBalance,
            // color: CupertinoColors.activeBlue,
          ),
          const Divider(),
          _row(
            context,
            "New Income",
            summary.receipts,
            // color: CupertinoColors.activeGreen,
          ),
          const Divider(),
          _row(
            context,
            "Total Income",
            totalIncome,
            //  color: CupertinoColors.activeGreen,
          ),
          const Divider(),
          _row(
            context,
            "Total Expenditure",
            summary.expenses,
            //   color: CupertinoColors.systemRed,
          ),
          const Divider(),
          _row(
            context,
            "Closing Balance",
            summary.closingBalance,
            // color: summary.closingBalance >= 0
            //     ? CupertinoColors.activeBlue
            //     : CupertinoColors.systemRed,
          ),
        ],
      ),
    );
  }
}

//final summaryAsync = ref.watch(monthlySummaryProvider(selectedMonth));

// summaryAsync.when(
//   data: (summary) => AccountSummaryCard(summary: summary),
//   loading: () => const Padding(
//     padding: EdgeInsets.all(24),
//     child: CupertinoActivityIndicator(),
//   ),
//   error: (_, __) => const SizedBox(),
// ),

// ------------------------------------------------------------
// MODELS
// ------------------------------------------------------------
class AccountNode {
  final String id;
  final String name;
  final String? parentId;

  AccountNode({required this.id, required this.name, this.parentId});
}

class AccountTotal {
  double receipts = 0;
  double expenses = 0;
}

// ------------------------------------------------------------
// PROVIDERS
// ------------------------------------------------------------

/// toggle expand / collapse per parent
final expandedAccountsProvider = StateProvider<Set<String>>((ref) => {});

/// toggle show sub-accounts
final showSubAccountsProvider = StateProvider<bool>((ref) => true);

/// fetch accounts tree
final accountsTreeProvider = FutureProvider<List<AccountNode>>((ref) async {
  final res = await Supabase.instance.client
      .from('accounts')
      .select('id, name, parent_account_id')
      .eq('year', ref.watch(yearProvider));

  return res
      .map<AccountNode>(
        (e) => AccountNode(
          id: e['id'],
          name: e['name'],
          parentId: e['parent_account_id'],
        ),
      )
      .toList();
});

/// monthly totals grouped by account id
final monthlyAccountTotalsProvider =
    FutureProvider.family<Map<String, AccountTotal>, DateTime>((
      ref,
      date,
    ) async {
      final supabase = Supabase.instance.client;

      final from = DateTime(date.year, date.month, 1);
      final to = DateTime(date.year, date.month + 1, 0);

      final rows = await supabase
          .from('entries')
          .select('type, amount, account_id')
          .gte('date', from.toIso8601String())
          .lte('date', to.toIso8601String());

      final map = <String, AccountTotal>{};

      for (final e in rows) {
        final id = e['account_id'] as String;
        final amt = (e['amount'] as num).toDouble();

        map.putIfAbsent(id, () => AccountTotal());

        if (e['type'] == 'debit') {
          map[id]!.receipts += amt;
        } else {
          map[id]!.expenses += amt;
        }
      }

      return map;
    });

// ------------------------------------------------------------
// SCREEN
// ------------------------------------------------------------

class MonthlyReportScreen extends ConsumerWidget {
  final DateTime month;
  const MonthlyReportScreen({super.key, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GlobalKey repaintKey = GlobalKey();
    final showSubs = ref.watch(showSubAccountsProvider);
    final expanded = ref.watch(expandedAccountsProvider);

    final accountsAsync = ref.watch(accountsTreeProvider);
    final totalsAsync = ref.watch(monthlyAccountTotalsProvider(month));
    // import 'dart:ui' as ui;
    // import 'package:flutter/foundation.dart'; // For kIsWeb
    // import 'package:flutter/rendering.dart';
    // import 'package:cross_file/cross_file.dart'; // Standard for XFile

    Future<XFile?> captureWidgetAsImage() async {
      try {
        // 1. Capture the pixels (This part remains the same)
        final boundary =
            repaintKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final Uint8List bytes = byteData!.buffer.asUint8List();

        final fileName = 'monthly_report_${month.year}_${month.month}.png';

        if (kIsWeb) {
          // 2. Web specific: Create XFile directly from memory bytes
          // Browsers don't have a "Temporary Directory" path
          //TODO: The Share package's shareXFiles on web will trigger a download of the file. If you want to trigger an immediate download without using the Share package, you can use the following code instead:
          // final blob = html.Blob([bytes]);
          // final url = html.Url.createObjectUrlFromBlob(blob);
          // final anchor = html.AnchorElement(href: url)
          //   ..setAttribute("download", fileName)
          //   ..click();
          // html.Url.revokeObjectUrl(url);
          return XFile.fromData(bytes, name: fileName, mimeType: 'image/png');
        } else {
          // 3. Mobile specific: Keep your existing dart:io logic
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/$fileName');
          await file.writeAsBytes(bytes);
          return XFile(file.path);
        }
      } catch (e) {
        if (context.mounted) {
          // _showErrorDialog(e.toString());
        }
        return null;
      }
    }

    Future<void> shareMonthlyReport(
      BuildContext context,
      WidgetRef ref,
      DateTime month,
    ) async {
      // 1. Show a loading indicator (Cupertino style)
      // ref.read(serverConnectionState.notifier).setTrue();

      try {
        // 2. Capture the image using your previously converted web-ready function
        final XFile? imageFile = await captureWidgetAsImage();

        if (imageFile != null) {
          final String dateString = DateFormat('MMMM yyyy').format(month);
          final String shareMessage = "Financial Summary for $dateString";

          // 3. Share the file
          // On Web: This usually triggers a download or opens a new tab depending on the browser
          // On Mobile: This opens the system share sheet
          await Share.shareXFiles(
            [imageFile],
            text: shareMessage,
            subject: "Monthly Report - $dateString",
          );
        }
      } catch (e) {
        debugPrint("Sharing failed: $e");
      } finally {
        //  ref.read(serverConnectionState.notifier).setFalse();
      }
    }

    void openShareActionSheet(MonthlyCashSummary m) {
      showCupertinoModalPopup<void>(
        context: context,
        builder: (BuildContext context) => CupertinoActionSheet(
          title: Text('Share Report: ${DateFormat('MMMM yyyy').format(month)}'),
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              child: const Text('Share as Image (PNG)'),
              onPressed: () async {
                Navigator.pop(context);
                shareMonthlyReport(context, ref, month);
                // final xFile = await captureWidgetAsImage();
                // if (xFile != null) {
                //   await Share.shareXFiles(
                //     [xFile],
                //     subject:
                //         'Cashbook Report – ${DateFormat('MMMM yyyy').format(month)}',
                //   );
                // }
              },
            ),
            CupertinoActionSheetAction(
              child: const Text('Export & Share as PDF'),
              onPressed: () async {
                Navigator.pop(context);
                final summary =
                    ref.watch(monthlySummaryProvider(month)).value;
                if (summary == null) return;
                await exportMonthlyPdf(summary: summary);
              },
            ),
            CupertinoActionSheetAction(
              child: const Text('Export & Share as Excel (XLSX)'),
              onPressed: () async {
                Navigator.pop(context);
                await exportMonthlyExcel(m);
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

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(DateFormat('MMMM yyyy').format(month)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => openShareActionSheet(
            ref.watch(monthlySummaryProvider(month)).value!,
          ),
          child: const Icon(CupertinoIcons.ellipsis_circle),
        ),
        // CupertinoSwitch(
        //   value: showSubs,
        //   onChanged: (v) =>
        //       ref.read(showSubAccountsProvider.notifier).state = v,
        // ),
      ),
      child: SafeArea(
        child: RepaintBoundary(
          key: repaintKey,
          child: SingleChildScrollView(
            child: Container(
              color: CupertinoColors.systemBackground,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                    child: Text(
                      "Overall Summary - ${DateFormat('MMMM yyyy').format(month)}",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  AccountSummaryCard(
                    summary: ref
                        .watch(monthlySummaryProvider(month))
                        .whenData((value) => value)
                        .value!,
                  ),
                  //  const Divider(),
                  //  buildDoubleEntryHeader(context),
                  //SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 12.0,
                      top: 8.0,
                      bottom: 8,
                    ),
                    child: Text(
                      "Detailed Account Summary",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const _LedgerHeader(),
                  // ------------------------------------------------------------
                  accountsAsync.when(
                    data: (accounts) => totalsAsync.when(
                      data: (totals) {
                        final parents = accounts
                            .where((a) => a.parentId == null)
                            .toList();

                        return Padding(
                          padding: const EdgeInsets.only(
                            left: 12.0,
                            right: 12.0,
                            // bottom: 8.0,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemBackground
                                  .resolveFrom(context),
                              // borderRadius: BorderRadius.only(
                              //   bottomLeft: Radius.circular(12),
                              //   bottomRight: Radius.circular(12),
                              // ),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                  color: CupertinoColors.systemGrey
                                      .resolveFrom(context)
                                      .withOpacity(0.2),
                                ),
                              ],
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: parents.length,
                              itemBuilder: (_, i) {
                                final backgroundColor = (i + 1) % 2 == 0
                                    ? CupertinoColors.systemBackground
                                    : CupertinoColors.secondarySystemBackground;
                                final parent = parents[i];
                                final isOpen = expanded.contains(parent.id);
                                final children = accounts
                                    .where((a) => a.parentId == parent.id)
                                    .toList();
                                final parentTotal = _aggregate(
                                  parent.id,
                                  children,
                                  totals,
                                  accounts,
                                );

                                // Skip empty parents
                                if (parentTotal.receipts == 0 &&
                                    parentTotal.expenses == 0) {
                                  return const SizedBox.shrink();
                                }

                                return Column(
                                  children: [
                                    _DoubleEntryTile(
                                      backgroundColor: backgroundColor,
                                      account: parent.name,
                                      inAmount: parentTotal.receipts,
                                      outAmount: parentTotal.expenses,
                                      cashSummary:
                                          ref
                                              .watch(
                                                monthlySummaryProvider(month),
                                              )
                                              .value ??
                                          MonthlyCashSummary(
                                            monthKey: '',
                                            openingBalance: 0,
                                            receipts: 0,
                                            expenses: 0,
                                            receiptsByAccount: {},
                                            expensesByAccount: {},
                                            closingBalance: 0,
                                            accountsById: {},
                                          ),
                                      indentLevel: 0,
                                      hasChildren: children.isNotEmpty,
                                      expanded: isOpen,
                                      onTap: () {
                                        final set = {...expanded};
                                        isOpen
                                            ? set.remove(parent.id)
                                            : set.add(parent.id);
                                        ref
                                                .read(
                                                  expandedAccountsProvider
                                                      .notifier,
                                                )
                                                .state =
                                            set;
                                      },
                                    ),
                                    if (showSubs && isOpen)
                                      ...children.map((c) {
                                        final childTotal = totals[c.id];
                                        return _DoubleEntryTile(
                                          isSubAccount: true,
                                          backgroundColor: backgroundColor,
                                          account: c.name,
                                          inAmount: childTotal?.receipts ?? 0,
                                          outAmount: childTotal?.expenses ?? 0,
                                          cashSummary:
                                              ref
                                                  .watch(
                                                    monthlySummaryProvider(
                                                      month,
                                                    ),
                                                  )
                                                  .value ??
                                              MonthlyCashSummary(
                                                monthKey: '',
                                                openingBalance: 0,
                                                receipts: 0,
                                                expenses: 0,
                                                receiptsByAccount: {},
                                                expensesByAccount: {},
                                                closingBalance: 0,
                                                accountsById: {},
                                              ),
                                          indentLevel:
                                              1, // Indent for accounting hierarchy
                                          hasChildren: false,
                                          expanded: false,
                                          onTap: () {},
                                        );
                                      }),
                                    const Divider(
                                      height: 0.1,
                                      indent: 40,
                                      color: Color.fromARGB(44, 130, 130, 137),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        );
                      },

                      loading: () =>
                          const Center(child: CupertinoActivityIndicator()),
                      error: (_, __) =>
                          const Center(child: Text('Error loading totals')),
                    ),
                    loading: () =>
                        const Center(child: CupertinoActivityIndicator()),
                    error: (_, __) =>
                        const Center(child: Text('Error loading accounts')),
                  ),
                  _GrandTotalFooter(
                    summary: ref.watch(monthlySummaryProvider(month)).value!,
                  ),
                  // buildDoubleEntryFooter(
                  //   context,
                  //   ref
                  //       .watch(monthlySummaryProvider(month))
                  //       .whenData((value) => value)
                  //       .value!,
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Recursively sum an account + ALL its descendants at any depth
  AccountTotal _aggregate(
    String parentId,
    List<AccountNode> children,
    Map<String, AccountTotal> totals,
    List<AccountNode> allAccounts,
  ) {
    return _aggregateRecursive(parentId, totals, allAccounts);
  }

  AccountTotal _aggregateRecursive(
    String accountId,
    Map<String, AccountTotal> totals,
    List<AccountNode> allAccounts,
  ) {
    final total = AccountTotal();
    // This account's own entries
    if (totals[accountId] != null) {
      total.receipts += totals[accountId]!.receipts;
      total.expenses += totals[accountId]!.expenses;
    }
    // Recurse into all children (any depth)
    for (final child in allAccounts.where((a) => a.parentId == accountId)) {
      final childTotal = _aggregateRecursive(child.id, totals, allAccounts);
      total.receipts += childTotal.receipts;
      total.expenses += childTotal.expenses;
    }
    return total;
  }
}

// ------------------------------------------------------------
// UI TILES
// ------------------------------------------------------------

// class _ParentTile extends StatelessWidget {
//   final String name;
//   final AccountTotal total;
//   final bool expanded;
//   final bool hasChildren;
//   final VoidCallback onTap;

//   const _ParentTile({
//     required this.name,
//     required this.total,
//     required this.expanded,
//     required this.hasChildren,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return CupertinoListTile(
//       title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
//       subtitle: Text(
//         'In: ₹${total.receipts.toStringAsFixed(2)}  Out: ₹${total.expenses.toStringAsFixed(2)}',
//       ),
//       trailing: hasChildren
//           ? Icon(
//               expanded
//                   ? CupertinoIcons.chevron_down
//                   : CupertinoIcons.chevron_right,
//             )
//           : null,
//       onTap: hasChildren ? onTap : null,
//     );
//   }
// }

// class _ChildTile extends StatelessWidget {
//   final String name;
//   final AccountTotal? total;

//   const _ChildTile({required this.name, this.total});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(left: 32),
//       child: CupertinoListTile(
//         title: Text(name),
//         subtitle: Text(
//           'In: ₹${(total?.receipts ?? 0).toStringAsFixed(2)}  Out: ₹${(total?.expenses ?? 0).toStringAsFixed(2)}',
//         ),
//       ),
//     );
//   }
// }

class _DoubleEntryTile extends StatelessWidget {
  final String account;
  final double inAmount;
  final double outAmount;
  final MonthlyCashSummary cashSummary;
  final int indentLevel;
  final VoidCallback onTap;
  final bool expanded;
  final bool hasChildren;
  final Color backgroundColor;
  final bool isSubAccount;

  const _DoubleEntryTile({
    required this.account,
    required this.inAmount,
    required this.outAmount,
    required this.indentLevel,
    required this.expanded,
    required this.cashSummary,
    required this.onTap,
    this.hasChildren = false,
    required this.backgroundColor,
    this.isSubAccount = false,
  });

  // Helper for accounting format: Monospaced digits
  TextStyle get _accountingStyle => const TextStyle(
    fontFamily: 'Courier', // Or use standard font with tabular features
    fontFeatures: [FontFeature.tabularFigures()],
    fontSize: 14,
  );

  String _formatCurrency(double amount) {
    if (amount == 0) return "-  "; // Standard accounting empty cell
    return amount.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final inPct =
        (inAmount / (cashSummary.receipts > 0 ? cashSummary.receipts : 1)) *
        100;
    final outPct =
        (outAmount / (cashSummary.expenses > 0 ? cashSummary.expenses : 1)) *
        100;

    return SizedBox(
      height: 36,
      child: CupertinoButton(
        //  color: backgroundColor,
        padding: EdgeInsets.zero,
        onPressed: hasChildren ? onTap : null,
        child: Container(
          padding: EdgeInsets.fromLTRB(20 + (indentLevel * 12), 2, 12, 2),
          // decoration: const BoxDecoration(
          //   color: CupertinoColors.systemBackground,
          // ),
          child: Row(
            children: [
              // 1. Account Name + Chevron
              Expanded(
                child: Row(
                  children: [
                    hasChildren
                        ? Icon(
                            expanded
                                ? CupertinoIcons.chevron_down
                                : CupertinoIcons.chevron_right,
                            size: 14,
                            color: CupertinoColors.systemGrey,
                          )
                        : SizedBox(width: 14),
                    if (hasChildren) const SizedBox(width: 2),
                    if (isSubAccount)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, right: 8),
                        child: const Icon(
                          CupertinoIcons.circle_fill,
                          size: 6,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        account,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: isSubAccount
                              ? CupertinoColors.systemGrey
                              : CupertinoColors.label.resolveFrom(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // 2. IN Column (Receipts)
              _buildAccountingColumn(
                amount: inAmount,
                percent: inPct,
                color: CupertinoColors.systemGreen,
              ),

              const SizedBox(width: 12),

              // 3. OUT Column (Expenses)
              _buildAccountingColumn(
                amount: outAmount,
                percent: outPct,
                color: CupertinoColors.systemRed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountingColumn({
    required double amount,
    required double percent,
    required Color color,
  }) {
    return SizedBox(
      width: 85, // Fixed width for vertical alignment
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatCurrency(amount),
            style: _accountingStyle.copyWith(
              color: amount == 0 ? CupertinoColors.placeholderText : color,
              fontWeight: indentLevel == 0
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
          // if (amount > 0)
          //   Text(
          //     "${percent.toStringAsFixed(1)}%",
          //     style: const TextStyle(
          //       fontSize: 10,
          //       color: CupertinoColors.secondaryLabel,
          //     ),
          //   ),
        ],
      ),
    );
  }
}

// double _percent(double part, double total) {
//   if (total == 0) return 0;
//   return (part / total) * 100;
// }

// String _fmtPercent(double pct) {
//   return '${pct.toStringAsFixed(1)}%';
// }

Widget buildDoubleEntryFooter(
  BuildContext context,
  MonthlyCashSummary? summary,
) {
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
                currencyFormatter.format(summary!.receipts),
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
                currencyFormatter.format(summary.expenses),
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

Widget buildDoubleEntryHeader(BuildContext context) {
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

class _LedgerHeader extends StatelessWidget {
  const _LedgerHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      // Light background to separate from list items
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      padding: const EdgeInsets.fromLTRB(20, 16, 0, 0),

      decoration: BoxDecoration(
        // color: CupertinoColors.systemYellow,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 4),
            color: CupertinoColors.systemGrey
                .resolveFrom(context)
                .withOpacity(0.2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'ACCOUNT',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.secondaryLabel,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                // IN COLUMN HEADER
                SizedBox(
                  width: 85,
                  child: Text(
                    'IN (₹)',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.secondaryLabel.withOpacity(0.8),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // OUT COLUMN HEADER
                SizedBox(
                  width: 85,
                  child: Text(
                    'OUT (₹)',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.secondaryLabel.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Container(
            height: 2,
            // margin: const EdgeInsets.only(bottom: 8),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: CupertinoColors.separator, width: 0.5),
                bottom: BorderSide(
                  color: CupertinoColors.separator,
                  width: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GrandTotalFooter extends StatelessWidget {
  final MonthlyCashSummary summary;

  const _GrandTotalFooter({required this.summary});

  // Re-using the same alignment style
  TextStyle get _accountingStyle => const TextStyle(
    fontFeatures: [FontFeature.tabularFigures()],
    fontSize: 13,
    fontWeight: FontWeight.bold,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      // Light grey background for the footer to make it stand out
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      padding: const EdgeInsets.fromLTRB(20, 0, 0, 18),

      decoration: BoxDecoration(
        // color: CupertinoColors.systemYellow,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 4),
            color: CupertinoColors.systemGrey
                .resolveFrom(context)
                .withOpacity(0.2),
          ),
        ],
      ), // Extra bottom padding for SafeArea
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Double border effect common in accounting
          Container(
            height: 2,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: CupertinoColors.separator, width: 0.5),
                bottom: BorderSide(
                  color: CupertinoColors.separator,
                  width: 0.5,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'GRAND TOTAL',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ),

                // Total IN Column
                SizedBox(
                  width: 85,
                  child: Text(
                    summary.receipts.toStringAsFixed(2),
                    textAlign: TextAlign.end,
                    style: _accountingStyle.copyWith(
                      color: CupertinoColors.systemGreen,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Total OUT Column
                SizedBox(
                  width: 85,
                  child: Text(
                    summary.expenses.toStringAsFixed(2),
                    textAlign: TextAlign.end,
                    style: _accountingStyle.copyWith(
                      color: CupertinoColors.systemRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Container(
          //   height: 2,
          //   margin: const EdgeInsets.only(top: 8),
          //   decoration: const BoxDecoration(
          //     border: Border(
          //       top: BorderSide(color: CupertinoColors.separator, width: 0.5),
          //       bottom: BorderSide(
          //         color: CupertinoColors.separator,
          //         width: 0.5,
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
