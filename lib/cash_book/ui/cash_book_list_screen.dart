import 'package:cashledger/cash_book/controller/cash_book_controller.dart';
import 'package:cashledger/cash_book/controller/cash_book_filter.dart';
import 'package:cashledger/cash_book/controller/cash_book_group_provider.dart';
import 'package:cashledger/cash_book/ui/widget/financial_yeaer_selector.dart';
import 'package:cashledger/export/export_utility.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'cash_book_add_edit_screen.dart';

class CashbookScreen extends ConsumerStatefulWidget {
  const CashbookScreen({super.key});

  @override
  ConsumerState<CashbookScreen> createState() => _CashbookScreenState();
}

class _CashbookScreenState extends ConsumerState<CashbookScreen> {
  final DateFormat monthHeaderFormat = DateFormat('MMMM yyyy');
  final DateFormat rowDateFormat = DateFormat('dd MMM yyyy');

  String _monthLabelFromKey(String key) {
    final parts = key.split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    return monthHeaderFormat.format(DateTime(y, m));
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(entriesListProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Cashbook'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            YearSelector(),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.refresh, size: 24),
              onPressed: () => ref.invalidate(entriesListProvider),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.add_circled_solid, size: 24),
              onPressed: () => Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => const AddEntryScreen()),
              ),
            ),
          ],
        ),
      ),
      child: entriesAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.exclamationmark_circle, size: 48,
                  color: CupertinoColors.systemRed),
              const SizedBox(height: 12),
              Text('Failed to load entries',
                  style: TextStyle(color: CupertinoColors.systemRed)),
              const SizedBox(height: 8),
              CupertinoButton(
                onPressed: () => ref.invalidate(entriesListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (entries) => _buildContent(context, ref, entries),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref,
      List<Map<String, dynamic>> entries) {
    final grouped = ref.watch(groupedEntriesProvider);
    final totals = ref.watch(monthlyTotalsProvider);

    if (entries.isEmpty) {
      return const Center(
        child: Text('No entries yet.\nTap + to add one.',
            textAlign: TextAlign.center,
            style: TextStyle(color: CupertinoColors.secondaryLabel)),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildSearchFilterBar(context, ref)),
        for (final section in grouped.entries) ...[
          SliverPersistentHeader(
            pinned: true,
            delegate: _MonthHeaderDelegate(
              monthKey: section.key,
              totals: totals[section.key] ?? const {},
              height: 40,
              monthLabel: _monthLabelFromKey(section.key),
              entries: section.value,
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              CupertinoListSection(
                backgroundColor: CupertinoColors.systemGroupedBackground,
                children: [
                  for (final e in section.value)
                    CupertinoListTile(
                      leading: Icon(
                        e['type'] == 'debit'
                            ? CupertinoIcons.arrow_down_circle_fill
                            : CupertinoIcons.arrow_up_circle_fill,
                        color: e['type'] == 'debit'
                            ? CupertinoColors.activeGreen
                            : CupertinoColors.destructiveRed,
                      ),
                      title: Text(
                        e['description'] ?? 'No description',
                        style: const TextStyle(fontSize: 16),
                      ),
                      subtitle: Text(
                        '${rowDateFormat.format(DateTime.parse(e['date']))} • ${e['accounts']?['name'] ?? 'Unknown'}',
                      ),
                      trailing: Text(
                        '₹${(e['amount'] ?? 0).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: e['type'] == 'debit'
                              ? CupertinoColors.activeGreen
                              : CupertinoColors.destructiveRed,
                        ),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => AddEntryScreen(entry: e),
                        ),
                      ),
                    ),
                ],
              ),
            ]),
          ),
        ],
      ],
    );
  }

  // --- Helper Widgets ---

  Widget _buildSearchFilterBar(BuildContext context, WidgetRef ref) {
    // Removed outer Padding for a better edge-to-edge feel in the Sliver context
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: CupertinoSearchTextField(
              placeholder: 'Search entries...', // Simplified placeholder
              onChanged: (v) =>
                  ref.read(cashbookFilterProvider.notifier).setSearch(v),
            ),
          ),
          // Use standard spacing
          const SizedBox(width: 8),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: const Icon(CupertinoIcons.sort_down, size: 24),
            onPressed: () => _openSortSheet(context, ref),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: const Icon(CupertinoIcons.slider_horizontal_3, size: 24),
            onPressed: () => _openFilterSheet(context, ref),
          ),
        ],
      ),
    );
  }

  // --- Modal Logic Updates ---

  // Sort Sheet remains a standard CupertinoActionSheet (best for iOS)
  void _openSortSheet(BuildContext context, WidgetRef ref) {
    final filter = ref.read(cashbookFilterProvider);

    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Sort By'),
        actions: [
          _sortAction(
            ref,
            'date_desc',
            filter.sort == 'date_desc',
            'Date (Newest First)',
          ),
          _sortAction(
            ref,
            'date_asc',
            filter.sort == 'date_asc',
            'Date (Oldest First)',
          ),
          _sortAction(
            ref,
            'amount_desc',
            filter.sort == 'amount_desc',
            'Amount (High to Low)',
          ),
          _sortAction(
            ref,
            'amount_asc',
            filter.sort == 'amount_asc',
            'Amount (Low to High)',
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  // Filter Sheet is now updated to be a standard ActionSheet for consistency
  void _openFilterSheet(BuildContext context, WidgetRef ref) {
    final filter = ref.read(cashbookFilterProvider);

    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Filter Entry Type'),
        message: CupertinoSegmentedControl(
          groupValue: filter.type,
          children: const {
            'all': Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('All'),
            ),
            'debit': Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('Receipts'), // Clearer label
            ),
            'credit': Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('Expenses'), // Clearer label
            ),
          },
          onValueChanged: (v) {
            ref.read(cashbookFilterProvider.notifier).setType(v);
            Navigator.pop(context); // Close after selection
          },
        ),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              ref.read(cashbookFilterProvider.notifier).clearFilters();
              Navigator.pop(context);
            },
            child: const Text('Clear Filters'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ),
    );
  }

  CupertinoActionSheetAction _sortAction(
    WidgetRef ref,
    String value,
    bool selected,
    String label,
  ) {
    return CupertinoActionSheetAction(
      onPressed: () {
        ref.read(cashbookFilterProvider.notifier).setSort(value);
        Navigator.pop(ref.context);
      },
      child: Text(
        selected ? '✓ $label' : label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class CashbookSummaryCard extends StatelessWidget {
  final double openingBalance;
  final double totalReceipts;
  final double totalExpenses;
  final double balance;

  const CashbookSummaryCard({
    super.key,
    required this.openingBalance,
    required this.totalReceipts,
    required this.totalExpenses,
    required this.balance,
  });

  Widget _summaryItem(String title, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Align text left
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '₹${value.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          // Use a darker background for the card to emphasize it
          color: CupertinoColors.systemGroupedBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: CupertinoColors.separator.withOpacity(0.5),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment
              .spaceBetween, // Use spaceBetween for cleaner layout
          children: [
            Column(
              children: [
                _summaryItem(
                  'Opening Balance',
                  openingBalance,
                  CupertinoColors.secondaryLabel,
                ),

                _summaryItem('Balance', balance, CupertinoColors.activeBlue),
              ],
            ),
            Column(
              children: [
                _summaryItem(
                  'Receipts',
                  totalReceipts,
                  CupertinoColors.activeGreen,
                ),
                _summaryItem(
                  'Expenses',
                  totalExpenses,
                  CupertinoColors.destructiveRed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String monthKey;
  final Map<String, double> totals;
  final double height;
  final String monthLabel;
  final List<Map<String, dynamic>> entries;

  _MonthHeaderDelegate({
    required this.monthKey,
    required this.totals,
    required this.height,
    required this.monthLabel,
    required this.entries,
  });

  // Use a shared currency formatter with ZERO decimal places for compactness
  final NumberFormat _compactFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Safely extract totals
    final openingBalance = totals['openingBalance'] ?? 0.0;
    final receipts = totals['receipts'] ?? 0.0;
    final expenses = totals['expenses'] ?? 0.0;
    final balance = totals['balance'] ?? 0.0;
    //Date
    String fullDateString = "$monthKey-01";

    DateTime dateTimeObject = DateTime.parse(fullDateString);
    final dateFormat = DateFormat('MMM yyy').format(dateTimeObject);
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 10),
      color: CupertinoColors.systemGroupedBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Month Label and Opening Balance (Left Column)
          Text(
            dateFormat.toString(),

            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: CupertinoColors.activeBlue,
            ),
          ),
          Spacer(),
          // 2. Compact Summary Stats (Middle Group)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                // color: CupertinoColors.activeGreen,
                width: 108,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCompactSummaryItem(
                      label: 'Open',
                      amount: openingBalance,
                      color: CupertinoColors.secondaryLabel,
                      formatter: _compactFormatter,
                      // isBold: true,
                    ),
                    SizedBox(height: 2),
                    _buildCompactSummaryItem(
                      label: 'Close',
                      amount: balance,
                      color: CupertinoColors.label,
                      formatter: _compactFormatter,
                      //  isBold: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),
              SizedBox(
                //color: CupertinoColors.activerGreen,
                width: 114,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCompactSummaryItem(
                      label: 'Receipts',
                      amount: receipts,
                      color: CupertinoColors.systemGreen,
                      formatter: _compactFormatter,
                      // isBold: true,
                    ),
                    SizedBox(height: 2),
                    _buildCompactSummaryItem(
                      label: 'Expenses',
                      amount: expenses,
                      color: CupertinoColors.systemRed,
                      formatter: _compactFormatter,
                      //  isBold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(width: 6),

          // 3. Export Button (Far Right)
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => ExportUtils.openDirectExport(
              context: context,
              entries: entries,
              openingBl: openingBalance,
            ),
            child: const Icon(CupertinoIcons.square_arrow_up, size: 22),
          ),
        ],
      ),
    );
  }

  // Helper widget for compact display
  Widget _buildCompactSummaryItem({
    required String label,
    required double amount,
    required Color color,
    required NumberFormat formatter,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          // The labels R, E, Bal are very short, maximizing space for the amount
          '$label : ',
          style: TextStyle(
            color: color,
            fontSize: isBold ? 12 : 11,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
          textAlign: TextAlign.right,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          // The labels R, E, Bal are very short, maximizing space for the amount
          formatter.format(amount),
          style: TextStyle(
            color: color,
            fontSize: isBold ? 12 : 11,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
          textAlign: TextAlign.right,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  double get maxExtent => height;
  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _MonthHeaderDelegate oldDelegate) {
    return oldDelegate.monthKey != monthKey ||
        oldDelegate.totals != totals ||
        oldDelegate.monthLabel != monthLabel;
  }
}
