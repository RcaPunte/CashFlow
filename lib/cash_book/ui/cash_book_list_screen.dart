import 'package:cashledger/cash_book/controller/cash_book_controller.dart';
import 'package:cashledger/cash_book/controller/cash_book_filter.dart';
import 'package:cashledger/cash_book/controller/cash_book_group_provider.dart';
import 'package:cashledger/cash_book/ui/widget/financial_yeaer_selector.dart';
import 'package:cashledger/export/export_utility.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'cash_book_add_edit_screen.dart';

const double kTabletBreakpoint = 800.0;

class CashbookScreen extends ConsumerStatefulWidget {
  const CashbookScreen({super.key});

  @override
  ConsumerState<CashbookScreen> createState() => _CashbookScreenState();
}

class _CashbookScreenState extends ConsumerState<CashbookScreen> {
  final DateFormat monthHeaderFormat = DateFormat('MMMM yyyy');
  final DateFormat rowDateFormat = DateFormat('dd MMM yyyy');
  final NumberFormat _amountFormat = NumberFormat.currency(
      locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  String _monthLabelFromKey(String key) {
    final parts = key.split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    return monthHeaderFormat.format(DateTime(y, m));
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(entriesListProvider);
    final isWide = MediaQuery.of(context).size.width >= kTabletBreakpoint;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFFFFFFFF).withValues(alpha: 0.96),
        middle: const Text('Cash Book',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const YearSelector(),
            const SizedBox(width: 4),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.arrow_counterclockwise,
                  size: 20, color: Color(0xFF007AFF)),
              onPressed: () => ref.invalidate(entriesListProvider),
            ),
            const SizedBox(width: 4),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(CupertinoIcons.add,
                    size: 18, color: CupertinoColors.white),
              ),
              onPressed: () => Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: (_) => const AddEntryScreen()),
              ),
            ),
          ],
        ),
      ),
      child: entriesAsync.when(
        loading: () =>
            const Center(child: CupertinoActivityIndicator(radius: 20)),
        error: (e, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(CupertinoIcons.exclamationmark_triangle,
                      color: CupertinoColors.systemRed, size: 24),
                ),
                const SizedBox(height: 12),
                Text('$e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF8E8E93))),
              ],
            ),
          ),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBlue
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(CupertinoIcons.list_bullet,
                        size: 34, color: CupertinoColors.systemBlue),
                  ),
                  const SizedBox(height: 20),
                  const Text('No entries yet',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1C1E))),
                  const SizedBox(height: 6),
                  const Text('Tap + to add your first entry',
                      style: TextStyle(
                          fontSize: 14, color: Color(0xFF8E8E93))),
                ],
              ),
            );
          }

          // Group entries by month
          final grouped = <String, List<Map<String, dynamic>>>{};
          for (final e in entries) {
            final date = DateTime.parse(e['date']);
            final key =
                '${date.year}-${date.month.toString().padLeft(2, '0')}';
            grouped.putIfAbsent(key, () => []).add(e);
          }
          final sortedKeys = grouped.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 560 : double.infinity,
                ),
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 0 : 12, vertical: 8),
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, idx) {
                    final key = sortedKeys[idx];
                    final monthEntries = grouped[key]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 4, top: 12, bottom: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF007AFF)
                                      .withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                    CupertinoIcons.calendar,
                                    size: 14,
                                    color: Color(0xFF007AFF)),
                              ),
                              const SizedBox(width: 8),
                              Text(_monthLabelFromKey(key),
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1C1C1E),
                                      letterSpacing: -0.1)),
                            ],
                          ),
                        ),
                        ...monthEntries.map((entry) {
                          final isDebit = entry['type'] == 'debit';
                          final amount =
                              (entry['amount'] as num).toDouble();
                          final accountName =
                              entry['accounts']?['name'] ?? '—';
                          final description =
                              entry['description'] as String? ?? '';
                          final date =
                              DateTime.parse(entry['date']);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color:
                                  CupertinoColors.systemBackground,
                              borderRadius:
                                  BorderRadius.circular(14),
                              border: Border.all(
                                  color: CupertinoColors.separator
                                      .withValues(alpha: 0.25),
                                  width: 0.5),
                            ),
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              borderRadius:
                                  BorderRadius.circular(14),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (_) => AddEntryScreen(
                                        entry: entry),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: isDebit
                                          ? const Color(0xFF34C759)
                                              .withValues(
                                                  alpha: 0.1)
                                          : const Color(0xFFFF3B30)
                                              .withValues(
                                                  alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(
                                              10),
                                    ),
                                    child: Icon(
                                      isDebit
                                          ? CupertinoIcons
                                              .arrow_down_left
                                          : CupertinoIcons
                                              .arrow_up_right,
                                      size: 18,
                                      color: isDebit
                                          ? const Color(
                                              0xFF34C759)
                                          : const Color(
                                              0xFFFF3B30),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(accountName,
                                            style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight:
                                                    FontWeight
                                                        .w600,
                                                color: Color(
                                                    0xFF1C1C1E),
                                                letterSpacing:
                                                    -0.1)),
                                        if (description
                                            .isNotEmpty)
                                          Text(description,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(
                                                      0xFF8E8E93)),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow
                                                      .ellipsis),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _amountFormat
                                            .format(amount),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight:
                                              FontWeight.w700,
                                          color: isDebit
                                              ? const Color(
                                                  0xFF34C759)
                                              : const Color(
                                                  0xFFFF3B30),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        rowDateFormat
                                            .format(date),
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(
                                                0xFF8E8E93)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}