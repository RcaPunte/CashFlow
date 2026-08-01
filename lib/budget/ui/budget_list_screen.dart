import 'package:cashledger/budget/controller/budget_providers.dart';
import 'package:cashledger/budget/model/budget_model.dart';
import 'package:cashledger/budget/ui/budget_add_edit_screen.dart';
import 'package:cashledger/budget/ui/budget_detail_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Displays all budgets for the organization
class BudgetListScreen extends ConsumerWidget {
  const BudgetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetListProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Budgets'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (_) => const BudgetAddEditScreen(),
              ),
            );
          },
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: budgetsAsync.when(
        data: (budgets) {
          if (budgets.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.money_dollar_circle,
                      size: 64, color: CupertinoColors.systemGrey),
                  SizedBox(height: 16),
                  Text(
                    'No budgets yet',
                    style: TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.systemGrey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to create your first budget',
                    style: TextStyle(
                        color: CupertinoColors.secondaryLabel),
                  ),
                ],
              ),
            );
          }
          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final budget = budgets[index];
                    return _BudgetRow(budget: budget);
                  },
                  childCount: budgets.length,
                ),
              ),
            ],
          );
        },
        loading: () =>
            const Center(child: CupertinoActivityIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _BudgetRow extends ConsumerWidget {
  final Budget budget;
  const _BudgetRow({required this.budget});

  Color _statusColor(BuildContext context, BudgetStatus status) {
    switch (status) {
      case BudgetStatus.draft:
        return CupertinoColors.systemOrange;
      case BudgetStatus.submitted:
        return CupertinoColors.systemBlue;
      case BudgetStatus.approved:
        return CupertinoColors.systemGreen;
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
    final color = _statusColor(context, budget.status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: CupertinoListTile(
        leading: Icon(_typeIcon(budget.type), color: color, size: 28),
        title: Text(budget.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          budget.accountName ??
              '${budget.yearLabel} · ${budget.type.label} · ${budget.yearType.shortLabel}',
          style: const TextStyle(fontSize: 13),
        ),
        additionalInfo: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            budget.status.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        trailing: const Icon(CupertinoIcons.chevron_right,
            size: 18, color: CupertinoColors.systemGrey),
        onTap: () {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (_) => BudgetDetailScreen(budgetId: budget.id),
            ),
          );
        },
      ),
    );
  }
}