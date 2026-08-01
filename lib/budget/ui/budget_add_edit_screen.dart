import 'package:cashledger/budget/controller/budget_providers.dart';
import 'package:cashledger/budget/model/budget_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Create or edit a budget (metadata only — items are added from the detail screen)
class BudgetAddEditScreen extends ConsumerStatefulWidget {
  final Budget? existingBudget;
  const BudgetAddEditScreen({super.key, this.existingBudget});

  @override
  ConsumerState<BudgetAddEditScreen> createState() =>
      _BudgetAddEditScreenState();
}

class _BudgetAddEditScreenState extends ConsumerState<BudgetAddEditScreen> {
  late final TextEditingController _nameController;
  late int _selectedYear;
  late YearType _yearType;
  late BudgetType _budgetType;
  final _notesController = TextEditingController();
  final _openingBalanceController = TextEditingController();
  bool _isSaving = false;

  bool get isEditing => widget.existingBudget != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingBudget;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _selectedYear = existing?.year ?? DateTime.now().year;
    _yearType = existing?.yearType ?? YearType.calendar;
    _budgetType = existing?.type ?? BudgetType.annual;
    _notesController.text = existing?.notes ?? '';
    _openingBalanceController.text =
        existing?.openingBalance?.toString() ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(isEditing ? 'Edit Budget' : 'New Budget'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const CupertinoActivityIndicator()
              : const Text('Save'),
        ),
      ),
      child: _buildForm(),
    );
  }

  Widget _buildForm() {
    final years = List.generate(5, (i) => DateTime.now().year - 2 + i);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Budget Name ──
              CupertinoTextFormFieldRow(
                controller: _nameController,
                placeholder: 'Budget Name',
                prefix: const Text('Name'),
              ),
              const SizedBox(height: 16),

              // ── Year Type ──
              const Text('Year Type',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              CupertinoSlidingSegmentedControl<YearType>(
                groupValue: _yearType,
                onValueChanged: (val) {
                  if (val != null) setState(() => _yearType = val);
                },
                children: {
                  YearType.calendar: Text(YearType.calendar.shortLabel),
                  YearType.financial: Text(YearType.financial.shortLabel),
                },
              ),
              const SizedBox(height: 16),

              // ── Year ──
              SizedBox(
                height: 200,
                child: CupertinoPicker(
                  itemExtent: 32,
                  scrollController: FixedExtentScrollController(
                    initialItem: years.indexOf(_selectedYear),
                  ),
                  onSelectedItemChanged: (index) {
                    setState(() => _selectedYear = years[index]);
                  },
                  children: years.map((y) {
                    final label = _yearType == YearType.financial
                        ? 'FY $y-${(y + 1).toString().substring(2)}'
                        : '$y';
                    return Center(child: Text(label));
                  }).toList(),
                ),
              ),
              Text(
                _yearType == YearType.financial
                    ? 'Period: Apr $_selectedYear – Mar ${_selectedYear + 1}'
                    : 'Period: Jan $_selectedYear – Dec $_selectedYear',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel
                        .resolveFrom(context)),
              ),
              const SizedBox(height: 16),

              // ── Budget Type ──
              CupertinoSlidingSegmentedControl<BudgetType>(
                groupValue: _budgetType,
                onValueChanged: (val) {
                  if (val != null) setState(() => _budgetType = val);
                },
                children: {
                  BudgetType.annual: const Text('Annual'),
                  BudgetType.supplementary: const Text('Suppl'),
                  BudgetType.emergency: const Text('Emerg'),
                  BudgetType.revised: const Text('Revised'),
                },
              ),
              const SizedBox(height: 16),

              // ── Opening Balance ──
              CupertinoTextFormFieldRow(
                controller: _openingBalanceController,
                placeholder: '0',
                keyboardType: TextInputType.number,
                prefix: const Text('Opening Balance (₹)'),
              ),
              const SizedBox(height: 16),

              // ── Notes ──
              CupertinoTextFormFieldRow(
                controller: _notesController,
                placeholder: 'Optional notes',
                prefix: const Text('Notes'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // ── Info ──
              Text(
                'After saving, you can add budget items (accounts with amounts) from the budget detail screen.',
                style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                    fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: const Text('Please enter a budget name'),
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

    setState(() => _isSaving = true);

    final repo = ref.read(budgetRepositoryProvider);
    final openingBalance =
        double.tryParse(_openingBalanceController.text.trim());

    try {
      Budget budget = Budget(
        id: widget.existingBudget?.id ?? '',
        name: name,
        year: _selectedYear,
        yearType: _yearType,
        type: _budgetType,
        status: widget.existingBudget?.status ?? BudgetStatus.draft,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: widget.existingBudget?.createdAt ?? DateTime.now(),
        userId: '',
        openingBalance: openingBalance,
      );

      if (isEditing) {
        await repo.updateBudget(budget);
      } else {
        await repo.createBudget(budget);
      }

      ref.invalidate(budgetListProvider);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('$e'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}