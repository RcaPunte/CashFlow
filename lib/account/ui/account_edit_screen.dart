import 'package:cashledger/account/controller/account_controller.dart';
import 'package:cashledger/account/model/account_model.dart';
import 'package:cashledger/budget/controller/budget_providers.dart';
import 'package:cashledger/budget/model/budget_item_model.dart';
import 'package:cashledger/budget/model/budget_model.dart';
import 'package:cashledger/budget/repository/budget_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountEditScreen extends ConsumerStatefulWidget {
  final AccountModel account;
  const AccountEditScreen({super.key, required this.account});

  @override
  ConsumerState<AccountEditScreen> createState() => _AccountEditScreenState();
}

class _AccountEditScreenState extends ConsumerState<AccountEditScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _limitController;

  List<Budget> _allBudgets = [];
  Set<String> _assignedBudgetIds = {};
  bool _isLoadingBudgets = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account.name);
    _descriptionController =
        TextEditingController(text: widget.account.description);
    _limitController = TextEditingController(
      text: widget.account.limitAmount?.toString() ?? '',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBudgets());
  }

  Future<void> _loadBudgets() async {
    try {
      final repo = BudgetRepository();
      final budgets = await repo.fetchBudgets();

      // Find existing budget items for this account
      final supabase = Supabase.instance.client;
      final items = await supabase
          .from('budget_items')
          .select('budget_id')
          .eq('account_id', widget.account.id);

      final assignedIds =
          items.map<String>((r) => r['budget_id'] as String).toSet();

      if (mounted) {
        setState(() {
          _allBudgets = budgets;
          _assignedBudgetIds = assignedIds;
          _isLoadingBudgets = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingBudgets = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _toggleBudget(Budget budget) async {
    final repo = BudgetRepository();
    final isAssigned = _assignedBudgetIds.contains(budget.id);

    if (isAssigned) {
      // Remove from budget — delete the budget_item row
      await Supabase.instance.client
          .from('budget_items')
          .delete()
          .eq('budget_id', budget.id)
          .eq('account_id', widget.account.id);
      setState(() => _assignedBudgetIds.remove(budget.id));
    } else {
      // Add to budget — create a budget_item with amount 0
      final prevMap =
          await repo.fetchPreviousYearActuals(budget: budget);
      final item = BudgetItem(
        id: '',
        budgetId: budget.id,
        accountId: widget.account.id,
        budgetedAmount: 0,
        previousActual: prevMap[widget.account.id] ?? 0,
      );
      await repo.addOrUpdateBudgetItem(budget.id, item, prevMap);
      setState(() => _assignedBudgetIds.add(budget.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text("Edit Account"),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Name ──
              CupertinoTextField(
                controller: _nameController,
                placeholder: "Account name",
              ),
              const SizedBox(height: 12),

              // ── Description ──
              CupertinoTextField(
                controller: _descriptionController,
                placeholder: "Description",
              ),
              const SizedBox(height: 12),

              // ── Limit ──
              CupertinoTextField(
                controller: _limitController,
                placeholder: "Limit amount",
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),

              // ── Save ──
              CupertinoButton.filled(
                child: const Text("Save"),
                onPressed: () async {
                  final updated = widget.account.copyWith(
                    name: _nameController.text,
                    description: _descriptionController.text,
                    limitAmount: _limitController.text.isEmpty
                        ? null
                        : double.parse(_limitController.text),
                  );

                  await ref
                      .read(accountControllerProvider.notifier)
                      .update(widget.account.id, updated);

                  if (context.mounted) Navigator.pop(context);
                },
              ),
              const SizedBox(height: 32),

              // ── Budget Assignment ──
              Row(
                children: [
                  const Icon(CupertinoIcons.money_dollar_circle,
                      size: 20, color: CupertinoColors.systemBlue),
                  const SizedBox(width: 8),
                  const Text("Assign to Budgets",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1C1E))),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Select budgets this account belongs to. Amounts can be set from the budget detail screen.",
                style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel
                        .resolveFrom(context)),
              ),
              const SizedBox(height: 12),

              if (_isLoadingBudgets)
                const Center(child: CupertinoActivityIndicator())
              else if (_allBudgets.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text("No budgets yet. Create one first.",
                      style: TextStyle(color: CupertinoColors.systemGrey)),
                )
              else
                ..._allBudgets.map((budget) {
                  final isAssigned =
                      _assignedBudgetIds.contains(budget.id);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CupertinoColors.separator
                            .withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      borderRadius: BorderRadius.circular(12),
                      onPressed: () => _toggleBudget(budget),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(6),
                              border: Border.all(
                                color: isAssigned
                                    ? CupertinoColors.systemBlue
                                    : CupertinoColors.systemGrey,
                                width: 2,
                              ),
                              color: isAssigned
                                  ? CupertinoColors.systemBlue
                                  : CupertinoColors
                                      .systemBackground,
                            ),
                            child: isAssigned
                                ? const Icon(
                                    CupertinoIcons.checkmark,
                                    size: 14,
                                    color:
                                        CupertinoColors.white)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(budget.name,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight:
                                            FontWeight.w600,
                                        color:
                                            Color(0xFF1C1C1E))),
                                Text(
                                  '${budget.yearLabel} · ${budget.type.label}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: CupertinoColors
                                          .secondaryLabel
                                          .resolveFrom(
                                              context)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _statusColor(budget.status)
                                  .withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Text(
                              budget.status.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color:
                                    _statusColor(budget.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(BudgetStatus status) {
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
}