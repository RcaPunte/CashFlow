import 'package:cashledger/account/model/account_model.dart';
import 'package:cashledger/budget/controller/budget_providers.dart';
import 'package:cashledger/budget/helper/budget_excel_export.dart';
import 'package:cashledger/budget/helper/budget_pdf_export.dart';
import 'package:cashledger/budget/model/budget_item_model.dart';
import 'package:cashledger/budget/model/budget_model.dart';
import 'package:cashledger/budget/ui/budget_add_edit_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BudgetDetailScreen extends ConsumerStatefulWidget {
  final String budgetId;
  const BudgetDetailScreen({super.key, required this.budgetId});

  @override
  ConsumerState<BudgetDetailScreen> createState() =>
      _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends ConsumerState<BudgetDetailScreen> {
  String? _message;
  bool _isError = false;
  final Map<String, bool> _expandedParents = {};

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _message = msg;
      _isError = isError;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _message = null;
          _isError = false;
        });
      }
    });
  }

  void _editOpeningBalance(Budget budget) {
    final controller = TextEditingController(
      text: budget.openingBalance?.toString() ?? '',
    );

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Opening Balance'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            placeholder: '0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefix: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text('₹ ', style: TextStyle(fontSize: 16)),
            ),
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              try {
                final value = double.tryParse(controller.text.trim());
                final updated = budget.copyWith(openingBalance: value);
                final repo = ref.read(budgetRepositoryProvider);
                await repo.updateBudget(updated);
                ref.invalidate(budgetDetailProvider(widget.budgetId));
                ref.invalidate(budgetSummaryProvider(budget));
                if (ctx.mounted) Navigator.pop(ctx);
                _showMessage('Opening balance updated');
              } catch (e) {
                _showMessage('Error: $e', isError: true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editBudgetItem(Budget budget, BudgetItem item) {
    final controller = TextEditingController(
      text: item.budgetedAmount.toString(),
    );

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(item.accountName ?? 'Budget Item'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            placeholder: '0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefix: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text('₹ ', style: TextStyle(fontSize: 16)),
            ),
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              _confirmDeleteItem(budget, item);
            },
            child: const Text('Delete',
                style: TextStyle(color: CupertinoColors.systemRed)),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final amount = double.tryParse(controller.text.trim()) ?? 0;
                final updated = item.copyWith(budgetedAmount: amount);
                final data = updated.toMap();
                data['budget_id'] = budget.id;
                data['previous_actual'] = item.previousActual;
                await Supabase.instance.client
                    .from('budget_items')
                    .update(data)
                    .eq('id', item.id);
                ref.invalidate(budgetItemsProvider(budget));
                ref.invalidate(budgetItemsSimpleProvider(widget.budgetId));
                ref.invalidate(budgetSummaryProvider(budget));
                _showMessage('Item updated');
              } catch (e) {
                _showMessage('Error: $e', isError: true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgetAsync = ref.watch(budgetDetailProvider(widget.budgetId));

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFFFFFFFF).withValues(alpha: 0.96),
        middle: const Text('Budget Detail',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2)),
        trailing: budgetAsync.whenOrNull(
              data: (budget) => _buildTrailing(context, ref, budget),
            ) ??
            const SizedBox.shrink(),
      ),
      child: budgetAsync.when(
        data: (budget) {
          final itemsAsync = ref.watch(budgetItemsProvider(budget));
          final summaryAsync = ref.watch(budgetSummaryProvider(budget));

          return SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _BudgetHeader(budget: budget),
                    const SizedBox(height: 4),
                    summaryAsync.when(
                      data: (summary) => _BudgetSummaryCards(
                        summary: summary,
                        onEditOpeningBalance: () =>
                            _editOpeningBalance(budget),
                      ),
                      loading: () => const SizedBox(
                          height: 80,
                          child: Center(
                              child:
                                  CupertinoActivityIndicator(radius: 16))),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Row(
                        children: [
                          const Text('Budget Items',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1C1C1E),
                                  letterSpacing: -0.1)),
                          const Spacer(),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            borderRadius: BorderRadius.circular(20),
                            color: CupertinoColors.systemBlue,
                            onPressed: () =>
                                _showAddItemSheet(context, ref, budget),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CupertinoIcons.add,
                                    size: 16,
                                    color: CupertinoColors.white),
                                SizedBox(width: 4),
                                Text('Add Item',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: CupertinoColors.white)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: itemsAsync.when(
                        data: (items) =>
                            _buildItemsTable(context, budget, items),
                        loading: () => const Center(
                            child: CupertinoActivityIndicator(radius: 18)),
                        error: (err, _) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemRed
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                      CupertinoIcons
                                          .exclamationmark_triangle,
                                      color: CupertinoColors.systemRed,
                                      size: 24),
                                ),
                                const SizedBox(height: 12),
                                Text('$err',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF8E8E93))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_message != null)
                  Positioned(
                    top: 8,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _isError
                            ? CupertinoColors.systemRed
                            : CupertinoColors.systemGreen,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: (_isError
                                    ? CupertinoColors.systemRed
                                    : CupertinoColors.systemGreen)
                                .withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isError
                                ? CupertinoIcons.xmark_circle_fill
                                : CupertinoIcons.checkmark_alt_circle_fill,
                            color: CupertinoColors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _message!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () =>
            const Center(child: CupertinoActivityIndicator(radius: 20)),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildTrailing(BuildContext context, WidgetRef ref, Budget budget) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _showActionSheet(context, ref, budget),
      child: const Icon(CupertinoIcons.ellipsis_circle, size: 22),
    );
  }

  void _showActionSheet(BuildContext context, WidgetRef ref, Budget budget) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(budget.name),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(CupertinoPageRoute(
                builder: (_) =>
                    BudgetAddEditScreen(existingBudget: budget),
              ));
            },
            child: const Text('Edit Budget'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showExportOptions(context, ref, budget, 'pdf');
            },
            child: const Text('Export PDF'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showExportOptions(context, ref, budget, 'xlsx');
            },
            child: const Text('Export Excel'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _confirmDelete(context, ref, budget);
            },
            child: const Text('Delete Budget'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Budget budget) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete Budget'),
        content: Text(
            'Are you sure you want to delete "${budget.name}"?\n\nThis will also remove all budget items.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(budgetRepositoryProvider)
                    .deleteBudget(budget.id);
                ref.invalidate(budgetListProvider);
                if (context.mounted) Navigator.of(context).pop();
              } catch (e) {
                _showMessage('Delete failed: $e', isError: true);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteItem(Budget budget, BudgetItem item) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(item.accountName ?? 'Budget Item'),
        content: Text(
            'Are you sure you want to delete this budget item?\n\nThis will remove "${item.accountName ?? "this item"}" from the budget.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Supabase.instance.client
                    .from('budget_items')
                    .delete()
                    .eq('id', item.id);
                ref.invalidate(budgetItemsProvider(budget));
                ref.invalidate(
                    budgetItemsSimpleProvider(widget.budgetId));
                ref.invalidate(budgetSummaryProvider(budget));
                _showMessage('Item deleted');
              } catch (e) {
                _showMessage('Delete failed: $e', isError: true);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showExportOptions(BuildContext context, WidgetRef ref, Budget budget, String format) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text('Export ${format.toUpperCase()}'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              final allItems = ref.read(budgetItemsProvider(budget)).asData?.value ?? [];
              // Aggregate: parent totals include children, children hidden
              final parentMap = <String, BudgetItem>{};
              final childMap = <String, List<BudgetItem>>{};
              for (final item in allItems) {
                if (item.parentAccountId == null) {
                  parentMap[item.accountId] = item;
                } else {
                  childMap.putIfAbsent(item.parentAccountId!, () => []).add(item);
                }
              }
              // Merge children into parents
              final mergedItems = <BudgetItem>[];
              for (final entry in parentMap.entries) {
                final parent = entry.value;
                final children = childMap[entry.key] ?? [];
                double childBudgeted = 0, childActual = 0, childPrev = 0;
                for (final c in children) {
                  childBudgeted += c.budgetedAmount;
                  childActual += c.actualAmount ?? 0;
                  childPrev += c.previousActual;
                }
                mergedItems.add(parent.copyWith(
                  budgetedAmount: parent.budgetedAmount + childBudgeted,
                  previousActual: parent.previousActual + childPrev,
                  actualIncome: (parent.actualIncome ?? 0) + children.fold<double>(0, (s, c) => s + (c.actualIncome ?? 0)),
                  actualExpense: (parent.actualExpense ?? 0) + children.fold<double>(0, (s, c) => s + (c.actualExpense ?? 0)),
                ));
              }
              try {
                if (format == 'pdf') {
                  await exportBudgetPdf(budget: budget, items: mergedItems, parentOnly: true);
                } else {
                  await exportBudgetExcel(budget: budget, items: mergedItems, parentOnly: true);
                }
              } catch (e) {
                _showMessage('Export failed', isError: true);
              }
            },
            child: const Text('Parents Only'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              final items = ref.read(budgetItemsProvider(budget)).asData?.value ?? [];
              try {
                if (format == 'pdf') {
                  await exportBudgetPdf(budget: budget, items: items, parentOnly: false);
                } else {
                  await exportBudgetExcel(budget: budget, items: items, parentOnly: false);
                }
              } catch (e) {
                _showMessage('Export failed', isError: true);
              }
            },
            child: const Text('With Children'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _showAddItemSheet(
      BuildContext context, WidgetRef ref, Budget budget) async {
    final repo = ref.read(budgetRepositoryProvider);

    final accountRows = await Supabase.instance.client
        .from('accounts')
        .select()
        .eq('year', budget.year)
        .order('name', ascending: true);
    final accounts = accountRows.map((r) => AccountModel.fromMap(r)).toList();

    if (!context.mounted) return;
    if (accounts.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('No Accounts'),
          content: const Text(
              'Add accounts first before creating budget items.'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Build display names with parent prefix for child accounts
    final parentMap = <String, AccountModel>{};
    for (final a in accounts) {
      parentMap[a.id] = a;
    }
    final displayNames = accounts.map((a) {
      if (a.parentId != null && parentMap.containsKey(a.parentId)) {
        return '  ${parentMap[a.parentId]!.name} › ${a.name}';
      }
      return a.name;
    }).toList();

    String selectedAccId = accounts.first.id;
    final amountController = TextEditingController();
    double? prevActual;
    final prevMap = await repo.fetchPreviousYearActuals(budget: budget);

    if (!context.mounted) return;
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 420,
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Cancel',
                          style: TextStyle(fontSize: 16)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text('Add Budget Item',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Save',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      onPressed: () async {
                        final amount = double.tryParse(
                                amountController.text.trim()) ??
                            0;
                        if (amount <= 0) {
                          Navigator.pop(context);
                          return;
                        }
                        try {
                          final item = BudgetItem(
                            id: '',
                            budgetId: budget.id,
                            accountId: selectedAccId,
                            budgetedAmount: amount,
                            previousActual: prevActual ?? 0,
                          );
                          await repo.addOrUpdateBudgetItem(
                              budget.id, item, prevMap);
                          ref.invalidate(
                              budgetItemsSimpleProvider(widget.budgetId));
                          ref.invalidate(budgetItemsProvider(budget));
                          ref.invalidate(budgetSummaryProvider(budget));
                          if (context.mounted) Navigator.pop(context);
                          _showMessage('Item added');
                        } catch (e) {
                          _showMessage('Error: $e', isError: true);
                        }
                      },
                    ),
                  ],
                ),
              ),
              Container(
                  height: 1,
                  color: CupertinoColors.separator
                      .resolveFrom(context)),
              const SizedBox(height: 8),
              SizedBox(
                height: 140,
                child: CupertinoPicker(
                  itemExtent: 36,
                  onSelectedItemChanged: (index) {
                    selectedAccId = accounts[index].id;
                    prevActual = prevMap[selectedAccId] ?? 0;
                  },
                  children: accounts
                      .map((a) => Center(
                          child: Text(
                              displayNames[accounts.indexOf(a)],
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500))))
                      .toList(),
                ),
              ),
              if (prevActual != null && prevActual! > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Previous year: ₹${prevActual!.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF8E8E93)),
                  ),
                ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CupertinoTextFormFieldRow(
                  controller: amountController,
                  placeholder: 'Budgeted Amount',
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  prefix: const Text('₹ '),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemsTable(
      BuildContext context, Budget budget, List<BudgetItem> items) {
    final currency = NumberFormat.currency(
        locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: CupertinoColors.systemBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(CupertinoIcons.doc_text,
                  size: 30, color: CupertinoColors.systemBlue),
            ),
            const SizedBox(height: 16),
            const Text('No budget items yet',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1E))),
            const SizedBox(height: 4),
            const Text('Tap "Add Item" to add accounts',
                style:
                    TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
          ],
        ),
      );
    }

    // Group items: parent items vs child items
    final Map<String?, List<BudgetItem>> grouped = {};
    for (final item in items) {
      final parentId = item.parentAccountId;
      grouped.putIfAbsent(parentId, () => []).add(item);
    }

    // Parent items (those with no parentAccountId set, or the account's own parent is null)
    final parentItems = <BudgetItem>[];
    final childMap = <String, List<BudgetItem>>{};
    for (final item in items) {
      if (item.parentAccountId == null) {
        parentItems.add(item);
      } else {
        childMap.putIfAbsent(item.parentAccountId!, () => []).add(item);
      }
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6
                    .resolveFrom(context),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Expanded(
                      flex: 3,
                      child: Text('Account',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: Color(0xFF8E8E93)))),
                  const SizedBox(
                      width: 52,
                      child: Text('Budget',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: Color(0xFF8E8E93)),
                          textAlign: TextAlign.right)),
                  const SizedBox(
                      width: 52,
                      child: Text('Income',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: Color(0xFF8E8E93)),
                          textAlign: TextAlign.right)),
                  const SizedBox(
                      width: 52,
                      child: Text('Expense',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: Color(0xFF8E8E93)),
                          textAlign: TextAlign.right)),
                  const SizedBox(
                      width: 48,
                      child: Text('Remain',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: Color(0xFF8E8E93)),
                          textAlign: TextAlign.right)),
                  const SizedBox(
                      width: 42,
                      child: Text('Util%',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: Color(0xFF8E8E93)),
                          textAlign: TextAlign.right)),
                ],
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = parentItems[index];
              final children = childMap[item.accountId] ?? [];

              return _BudgetItemTreeGroup(
                budget: budget,
                parentItem: item,
                children: children,
                currency: currency,
                expanded: _expandedParents[item.accountId] ?? false,
                onToggleExpand: () {
                  setState(() {
                    _expandedParents[item.accountId] =
                        !(_expandedParents[item.accountId] ?? false);
                  });
                },
                onEditBudgetItem: _editBudgetItem,
              );
            },
            childCount: parentItems.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }
}

