import 'package:cashledger/account/controller/account_controller.dart'
    show accountControllerProvider;
import 'package:cashledger/account/controller/account_total_provider.dart';
import 'package:cashledger/export/account_export.dart' show AccountExportUtils;
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

const double kTabletBreakpoint = 800.0;

class AccountListScreen extends HookConsumerWidget {
  const AccountListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountControllerProvider);
    final totalsAsync = ref.watch(accountTotalsProvider);
    final fmt = NumberFormat('#,##,###', 'en_IN');
    final isWide = MediaQuery.of(context).size.width >= kTabletBreakpoint;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFFFFFFFF).withValues(alpha: 0.96),
        middle: const Text('Accounts',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () async {
                final accounts = accountsAsync.asData?.value ?? [];
                final totals = totalsAsync.asData?.value ?? {};
                if (accounts.isEmpty) return;
                await AccountExportUtils.openExportSheet(
                  context: context,
                  totals: totals,
                  accounts: accounts,
                );
              },
              child: const Icon(CupertinoIcons.square_arrow_up, size: 22),
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
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF007AFF).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(CupertinoIcons.add, size: 18,
                    color: CupertinoColors.white),
              ),
              onPressed: () => context.push('/accounts/add'),
            ),
          ],
        ),
      ),
      child: accountsAsync.when(
        loading: () =>
            const Center(child: CupertinoActivityIndicator(radius: 20)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(CupertinoIcons.exclamationmark_triangle,
                    size: 28, color: Color(0xFFFF3B30)),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                    e.toString().length > 60
                        ? '${e.toString().substring(0, 60)}...'
                        : e.toString(),
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF8E8E93)),
                    textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(CupertinoIcons.folder,
                        size: 34, color: CupertinoColors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text('No Accounts Yet',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1C1E))),
                  const SizedBox(height: 6),
                  const Text('Start by creating your first account',
                      style: TextStyle(
                          fontSize: 14, color: Color(0xFF8E8E93))),
                ],
              ),
            );
          }

          final totals = totalsAsync.asData?.value ?? {};
          final totalIn =
              totals.values.fold(0.0, (s, v) => s + (v['in'] ?? 0));
          final totalOut =
              totals.values.fold(0.0, (s, v) => s + (v['out'] ?? 0));
          final net = totalIn - totalOut;

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 560 : double.infinity,
                ),
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                          horizontal: isWide ? 0 : 12),
                      sliver: SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: _KpiCard(
                                  label: 'Total Income',
                                  amount: totalIn,
                                  color: const Color(0xFF34C759),
                                  icon: CupertinoIcons
                                      .arrow_down_left_circle_fill,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _KpiCard(
                                  label: 'Total Expenditure',
                                  amount: totalOut,
                                  color: const Color(0xFFFF3B30),
                                  icon: CupertinoIcons
                                      .arrow_up_right_circle_fill,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _KpiCard(
                                  label: 'Net',
                                  amount: net,
                                  color: net >= 0
                                      ? const Color(0xFF007AFF)
                                      : const Color(0xFFFF3B30),
                                  icon: CupertinoIcons
                                      .chart_bar_circle_fill,
                                  isBalance: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                          horizontal: isWide ? 0 : 12),
                      sliver: SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                              4, 8, 4, 8),
                          child: Text('All Accounts',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1C1C1E)
                                      .withValues(alpha: 0.9),
                                  letterSpacing: -0.1)),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          final acc = list[i];
                          final accIn =
                              (totals[acc.id]?['in'] ?? 0);
                          final accOut =
                              (totals[acc.id]?['out'] ?? 0);
                          final accNet = accIn - accOut;

                          return Container(
                            margin: EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color:
                                  CupertinoColors.systemBackground,
                              borderRadius:
                                  BorderRadius.circular(14),
                              border: Border.all(
                                  color: CupertinoColors.separator
                                      .withValues(alpha: 0.25),
                                  width: 0.5),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFF000000)
                                        .withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset:
                                        const Offset(0, 1)),
                              ],
                            ),
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              borderRadius:
                                  BorderRadius.circular(14),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/accounts/edit',
                                  arguments: acc,
                                );
                              },
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      gradient:
                                          const LinearGradient(
                                        colors: [
                                          Color(0xFF007AFF),
                                          Color(0xFF5856D6)
                                        ],
                                        begin:
                                            Alignment.topLeft,
                                        end: Alignment
                                            .bottomRight,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(
                                              12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        acc.name.isNotEmpty
                                            ? acc.name[0]
                                                .toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color:
                                              CupertinoColors
                                                  .white,
                                          fontSize: 18,
                                          fontWeight:
                                              FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(
                                          acc.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                                FontWeight.w600,
                                            color: Color(
                                                0xFF1C1C1E),
                                            letterSpacing: -0.1,
                                          ),
                                        ),
                                        const SizedBox(
                                            height: 4),
                                        Row(
                                          children: [
                                            _miniStat(
                                              'Income',
                                              accIn,
                                              const Color(
                                                  0xFF34C759),
                                            ),
                                            const SizedBox(
                                                width: 12),
                                            _miniStat(
                                              'Expense',
                                              accOut,
                                              const Color(
                                                  0xFFFF3B30),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹ ${fmt.format(accNet.round())}',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight:
                                              FontWeight.w700,
                                          color: accNet >= 0
                                              ? const Color(
                                                  0xFF34C759)
                                              : const Color(
                                                  0xFFFF3B30),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Balance',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Color(
                                                0xFF8E8E93)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                      CupertinoIcons
                                          .chevron_right,
                                      size: 14,
                                      color: Color(0xFFC7C7CC)),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: list.length,
                      ),
                    ),
                    const SliverToBoxAdapter(
                        child: SizedBox(height: 20)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _miniStat(String label, double value, Color color) {
    final fmt = NumberFormat('#,##,##0', 'en_IN');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ',
            style: const TextStyle(
                fontSize: 11, color: Color(0xFF8E8E93))),
        Text('₹ ${fmt.format(value)}',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color)),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final bool isBalance;

  const _KpiCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    this.isBalance = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: CupertinoColors.separator.withValues(alpha: 0.25),
            width: 0.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(7)),
                child: Icon(icon, size: 13, color: color),
              ),
              const Spacer(),
              if (isBalance)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    amount >= 0 ? 'NET' : 'DEF',
                    style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 0.5),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF8E8E93),
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1)),
          const SizedBox(height: 1),
          Text(
            '₹ ${NumberFormat('#,##,###').format(amount.round())}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: -0.3),
          ),
        ],
      ),
    );
  }
}