import 'package:cashledger/account/controller/account_controller.dart';
import 'package:cashledger/cash_book/controller/cash_book_controller.dart';
import 'package:cashledger/cash_book/repository/entries_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Used for Colors.green/red in initState
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

  // Use CupertinoColors for consistency
  Color selectedColor = CupertinoColors.activeGreen;

  DateTime date = DateTime.now();
  String? selectedAccountId;
  String type = "receipt"; // receipt (debit) or expense (credit)

  @override
  void initState() {
    super.initState();

    if (widget.entry != null) {
      amountCtrl.text = widget.entry!["amount"].toString();
      descCtrl.text = widget.entry!["description"] ?? "";
      selectedAccountId = widget.entry!["account_id"];

      // maps: debit -> receipt, credit -> expense
      type = widget.entry!["type"] == "debit" ? "receipt" : "expense";
      selectedColor = type == "receipt"
          ? CupertinoColors.activeGreen
          : CupertinoColors.systemRed;

      // Ensure date is parsed correctly from the ISO string
      date = DateTime.parse(widget.entry!["date"]);
    }
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  /// --------------------------
  /// ACCOUNT PICKER
  /// --------------------------
  void _openAccountPicker(List<Map<String, dynamic>> accounts) {
    // Determine the initial index for the picker
    int initialIndex = accounts.indexWhere((a) => a['id'] == selectedAccountId);
    if (initialIndex == -1) initialIndex = 0;

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 320, // Slightly taller container
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Container(
              height: 44,
              alignment: Alignment.center,
              child: const Text(
                "Select Account",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(
              height: 200,
              child: CupertinoPicker(
                itemExtent: 32,
                scrollController: FixedExtentScrollController(
                  initialItem: initialIndex,
                ),
                onSelectedItemChanged: (index) {
                  // Update state immediately, but only set when 'Done' or implicitly selected
                  selectedAccountId = accounts[index]['id'];
                },
                children: accounts
                    .map((a) => Center(child: Text(a['name'])))
                    .toList(),
              ),
            ),
            // Explicit Done button to confirm selection (optional, but good practice)
            CupertinoButton(
              child: const Text("Done"),
              onPressed: () {
                // Ensure the last selected item is applied if they didn't scroll to it
                if (mounted) setState(() {});
                Navigator.pop(context);
              },
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
    DateTime tempDate = date; // Temporary variable to hold changes

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            // Done Button
            Container(
              height: 44,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() => date = tempDate);
                  Navigator.pop(ctx);
                },
                child: const Text(
                  "Done",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(
              height: 256,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: date,
                maximumDate: DateTime.now(),
                onDateTimeChanged: (value) {
                  tempDate = value;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// --------------------------
  /// DELETE ACTION
  /// --------------------------
  void _confirmAndDelete(String id) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text("Delete Entry"),
        content: const Text(
          "Are you sure you want to permanently delete this entry?",
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("Delete"),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await ref.read(entriesRepositoryProvider).deleteEntry(id);
              if (mounted) {
                Navigator.pop(context); // Close Add/Edit screen
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsListProvider);
    final entriesNotifier = ref.read(entriesProvider);

    // Dynamic title
    final title = widget.entry == null ? "New Entry" : "Edit Entry";

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(title),
        trailing: widget.entry != null
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _confirmAndDelete(widget.entry!['id']),
                child: const Icon(
                  CupertinoIcons.delete_solid,
                  color: CupertinoColors.systemRed,
                ),
              )
            : null,
      ),
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: accountsAsync.when(
          loading: () =>
              const Center(child: CupertinoActivityIndicator(radius: 18)),
          error: (_, __) => const Center(child: Text("Error loading accounts")),
          data: (rawAccounts) {
            final accounts = List<Map<String, dynamic>>.from(rawAccounts);
            final selectedAccountName = selectedAccountId == null
                ? "Select Account"
                : accounts.firstWhere(
                    (a) => a['id'] == selectedAccountId,
                    orElse: () => {'name': 'Account Missing'},
                  )['name'];

            return ListView(
              padding: const EdgeInsets.only(top: 20, bottom: 40),
              children: [
                /// --------------------------
                /// TYPE: RECEIPT / EXPENSE
                /// --------------------------
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: CupertinoSegmentedControl<String>(
                    padding: const EdgeInsets.all(0),
                    selectedColor: selectedColor,
                    borderColor: selectedColor,
                    // Ensure text colors resolve correctly against the background
                    children: {
                      "receipt": Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          "Receipt",
                          style: TextStyle(
                            color: type == "receipt"
                                ? CupertinoColors.white
                                : CupertinoColors.activeGreen,
                          ),
                        ),
                      ),
                      "expense": Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          "Expense",
                          style: TextStyle(
                            color: type == "expense"
                                ? CupertinoColors.white
                                : CupertinoColors.systemRed,
                          ),
                        ),
                      ),
                    },
                    groupValue: type,
                    onValueChanged: (v) {
                      setState(() {
                        type = v;
                        selectedColor = v == "receipt"
                            ? CupertinoColors.activeGreen
                            : CupertinoColors.systemRed;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),

                /// --------------------------
                /// MAIN FORM FIELDS (Grouped List)
                /// --------------------------
                CupertinoListSection.insetGrouped(
                  // 1. AMOUNT FIELD
                  children: [
                    CupertinoTextFormFieldRow(
                      controller: amountCtrl,
                      placeholder: "Amount",
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      prefix: const Text(
                        "Amount",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      validator: (value) {
                        if (double.tryParse(value ?? '') == null) {
                          return 'Enter a valid number.';
                        }
                        return null;
                      },
                    ),

                    // 2. DESCRIPTION FIELD
                    CupertinoTextFormFieldRow(
                      controller: descCtrl,
                      placeholder: "Details or purpose",
                      prefix: const Text(
                        "Description",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),

                    // 3. ACCOUNT PICKER FIELD
                    CupertinoListTile(
                      title: const Text("Account"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            selectedAccountName,
                            style: TextStyle(
                              color: selectedAccountId == null
                                  ? CupertinoColors.placeholderText
                                  : CupertinoColors.label,
                            ),
                          ),
                          const Icon(
                            CupertinoIcons.right_chevron,
                            size: 18,
                            color: CupertinoColors.systemGrey,
                          ),
                        ],
                      ),
                      onTap: () => _openAccountPicker(accounts),
                    ),

                    // 4. DATE PICKER FIELD
                    CupertinoListTile(
                      title: const Text("Date"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('MMM d, yyyy').format(date),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const Icon(
                            CupertinoIcons.right_chevron,
                            size: 18,
                            color: CupertinoColors.systemGrey,
                          ),
                        ],
                      ),
                      onTap: _openDatePicker,
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                /// --------------------------
                /// SAVE BUTTON
                /// --------------------------
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: CupertinoButton.filled(
                    // Use dynamic color based on type
                    color: selectedColor,
                    child: Text(
                      widget.entry == null ? "Save Entry" : "Update Entry",
                    ),
                    onPressed: () async {
                      if (selectedAccountId == null) {
                        showCupertinoDialog(
                          context: context,
                          builder: (_) => CupertinoAlertDialog(
                            title: Text("Account Required"),
                            content: Text(
                              "Please choose an account before saving.",
                            ),
                            actions: [
                              CupertinoDialogAction(
                                child: Text("OK"),
                                onPressed: () => Navigator.pop(
                                  context,
                                ), // FIX: Use an anonymous function
                              ),
                            ],
                          ),
                        );
                        return;
                      }

                      final amount = double.tryParse(amountCtrl.text.trim());
                      if (amount == null || amount <= 0) {
                        showCupertinoDialog(
                          context: context,
                          builder: (_) => CupertinoAlertDialog(
                            title: Text("Invalid Amount"),
                            content: Text(
                              "Please enter a valid amount greater than zero.",
                            ),
                            actions: [
                              CupertinoDialogAction(
                                child: Text("OK"),
                                onPressed: () => Navigator.pop(
                                  context,
                                ), // FIX: Use an anonymous function
                              ),
                            ],
                          ),
                        );
                        return;
                      }

                      try {
                        final entryData = {
                          'date': date,
                          'amount': amount,
                          'type': type == 'receipt'
                              ? 'debit'
                              : 'credit', // Map back to DB type
                          'description': descCtrl.text.trim(),
                          'account_id': selectedAccountId!,
                        };

                        if (widget.entry == null) {
                          await entriesNotifier.addEntry(entryData);
                        } else {
                          await entriesNotifier.updateEntry(
                            widget.entry!['id'],
                            {
                              'date': date.toIso8601String(),
                              'amount': amount,
                              'type': type == 'receipt'
                                  ? 'debit'
                                  : 'credit', // Map back to DB type
                              'description': descCtrl.text.trim(),
                              'account_id': selectedAccountId!,
                            },
                          );
                        }

                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        if (mounted) {
                          showCupertinoDialog(
                            context: context,
                            builder: (_) => CupertinoAlertDialog(
                              title: const Text("Operation Failed"),
                              content: Text(
                                "Could not save entry. Error: ${e.toString()}",
                              ),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text("OK"),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
