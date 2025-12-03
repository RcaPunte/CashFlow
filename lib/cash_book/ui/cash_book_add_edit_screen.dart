import 'package:cashledger/account/controller/account_controller.dart';
import 'package:cashledger/cash_book/controller/cash_book_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AddEntryScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? entry;
  const AddEntryScreen({this.entry, super.key});

  @override
  ConsumerState<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends ConsumerState<AddEntryScreen> {
  final amountCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  DateTime date = DateTime.now();
  String? selectedAccountId;
  String type = "receipt";

  @override
  void initState() {
    super.initState();

    if (widget.entry != null) {
      amountCtrl.text = widget.entry!["amount"].toString();
      descCtrl.text = widget.entry!["description"] ?? "";
      selectedAccountId = widget.entry!["account_id"];

      // maps: receipt → debit, expense → credit
      type = widget.entry!["type"] == "debit" ? "receipt" : "expense";

      date = DateTime.parse(widget.entry!["date"]);
    }
  }

  /// --------------------------
  /// ACCOUNT PICKER
  /// --------------------------
  void _openAccountPicker(List<Map<String, dynamic>> accounts) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 260,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text("Select Account", style: TextStyle(fontSize: 18)),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 32,
                onSelectedItemChanged: (index) {
                  setState(() => selectedAccountId = accounts[index]['id']);
                },
                children: accounts
                    .map((a) => Center(child: Text(a['name'])))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// --------------------------
  /// DATE PICKER
  /// --------------------------
  void _openDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: date,
                maximumDate: DateTime.now(),
                onDateTimeChanged: (value) {
                  setState(() => date = value);
                },
              ),
            ),
            CupertinoButton(
              child: const Text("Done"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  onDelete(String id) {
    ref.read(entriesListProvider.notifier).deleteEntry(id);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsListProvider);
    final entriesNotifier = ref.read(entriesListProvider.notifier);

    return Material(
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(widget.entry == null ? "Add Entry" : "Edit Entry"),

          trailing: widget.entry != null
              ? IconButton(
                  onPressed: () {
                    showCupertinoDialog(
                      context: context,
                      builder: (_) => CupertinoAlertDialog(
                        title: Text("Delete Entry"),
                        content: Text(
                          "Are you sure you want to delete this item?",
                        ),
                        actions: [
                          CupertinoDialogAction(
                            child: Text("Cancel"),
                            onPressed: () => Navigator.pop(context),
                          ),
                          CupertinoDialogAction(
                            isDestructiveAction: true,
                            child: Text("Delete"),
                            onPressed: () {
                              Navigator.pop(context);
                              onDelete(widget.entry!['id']);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(
                    CupertinoIcons.delete,
                    size: 24,
                    color: Colors.red,
                  ),
                )
              : null,
        ),
        child: SafeArea(
          child: accountsAsync.when(
            loading: () => const Center(child: CupertinoActivityIndicator()),
            error: (_, __) =>
                const Center(child: Text("Error loading accounts")),
            data: (rawAccounts) {
              final accounts = List<Map<String, dynamic>>.from(rawAccounts);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  /// --------------------------
                  /// TYPE: RECEIPT / EXPENSE
                  /// --------------------------
                  CupertinoSegmentedControl(
                    padding: const EdgeInsets.all(0),
                    children: const {
                      "receipt": Text("Receipt"),
                      "expense": Text("Expense"),
                    },
                    groupValue: type,
                    onValueChanged: (v) => setState(() => type = v),
                  ),
                  const SizedBox(height: 16),

                  /// --------------------------
                  /// AMOUNT
                  /// --------------------------
                  CupertinoTextField(
                    controller: amountCtrl,
                    placeholder: "Amount",
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  /// --------------------------
                  /// DESCRIPTION
                  /// --------------------------
                  CupertinoTextField(
                    controller: descCtrl,
                    placeholder: "Description",
                  ),
                  const SizedBox(height: 16),

                  /// --------------------------
                  /// ACCOUNT PICKER
                  /// --------------------------
                  GestureDetector(
                    onTap: () => _openAccountPicker(accounts),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: CupertinoColors.separator),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        selectedAccountId == null
                            ? "Select Account"
                            : accounts.firstWhere(
                                (a) => a['id'] == selectedAccountId,
                              )['name'],
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// --------------------------
                  /// DATE PICKER FIELD
                  /// --------------------------
                  GestureDetector(
                    onTap: _openDatePicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: CupertinoColors.separator),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        DateFormat('MMM d, yyyy').format(date),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  /// --------------------------
                  /// SAVE BUTTON
                  /// --------------------------
                  CupertinoButton.filled(
                    child: Text(widget.entry == null ? "Save" : "Update"),
                    onPressed: () async {
                      if (selectedAccountId == null) {
                        showCupertinoDialog(
                          context: context,
                          builder: (_) => const CupertinoAlertDialog(
                            title: Text("Account Required"),
                            content: Text("Please choose an account"),
                          ),
                        );
                        return;
                      }

                      final amount = double.tryParse(amountCtrl.text);
                      if (amount == null) return;

                      try {
                        if (widget.entry == null) {
                          await entriesNotifier.addEntry({
                            'date': date,
                            'amount': amount,
                            'type': type,
                            'description': descCtrl.text,
                            'accountId': selectedAccountId!,
                          });
                        } else {
                          await entriesNotifier
                              .updateEntry(widget.entry!['id'], {
                                'date': date.toIso8601String(),
                                'amount': amount,
                                'type': type,
                                'description': descCtrl.text,
                                'account_id': selectedAccountId!,
                              });
                        }

                        Navigator.pop(context);
                      } catch (e) {
                        showCupertinoDialog(
                          context: context,
                          builder: (_) => CupertinoAlertDialog(
                            title: const Text("Error"),
                            content: Text(e.toString()),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text("OK"),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
