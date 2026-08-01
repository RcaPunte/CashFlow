import 'package:cashledger/budget/controller/budget_providers.dart';
import 'package:cashledger/budget/model/budget_model.dart';
import 'package:cashledger/budget/ui/budget_add_edit_screen.dart';
import 'package:cashledger/budget/ui/budget_detail_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const double kTabletBreakpoint = 800.0;

class BudgetListScreen extends ConsumerWidget {
  const BudgetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetListProvider);
    final isWide = MediaQuery.of(context).size.width >= kTabletBreakpoint;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFFFFFFFF).withValues(alpha: 0.96),
        middle: const Text('Budgets',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (_) => const BudgetAddEditScreen(),
              ),
            );
          },
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
            child: const Icon(CupertinoIcons.add,
                size: 18, color: CupertinoColors.white),
          ),
        ),
      ),
      child: budgetsAsync.when(
        data: (budgets) {
          if (budgets.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(CupertinoIcons.money_dollar_circle,
                        size: 34, color: CupertinoColors.systemBlue),
                  ),
                  const SizedBox(height: 20),
                  const Text('No budgets yet',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1C1E))),
                  const SizedBox(height: 6),
                  const Text('Tap + to create your first budget',
                      style: TextStyle(
                          fontSize: 14, color: Color(0xFF8E8E93))),
                ],
              ),
            );
          }

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 560 : double.infinity,
                ),
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 0 : 12, vertical: 8),
                  itemCount: budgets.length,
                  itemBuilder: (context, index) =>
                      _BudgetRow(budget: budgets[index]),
                ),
              ),
            ),
          );
        },
        loading: () =>
            const Center(child: CupertinoActivityIndicator(radius: 20)),
        error: (err, st) => Center(
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
                Text('$err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF8E8E93))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BudgetRow extends ConsumerWidget {
  final Budget budget;
  const _BudgetRow({required this.budget});

  Color _statusColor(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.draft:
        return const Color(0xFFFF9500);
      case BudgetStatus.submitted:
        return CupertinoColors.systemBlue;
      case BudgetStatus.approved:
        return const Color(0xFF34C759);
      case BudgetStatus.rejected:
        return CupertinoColors.systemRed;
    }
  }

  IconData _typeIcon(BudgetType type) {
    switch (type) {
      case BudgetType.annual:
        return CupertinoIcons.calendar;
      case BudgetType.supplementary:
        return CupertinoIcons.add_circled;
      case BudgetType.emergency:
        return CupertinoIcons.exclamationmark_triangle;
      case BudgetType.revised:
        return CupertinoIcons.pencil_ellipsis_rectangle;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _statusColor(budget.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: CupertinoColors.separator.withValues(alpha: 0.25),
            width: 0.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1)),
        ],
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderRadius: BorderRadius.circular(14),
        onPressed: () {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (_) => BudgetDetailScreen(budgetId: budget.id),
            ),
          );
        },
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_typeIcon(budget.type), color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(budget.name,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1C1C1E),
                          letterSpacing: -0.1)),
                  const SizedBox(height: 2),
                  Text(
                    '${budget.yearLabel} · ${budget.type.label} · ${budget.yearType.shortLabel}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF8E8E93)),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                budget.status.label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(CupertinoIcons.chevron_right,
                size: 16, color: CupertinoColors.systemGrey),
          ],
        ),
      ),
    );
  }
}