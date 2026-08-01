import 'package:cashledger/budget/controller/budget_providers.dart';
import 'package:cashledger/budget/model/budget_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const double kTabletBreakpoint = 800.0;

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
    final isWide = MediaQuery.of(context).size.width >= kTabletBreakpoint;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFFFFFFFF).withValues(alpha: 0.96),
        middle: Text(isEditing ? 'Edit Budget' : 'New Budget',
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const CupertinoActivityIndicator()
              : const Text('Save',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600)),
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWide ? 560 : double.infinity,
            ),
            child: _buildForm(isWide: isWide),
          ),
        ),
      ),
    );
  }

  Widget _buildForm({required bool isWide}) {
    final years = List.generate(5, (i) => DateTime.now().year - 2 + i);

    return ListView(
      padding: EdgeInsets.fromLTRB(
          isWide ? 0 : 12, 16, isWide ? 0 : 12, 40),
      children: [
        // ── Budget Name ──
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
            placeholder: 'Budget Name',
            prefix: const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Icon(CupertinoIcons.doc_text,
                  size: 20, color: CupertinoColors.systemBlue),
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 16),

        // ── Year Type ──
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: CupertinoColors.separator
                    .withValues(alpha: 0.25),
                width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 12, top: 8),
                child: Text('Year Type',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF8E8E93))),
              ),
              CupertinoSlidingSegmentedControl<YearType>(
                groupValue: _yearType,
                backgroundColor:
                    CupertinoColors.systemBackground,
                thumbColor: CupertinoColors.systemBlue,
                padding: const EdgeInsets.all(4),
                onValueChanged: (val) {
                  if (val != null) setState(() => _yearType = val);
                },
                children: {
                  YearType.calendar: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(YearType.calendar.shortLabel,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ),
                  YearType.financial: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(YearType.financial.shortLabel,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ),
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Year Picker ──
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: CupertinoColors.separator
                    .withValues(alpha: 0.25),
                width: 0.5),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 160,
                child: CupertinoPicker(
                  itemExtent: 36,
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
                    return Center(
                        child: Text(label,
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500)));
                  }).toList(),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _yearType == YearType.financial
                    ? 'Period: Apr $_selectedYear – Mar ${_selectedYear + 1}'
                    : 'Period: Jan $_selectedYear – Dec $_selectedYear',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF8E8E93)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Budget Type ──
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: CupertinoColors.separator
                    .withValues(alpha: 0.25),
                width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 12, top: 8),
                child: Text('Budget Type',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF8E8E93))),
              ),
              CupertinoSlidingSegmentedControl<BudgetType>(
                groupValue: _budgetType,
                backgroundColor:
                    CupertinoColors.systemBackground,
                thumbColor: CupertinoColors.systemBlue,
                padding: const EdgeInsets.all(4),
                onValueChanged: (val) {
                  if (val != null) setState(() => _budgetType = val);
                },
                children: const {
                  BudgetType.annual: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('Annual',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ),
                  BudgetType.supplementary: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('Suppl',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ),
                  BudgetType.emergency: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('Emerg',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ),
                  BudgetType.revised: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('Revised',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ),
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Opening Balance ──
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
            controller: _openingBalanceController,
            placeholder: '0',
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            prefix: const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Text('Opening Balance',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1C1C1E))),
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 12),

        // ── Notes ──
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
            controller: _notesController,
            placeholder: 'Optional notes',
            prefix: const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Icon(CupertinoIcons.doc_text,
                  size: 20, color: CupertinoColors.systemGrey),
            ),
            maxLines: 2,
            style: const TextStyle(fontSize: 15),
          ),
        ),
        const SizedBox(height: 24),

        // ── Save Button ──
        CupertinoButton(
          color: CupertinoColors.systemBlue,
          borderRadius: BorderRadius.circular(14),
          padding: const EdgeInsets.symmetric(vertical: 16),
          onPressed: _isSaving ? null : _save,
          child: Text(
            isEditing ? 'Update Budget' : 'Create Budget',
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: CupertinoColors.white,
                letterSpacing: -0.1),
          ),
        ),
        const SizedBox(height: 24),

        // ── Info ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'After saving, you can add budget items (accounts with amounts) from the budget detail screen.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.tertiaryLabel
                    .resolveFrom(context),
                fontStyle: FontStyle.italic),
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