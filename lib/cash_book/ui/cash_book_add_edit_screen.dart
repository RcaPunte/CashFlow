import 'package:cashledger/account/controller/account_controller.dart';
import 'package:cashledger/account/model/account_model.dart';
import 'package:cashledger/cash_book/controller/cash_book_controller.dart';
import 'package:cashledger/cash_book/controller/cash_book_group_provider.dart';
import 'package:cashledger/cash_book/repository/entries_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

const double kTabletBreakpoint = 800.0;

class AddEntryScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? entry;
  const AddEntryScreen({this.entry, super.key});

  @override
  ConsumerState<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends ConsumerState<AddEntryScreen> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  Color _selectedColor = CupertinoColors.activeGreen;
  DateTime _date = DateTime.now();
  String? _selectedAccountId;
  String? _selectedSubAccountId;
  String _type = 'receipt';

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _amountCtrl.text = widget.entry!['amount'].toString();
      _descCtrl.text = widget.entry!['description'] ?? '';
      _selectedAccountId = widget.entry!['account_id'];
      _type = widget.entry!['type'] == 'debit' ? 'receipt' : 'expense';
      _selectedColor = _type == 'receipt'
          ? CupertinoColors.activeGreen
          : CupertinoColors.systemRed;
      _date = DateTime.parse(widget.entry!['date']);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _showMessage(String msg, {bool isError = false}) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(isError ? 'Error' : 'Success'),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Map<String?, List<AccountModel>> _buildAccountTree(List<AccountModel> accounts) {
    final tree = <String?, List<AccountModel>>{};
    for (final acc in accounts) {
      tree.putIfAbsent(acc.parentId, () => []).add(acc);
    }
    return tree;
  }

  void _openAccountPicker(List<AccountModel> accounts) {
    final tree = _buildAccountTree(accounts);
    final roots = tree[null] ?? [];

    int mainIdx = roots.indexWhere((a) => a.id == _selectedAccountId);
    if (mainIdx < 0) mainIdx = 0;

    showCupertinoModalPopup(
      context: context,
      builder: (_) {
        AccountModel selectedMain = roots[mainIdx];

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final children = tree[selectedMain.id] ?? [];
            return Container(
              height: 380,
              decoration: const BoxDecoration(
                color: CupertinoColors.systemBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                          const Text('Select Account',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: const Text('Done',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                            onPressed: () {
                              if (children.isNotEmpty) {
                                _selectedAccountId = _selectedSubAccountId ??
                                    children.first.id;
                              } else {
                                _selectedAccountId = selectedMain.id;
                                _selectedSubAccountId = null;
                              }
                              setState(() {});
                              Navigator.pop(context);
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
                      height: 130,
                      child: CupertinoPicker(
                        itemExtent: 36,
                        scrollController: FixedExtentScrollController(
                            initialItem: mainIdx),
                        onSelectedItemChanged: (i) {
                          setModalState(() => selectedMain = roots[i]);
                        },
                        children: roots
                            .map((a) => Center(
                                child: Text(a.name,
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w500))))
                            .toList(),
                      ),
                    ),
                    if (children.isNotEmpty) ...[
                      Container(
                          height: 1,
                          color: CupertinoColors.separator
                              .resolveFrom(context)),
                      const SizedBox(height: 8),
                      const Text('Sub Account',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      SizedBox(
                        height: 100,
                        child: CupertinoPicker(
                          itemExtent: 32,
                          onSelectedItemChanged: (i) {
                            setModalState(() {
                              _selectedSubAccountId = children[i].id;
                            });
                          },
                          children: children
                              .map((a) => Center(
                                  child: Text(a.name,
                                      style: const TextStyle(
                                          fontSize: 15))))
                              .toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _isPreviousMonthOrEarlier(DateTime d) {
    final now = DateTime.now();
    return d.isBefore(DateTime(now.year, now.month, 1));
  }

  Future<bool> _showPreviousDateWarning() async {
    return await showCupertinoDialog<bool>(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Confirm Previous Date'),
            content: const Text(
                'The selected date is from a previous period. Please confirm this is intentional.'),
            actions: [
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _openDatePicker() {
    DateTime tempDate = _date;

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 320,
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    const Text('Select Date',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Done',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      onPressed: () async {
                        if (_isPreviousMonthOrEarlier(tempDate)) {
                          final confirmed =
                              await _showPreviousDateWarning();
                          if (!confirmed) {
                            Navigator.pop(ctx);
                            return;
                          }
                        }
                        setState(() => _date = tempDate);
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ),
              Container(
                  height: 1,
                  color:
                      CupertinoColors.separator.resolveFrom(context)),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _date,
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (v) => tempDate = v,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmAndDelete(String id) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete Entry'),
        content: const Text(
            'Are you sure you want to permanently delete this entry?'),
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
                await ref.read(entriesRepositoryProvider).deleteEntry(id);
                refresh();
                if (mounted) Navigator.pop(context);
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

  void refresh() {
    ref.invalidate(entriesListProvider);
    ref.invalidate(groupedEntriesProvider);
    ref.invalidate(monthlyTotalsProvider);
  }

  String _getDisplayName(List<AccountModel> accounts) {
    if (_selectedAccountId == null) return 'Select Account';
    if (_selectedSubAccountId != null) {
      final sub = accounts.firstWhere(
        (a) => a.id == _selectedSubAccountId,
        orElse: () => AccountModel(
            id: '', name: 'Unknown', year: 0, parentId: null, accountType: '', userId: ''),
      );
      if (sub.parentId != null) {
        final parent = accounts.firstWhere(
          (a) => a.id == sub.parentId,
          orElse: () => AccountModel(
              id: '', name: 'Unknown', year: 0, parentId: null, accountType: '', userId: ''),
        );
        return '${parent.name} › ${sub.name}';
      }
      return sub.name;
    }
    return accounts
        .firstWhere(
          (a) => a.id == _selectedAccountId,
          orElse: () => AccountModel(
              id: '', name: 'Unknown', year: 0, parentId: null, accountType: '', userId: ''),
        )
        .name;
  }

  Future<void> _confirmAndSave() async {
    if (_selectedAccountId == null) {
      _showMessage('Please select an account.', isError: true);
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      _showMessage('Please enter a valid amount.', isError: true);
      return;
    }

    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final accountsAsync = ref.read(accountsListProvider);
    final displayName = _getDisplayName(accountsAsync.asData?.value ?? []);

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(_type.toUpperCase(),
            style: TextStyle(
                color: _type == 'receipt'
                    ? CupertinoColors.activeGreen
                    : CupertinoColors.systemRed,
                fontWeight: FontWeight.w700)),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _confirmRow('Amount', fmt.format(amount)),
              _confirmRow('Date', DateFormat('MMM d, yyyy').format(_date)),
              _confirmRow('Account', displayName),
              if (_descCtrl.text.isNotEmpty)
                _confirmRow('Description', _descCtrl.text),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final repo = ref.read(entriesRepositoryProvider);
    try {
      if (widget.entry == null) {
        await repo.addEntry(
          date: _date,
          amount: amount,
          type: _type == 'receipt' ? 'debit' : 'credit',
          description: _descCtrl.text.trim(),
          accountId: _selectedAccountId!,
          subAccountId: _selectedSubAccountId ?? '',
        );
      } else {
        await repo.updateEntry(widget.entry!['id'], {
          'date': _date.toIso8601String(),
          'amount': amount,
          'type': _type == 'receipt' ? 'debit' : 'credit',
          'description': _descCtrl.text.trim(),
          'account_id': _selectedAccountId!,
        });
      }
      refresh();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showMessage('Could not save: $e', isError: true);
    }
  }

  Widget _confirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsListProvider);
    final title = widget.entry == null ? 'New Entry' : 'Edit Entry';
    final isWide = MediaQuery.of(context).size.width >= kTabletBreakpoint;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFFFFFFFF).withValues(alpha: 0.96),
        middle: Text(title,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2)),
        trailing: widget.entry != null
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _confirmAndDelete(widget.entry!['id']),
                child: const Icon(CupertinoIcons.delete_solid,
                    color: CupertinoColors.systemRed, size: 22),
              )
            : null,
      ),
      child: accountsAsync.when(
        loading: () =>
            const Center(child: CupertinoActivityIndicator(radius: 18)),
        error: (_, __) =>
            const Center(child: Text('Error loading accounts')),
        data: (accounts) {
          final displayName = _getDisplayName(accounts);

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 560 : double.infinity,
                ),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                      isWide ? 0 : 12, 16, isWide ? 0 : 12, 40),
              children: [
                // ── Type Segmented Control ──
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
                  child: CupertinoSlidingSegmentedControl<String>(
                    groupValue: _type,
                    backgroundColor: CupertinoColors.systemBackground,
                    thumbColor: _selectedColor,
                    padding: const EdgeInsets.all(0),
                    onValueChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _type = v;
                          _selectedColor = v == 'receipt'
                              ? const Color(0xFF34C759)
                              : const Color(0xFFFF3B30);
                        });
                      }
                    },
                    children: {
                      'receipt': Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text('Receipt',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _type == 'receipt'
                                  ? CupertinoColors.white
                                  : const Color(0xFF34C759),
                            )),
                      ),
                      'expense': Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text('Expense',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _type == 'expense'
                                  ? CupertinoColors.white
                                  : const Color(0xFFFF3B30),
                            )),
                      ),
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // ── Amount ──
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
                    controller: _amountCtrl,
                    placeholder: '0.00',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Text('₹ ',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1C1C1E))),
                    ),
                    style: const TextStyle(fontSize: 17),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Account ──
                GestureDetector(
                  onTap: () => _openAccountPicker(accounts),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
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
                        const Icon(CupertinoIcons.folder,
                            size: 20, color: CupertinoColors.systemBlue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(displayName,
                              style: TextStyle(
                                fontSize: 15,
                                color: _selectedAccountId == null
                                    ? CupertinoColors.placeholderText
                                    : CupertinoColors.label,
                                fontWeight: FontWeight.w500,
                              )),
                        ),
                        const Icon(CupertinoIcons.chevron_right,
                            size: 16, color: CupertinoColors.systemGrey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Date ──
                GestureDetector(
                  onTap: _openDatePicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
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
                        const Icon(CupertinoIcons.calendar,
                            size: 20, color: CupertinoColors.systemBlue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            DateFormat('MMM d, yyyy').format(_date),
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        const Icon(CupertinoIcons.chevron_right,
                            size: 16, color: CupertinoColors.systemGrey),
                      ],
                    ),
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
                    controller: _descCtrl,
                    placeholder: 'Description (optional)',
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Icon(CupertinoIcons.doc_text,
                          size: 20, color: CupertinoColors.systemGrey),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Save Button ──
                CupertinoButton(
                  color: _selectedColor,
                  borderRadius: BorderRadius.circular(14),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16),
                  onPressed: _confirmAndSave,
                  child: Text(
                    widget.entry == null ? 'Save Entry' : 'Update Entry',
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: CupertinoColors.white,
                        letterSpacing: -0.1),
                  ),
                ),
              ],
            ),
                ),
              ),
            );
          },
      ),
    );
  }
}