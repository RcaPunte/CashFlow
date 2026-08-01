import 'package:cashledger/account/controller/account_controller.dart';
import 'package:cashledger/account/model/account_model.dart';
import 'package:cashledger/budget/controller/budget_providers.dart';
import 'package:cashledger/budget/model/budget_item_model.dart';
import 'package:cashledger/budget/model/budget_model.dart';
import 'package:cashledger/budget/repository/budget_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const double kTabletBreakpoint = 800.0;

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
      await Supabase.instance.client
          .from('budget_items')
          .delete()
          .eq('budget_id', budget.id)
          .eq('account_id', widget.account.id);
      setState(() => _assignedBudgetIds.remove(budget.id));
    } else {
      final prevMap = await repo.fetchPreviousYearActuals(budget: budget);
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
    final isWide = MediaQuery.of(context).size.width >= kTabletBreakpoint;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFFFFFFFF).withValues(alpha: 0.96),
        middle: const Text('Edit Account',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2)),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWide ? 560 : double.infinity,
            ),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                  isWide ? 0 : 12, 16, isWide ? 0 : 12, 40),
              children: [
                // ── Name ──
                Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: CupertinoColors.separator
                            .withValues(alpha: 0.25),
                        width: 0.5),
                  ),
                  child: CupertinoTextFormFieldRow(
                    controller: _nameController,
                    placeholder: 'Account name',
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Icon(CupertinoIcons.person,
                          size: 20, color: CupertinoColors.systemBlue),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Description ──
                Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: CupertinoColors.separator
                            .withValues(alpha: 0.25),
                        width: 0.5),
                  ),
                  child: CupertinoTextFormFieldRow(
                    controller: _descriptionController,
                    placeholder: 'Description',
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Icon(CupertinoIcons.doc_text,
                          size: 20, color: CupertinoColors.systemGrey),
                    ),
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Limit ──
                Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: CupertinoColors.separator
                            .withValues(alpha: 0.25),
                        width: 0.5),
                  ),
                  child: CupertinoTextFormFieldRow(
                    controller: _limitController,
                    placeholder: 'Limit amount',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Text('₹',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF1C1C1E))),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Save ──
                CupertinoButton(
                  color: CupertinoColors.systemBlue,
                  borderRadius: BorderRadius.circular(14),
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                  child: const Text('Save',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: CupertinoColors.white,
                          letterSpacing: -0.1)),
                ),
                const SizedBox(height: 32),

                // ── Budget Assignment ──
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBlue
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(CupertinoIcons.money_dollar_circle,
                          size: 14, color: CupertinoColors.systemBlue),
                    ),
                    const SizedBox(width: 8),
                    const Text('Assign to Budgets',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C1C1E),
                            letterSpacing: -0.1)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Select budgets this account belongs to. Amounts can be set from the budget detail screen.',
                  style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel
                          .resolveFrom(context)),
                ),
                const SizedBox(height: 12),

                if (_isLoadingBudgets)
                  const Center(
                      child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CupertinoActivityIndicator(radius: 16),
                  ))
                else if (_allBudgets.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: CupertinoColors.separator
                                .withValues(alpha: 0.25),
                            width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9500)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                                CupertinoIcons.exclamationmark_circle,
                                size: 16,
                                color: Color(0xFFFF9500)),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text('No budgets yet. Create one first.',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF8E8E93))),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._allBudgets.map((budget) {
                    final isAssigned =
                        _assignedBudgetIds.contains(budget.id);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: CupertinoColors.separator
                              .withValues(alpha: 0.25),
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF000000)
                                  .withValues(alpha: 0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 1)),
                        ],
                      ),
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        borderRadius: BorderRadius.circular(14),
                        onPressed: () => _toggleBudget(budget),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isAssigned
                                      ? CupertinoColors.systemBlue
                                      : CupertinoColors.systemGrey,
                                  width: 2,
                                ),
                                color: isAssigned
                                    ? CupertinoColors.systemBlue
                                    : CupertinoColors.systemBackground,
                              ),
                              child: isAssigned
                                  ? const Icon(CupertinoIcons.checkmark,
                                      size: 14,
                                      color: CupertinoColors.white)
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
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1C1C1E))),
                                  Text(
                                    '${budget.yearLabel} · ${budget.type.label}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: CupertinoColors
                                            .secondaryLabel
                                            .resolveFrom(context)),
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
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                budget.status.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _statusColor(budget.status),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
}