/// A group row for a parent account and its child budget items
class _BudgetItemTreeGroup extends StatelessWidget {
  final Budget budget;
  final BudgetItem parentItem;
  final List<BudgetItem> children;
  final NumberFormat currency;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final void Function(Budget, BudgetItem) onEditBudgetItem;

  const _BudgetItemTreeGroup({
    required this.budget,
    required this.parentItem,
    required this.children,
    required this.currency,
    required this.expanded,
    required this.onToggleExpand,
    required this.onEditBudgetItem,
  });

  @override
  Widget build(BuildContext context) {
    final budgeted = parentItem.budgetedAmount;
    final income = parentItem.actualIncome;
    final expense = parentItem.actualExpense;
    final remaining = parentItem.remainingBalance;
    final util = parentItem.utilizationPercent;

    // Aggregate children totals
    double childBudgeted = 0, childIncome = 0, childExpense = 0;
    for (final c in children) {
      childBudgeted += c.budgetedAmount;
      childIncome += c.actualIncome ?? 0;
      childExpense += c.actualExpense ?? 0;
    }
    final totalBudgeted = budgeted + childBudgeted;
    final totalIncome = (income ?? 0) + childIncome;
    final totalExpense = (expense ?? 0) + childExpense;
    final hasChildren = children.isNotEmpty;

    return Column(
      children: [
        Container(
          color: const Color(0xFFF9F9FB),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Parent Row ──
              GestureDetector(
                onTap: () => onEditBudgetItem(budget, parentItem),
                child: Row(
                  children: [
                    if (hasChildren)
                      GestureDetector(
                        onTap: onToggleExpand,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFF007AFF)
                                .withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(5),
                          ),
                          child: Icon(
                            expanded
                                ? CupertinoIcons.chevron_down
                                : CupertinoIcons.chevron_right,
                            size: 12,
                            color: const Color(0xFF007AFF),
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 3,
                      child: Text(parentItem.accountName ?? '—',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1C1C1E)),
                          overflow: TextOverflow.ellipsis),
                    ),
                    SizedBox(
                        width: 52,
                        child: Text(
                            currency.format(totalBudgeted),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700))),
                    SizedBox(
                        width: 52,
                        child: Text(
                            totalIncome > 0
                                ? currency.format(totalIncome)
                                : '—',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 12,
                                color:
                                    CupertinoColors.systemGreen,
                                fontWeight: FontWeight.w600))),
                    SizedBox(
                        width: 52,
                        child: Text(
                            totalExpense > 0
                                ? currency.format(totalExpense)
                                : '—',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 12,
                                color:
                                    CupertinoColors.systemRed,
                                fontWeight: FontWeight.w600))),
                    SizedBox(
                        width: 48,
                        child: Text(
                          remaining != null
                              ? currency.format(
                                  remaining - (childExpense))
                              : '—',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: remaining != null &&
                                      remaining < 0
                                  ? CupertinoColors.systemRed
                                  : CupertinoColors.systemGreen),
                        )),
                    SizedBox(width: 42, child: const SizedBox.shrink()),
                  ],
                ),
              ),
              // ── Child rows ──
              if (hasChildren && expanded)
                ...children.map((child) => Padding(
                      padding: const EdgeInsets.only(
                          left: 26, top: 4),
                      child: GestureDetector(
                        onTap: () =>
                            onEditBudgetItem(budget, child),
                        child: Row(
                          children: [
                            const Icon(
                                CupertinoIcons.arrow_turn_down_right,
                                size: 12,
                                color: Color(0xFF8E8E93)),
                            const SizedBox(width: 4),
                            Expanded(
                              flex: 3,
                              child: Text(
                                  child.accountName ?? '—',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color:
                                          Color(0xFF8E8E93)),
                                  overflow:
                                      TextOverflow.ellipsis),
                            ),
                            SizedBox(
                                width: 52,
                                child: Text(
                                    currency.format(
                                        child.budgetedAmount),
                                    textAlign:
                                        TextAlign.right,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color:
                                            Color(0xFF8E8E93)))),
                            SizedBox(
                                width: 52,
                                child: Text(
                                    child.actualIncome != null
                                        ? currency.format(
                                            child.actualIncome!)
                                        : '—',
                                    textAlign:
                                        TextAlign.right,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color:
                                            CupertinoColors
                                                .systemGreen))),
                            SizedBox(
                                width: 52,
                                child: Text(
                                    child.actualExpense != null
                                        ? currency.format(
                                            child.actualExpense!)
                                        : '—',
                                    textAlign:
                                        TextAlign.right,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color:
                                            CupertinoColors
                                                .systemRed))),
                            SizedBox(
                                width: 48,
                                child: Text(
                                    child.remainingBalance !=
                                            null
                                        ? currency.format(child
                                            .remainingBalance!)
                                        : '—',
                                    textAlign:
                                        TextAlign.right,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: child.remainingBalance !=
                                                    null &&
                                                child.remainingBalance! <
                                                    0
                                            ? CupertinoColors
                                                .systemRed
                                            : CupertinoColors
                                                .systemGreen))),
                            const SizedBox(
                                width: 42,
                                child: SizedBox.shrink()),
                          ],
                        ),
                      ),
                    )),
              // ── Subtle separator ──
              Container(
                margin: const EdgeInsets.only(top: 6),
                height: 0.5,
                color: CupertinoColors.separator
                    .resolveFrom(context)
                    .withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// KPI Summary Cards
class _BudgetSummaryCards extends StatelessWidget {
  final BudgetSummary summary;
  final VoidCallback? onEditOpeningBalance;
  const _BudgetSummaryCards(
      {required this.summary, this.onEditOpeningBalance});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
        locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final net = summary.totalActualIncome -
        summary.totalActualExpense;

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _KpiCard(
                      label: 'Prev Year',
                      amount:
                          fmt.format(summary.totalPrevious),
                      icon: CupertinoIcons.clock,
                      color: const Color(0xFF8E8E93))),
              const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  onTap: onEditOpeningBalance,
                  child: _KpiCard(
                      label: 'Opening Bal ✎',
                      amount:
                          fmt.format(summary.openingBalance),
                      icon: CupertinoIcons.money_dollar_circle,
                      color: const Color(0xFFFF9500)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                  child: _KpiCard(
                      label: 'Budgeted',
                      amount:
                          fmt.format(summary.totalBudgeted),
                      icon: CupertinoIcons.doc_text,
                      color: CupertinoColors.systemBlue)),
              const SizedBox(width: 6),
              Expanded(
                  child: _KpiCard(
                      label: 'Income',
                      amount: fmt.format(
                          summary.totalActualIncome),
                      icon: CupertinoIcons.arrow_down_left,
                      color: const Color(0xFF34C759))),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                  child: _KpiCard(
                      label: 'Expenditure',
                      amount: fmt.format(
                          summary.totalActualExpense),
                      icon: CupertinoIcons.arrow_up_right,
                      color: const Color(0xFFFF3B30))),
              const SizedBox(width: 6),
              Expanded(
                  child: _KpiCard(
                      label: 'Remaining',
                      amount: fmt.format(
                          summary.remainingBalance),
                      icon: CupertinoIcons.chart_bar,
                      color: summary.remainingBalance < 0
                          ? const Color(0xFFFF3B30)
                          : const Color(0xFF34C759))),
              const SizedBox(width: 6),
              Expanded(
                  child: _KpiCard(
                      label: 'Net',
                      amount: fmt.format(net),
                      icon: CupertinoIcons.chart_bar_circle,
                      color: net >= 0
                          ? const Color(0xFF34C759)
                          : const Color(0xFFFF3B30))),
              const SizedBox(width: 6),
              Expanded(child: const SizedBox.shrink()),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color color;
  const _KpiCard(
      {required this.label,
      required this.amount,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: CupertinoColors.separator
                .withValues(alpha: 0.25),
            width: 0.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF000000)
                  .withValues(alpha: 0.03),
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
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(7)),
                child: Icon(icon, size: 12, color: color),
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
          Text(amount,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: -0.3)),
        ],
      ),
    );
  }
}

/// Budget Header
class _BudgetHeader extends StatelessWidget {
  final Budget budget;
  const _BudgetHeader({required this.budget});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF007AFF)
                  .withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(budget.name,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: CupertinoColors.white,
                        letterSpacing: -0.2)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CupertinoColors.white
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(budget.status.label,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: CupertinoColors.white)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _tag(context, budget.yearLabel),
              const SizedBox(width: 6),
              _tag(context, budget.type.label),
              const SizedBox(width: 6),
              _tag(context, budget.yearType.shortLabel),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(CupertinoIcons.calendar,
                  size: 13, color: CupertinoColors.white),
              const SizedBox(width: 4),
              Text(budget.dateRange,
                  style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.white,
                      letterSpacing: -0.1)),
            ],
          ),
          if (budget.notes != null &&
              budget.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(budget.notes!,
                style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.white
                        .withValues(alpha: 0.8),
                    fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _tag(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color:
            CupertinoColors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.white)),
    );
  }
}