import 'dart:developer';

import 'package:cashledger/account/controller/account_controller.dart';
import 'package:cashledger/account/model/account_model.dart';
import 'package:cashledger/auth/controller/auth_controller.dart';
import 'package:cashledger/cash_book/controller/cash_book_controller.dart';
import 'package:cashledger/cash_book/controller/cash_book_group_provider.dart';
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

  Color selectedColor = CupertinoColors.activeGreen;

  DateTime date = DateTime.now();
  String? selectedAccountId;

  String? selectedSubAccountId;
  String type = "receipt";

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
  ///
  Map<String?, List<AccountModel>> buildAccountTree(
    List<AccountModel> accounts,
  ) {
    final Map<String?, List<AccountModel>> tree = {};
    for (final acc in accounts) {
      tree.putIfAbsent(acc.parentId, () => []).add(acc);
    }
    return tree;
  }

  void _openAccountPicker(List<AccountModel> accounts) {
    final tree = buildAccountTree(accounts);
    final roots = tree[null] ?? [];

    int mainIndex = roots.indexWhere((a) => a.id == selectedAccountId);
    if (mainIndex < 0) mainIndex = 0;

    showCupertinoModalPopup(
      context: context,
      builder: (_) {
        AccountModel selectedMain = roots[mainIndex];

        return StatefulBuilder(
          builder: (context, setModalState) {
            final subAccounts = tree[selectedMain.id] ?? [];

            return Container(
              height: 360,
              color: CupertinoColors.systemBackground.resolveFrom(context),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    "Select Account",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  /// 🔹 MAIN ACCOUNT PICKER
                  SizedBox(
                    height: 120,
                    child: CupertinoPicker(
                      itemExtent: 32,
                      scrollController: FixedExtentScrollController(
                        initialItem: mainIndex,
                      ),
                      onSelectedItemChanged: (index) {
                        setModalState(() {
                          selectedMain = roots[index];
                        });
                      },
                      children: roots
                          .map((a) => Center(child: Text(a.name)))
                          .toList(),
                    ),
                  ),

                  /// 🔹 SUB ACCOUNT PICKER (ONLY IF EXISTS)
                  if (subAccounts.isNotEmpty) ...[
                    const Divider(height: 1),
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        "Sub Account",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 120,
                      child: CupertinoPicker(
                        itemExtent: 32,
                        onSelectedItemChanged: (index) {
                          setModalState(() {
                            selectedAccountId = subAccounts[index].id;
                            selectedSubAccountId = subAccounts[index].id;
                          });
                          // log(selectedSubAccountId.toString());
                          //   selectedAccountName = subAccounts[index].name;
                        },
                        children: subAccounts
                            .map((a) => Center(child: Text(a.name)))
                            .toList(),
                      ),
                    ),
                  ],

                  /// 🔹 DONE BUTTON
                  CupertinoButton(
                    child: const Text("Done"),
                    onPressed: () {
                      // If no sub account, use main account
                      if (subAccounts.isNotEmpty) {
                        selectedAccountId =
                            subAccounts[selectedMain.id == selectedMain.id
                                    ? 0
                                    : 1]
                                .id;
                        selectedSubAccountId = subAccounts
                            .firstWhere(
                              (a) => a.id == selectedSubAccountId,
                              orElse: () => AccountModel(
                                id: "",
                                name: 'Sub Account Missing',
                                year: DateTime.now().year,
                                parentId: null,
                                accountType: '',
                              ),
                            )
                            .id;
                        log(selectedSubAccountId.toString());
                      } else {
                        selectedAccountId = selectedMain.id;
                        selectedSubAccountId = null;
                      }
                      // selectedAccountId = selectedMain.id;
                      setState(() {});
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // void _openAccountPicker(List<AccountModel> accounts) {
  //   final sortedAccounts = buildAccountTree(accounts);
  //   final roots = sortedAccounts[null] ?? [];
  //   // Determine the initial index for the picker
  //   int initialIndex = roots.indexWhere((a) => a.id == selectedAccountId) ?? 0;
  //   if (initialIndex == -1) initialIndex = 0;

  //   showCupertinoModalPopup(
  //     context: context,
  //     builder: (_) => Container(
  //       height: 320, // Slightly taller container
  //       color: CupertinoColors.systemBackground.resolveFrom(context),
  //       child: Column(
  //         children: [
  //           Container(
  //             height: 44,
  //             alignment: Alignment.center,
  //             child: const Text(
  //               "Select Account",
  //               style: TextStyle(fontWeight: FontWeight.w600),
  //             ),
  //           ),
  //           SizedBox(
  //             height: 200,
  //             child: CupertinoPicker(
  //               itemExtent: 32,
  //               scrollController: FixedExtentScrollController(
  //                 initialItem: initialIndex,
  //               ),
  //               onSelectedItemChanged: (index) {
  //                 // Update state immediately, but only set when 'Done' or implicitly selected

  //                 selectedAccountId = roots[index].id;
  //               },
  //               children: roots
  //                   .map((a) => Center(child: Text(a.name)))
  //                   .toList(),
  //             ),
  //           ),
  //           // Explicit Done button to confirm selection (optional, but good practice)
  //           CupertinoButton(
  //             child: const Text("Done"),
  //             onPressed: () {
  //               // Ensure the last selected item is applied if they didn't scroll to it
  //               if (mounted) setState(() {});
  //               Navigator.pop(context);
  //             },
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  /// --------------------------
  /// DATE PICKER
  /// --------------------------

  // Helper function to check if the date is in the previous month or earlier
  bool _isPreviousMonthOrEarlier(DateTime selectedDate) {
    final now = DateTime.now();
    final firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);

    // Return true if the selected date is before the first day of the current month
    return selectedDate.isBefore(firstDayOfCurrentMonth);
  }

  // Function to show the confirmation dialog
  Future<bool> _showPreviousDateWarning(BuildContext context) async {
    return await showCupertinoDialog<bool>(
          context: context,
          builder: (BuildContext context) => CupertinoAlertDialog(
            title: const Text("Confirm Previous Entry Date"),
            content: const Text(
              "The selected date is from a previous month. Please confirm you wish to enter this transaction date. This is often used to prevent accidental backdating of cash transactions.",
            ),
            actions: <CupertinoDialogAction>[
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context, false); // User cancelled
                },
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () {
                  Navigator.pop(context, true); // User confirmed
                },
                child: const Text('Confirm Entry'),
              ),
            ],
          ),
        ) ??
        false; // Return false if dialog is dismissed
  }

  void _openDatePicker() {
    DateTime tempDate = date; // Temporary variable to hold changes

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            // Done Button (where the logic is applied)
            Container(
              height: 44,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () async {
                  // Changed to async

                  // 1. Check if the selected date is from a previous month
                  if (_isPreviousMonthOrEarlier(tempDate)) {
                    // 2. Show the warning dialog and await confirmation
                    final confirmed = await _showPreviousDateWarning(context);

                    if (confirmed) {
                      // 3a. If confirmed, update state and close the picker
                      setState(() => date = tempDate);
                      // Navigator.pop(ctx);
                    }
                    // 3b. If NOT confirmed, do nothing (keep date as is, but close picker)
                    // We still need to close the date picker modal here
                    // because the user interaction is complete.
                    Navigator.pop(ctx);
                  } else {
                    // 4. If date is current month/future (but constrained by maximumDate), update state immediately
                    setState(() => date = tempDate);
                    Navigator.pop(ctx);
                  }
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
                maximumDate:
                    DateTime.now(), // Keeps the constraint that you cannot select a future date
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

  String getSelectedAccountName({
    required List<AccountModel> accounts,
    required String? selectedAccountId,
    required String? selectedSubAccountId,
  }) {
    if (selectedAccountId == null) {
      return "Select Account";
    }

    // If sub-account selected → return parent name
    if (selectedSubAccountId != null) {
      final subAccount = accounts.firstWhere(
        (a) => a.id == selectedSubAccountId,
        orElse: () => AccountModel(
          id: '',
          name: 'Unknown Account',
          year: DateTime.now().year,
          parentId: null,
          accountType: '',
        ),
      );

      if (subAccount.parentId != null) {
        final parent = accounts.firstWhere(
          (a) => a.id == subAccount.parentId,
          orElse: () => AccountModel(
            id: '',
            name: 'Parent Account Missing',
            year: DateTime.now().year,
            parentId: null,
            accountType: '',
          ),
        );
        return parent.name;
      }
    }

    // Otherwise return selected main account
    return accounts
        .firstWhere(
          (a) => a.id == selectedAccountId,
          orElse: () => AccountModel(
            id: '',
            name: 'Unknown Account',
            year: DateTime.now().year,
            parentId: null,
            accountType: '',
          ),
        )
        .name;
  }

  refesh() {
    ref.refresh(entriesListProvider);
    ref.refresh(groupedEntriesProvider);
    ref.refresh(monthlyTotalsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsListProvider);
    final entriesNotifier = ref.read(entriesProvider);

    // Dynamic title
    final title = widget.entry == null ? "New Entry" : "Edit Entry";
    final user = ref.watch(currentUserProvider);
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
            final accounts =
                rawAccounts; // List<Map<String, dynamic>>.from(rawAccounts);

            final selectedAccountName = selectedAccountId == null
                ? "Select Account"
                : selectedSubAccountId != null
                ? getSelectedAccountName(
                    accounts: accounts,
                    selectedAccountId: selectedAccountId,
                    selectedSubAccountId: selectedSubAccountId,
                  )
                : accounts
                      .firstWhere(
                        (a) => a.id == selectedAccountId,
                        orElse: () => AccountModel(
                          id: "",
                          name: 'Account Missing',
                          year: DateTime.now().year,
                          parentId: null,
                          accountType: '',
                        ),
                      )
                      .name;
            final selectedSubAccountName =
                selectedSubAccountId == null || selectedSubAccountId == ""
                ? ""
                : accounts
                      .firstWhere(
                        (a) => a.id == selectedSubAccountId,
                        orElse: () => AccountModel(
                          id: "",
                          name: 'Sub Account Missing',
                          year: DateTime.now().year,
                          parentId: null,
                          accountType: '',
                        ),
                      )
                      .name;
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
                    CupertinoListTile(
                      title: const Text("Account"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            selectedSubAccountId == null
                                ? selectedAccountName
                                : "$selectedAccountName-$selectedSubAccountName",
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
                    // 3. ACCOUNT PICKER FIELD
                    // CupertinoListTile(
                    //   title: const Text("Account"),
                    //   trailing: Row(
                    //     mainAxisSize: MainAxisSize.min,
                    //     children: [
                    //       Text(
                    //         selectedAccountName,
                    //         style: TextStyle(
                    //           color: selectedAccountId == null
                    //               ? CupertinoColors.placeholderText
                    //               : CupertinoColors.label,
                    //         ),
                    //       ),
                    //       const Icon(
                    //         CupertinoIcons.right_chevron,
                    //         size: 18,
                    //         color: CupertinoColors.systemGrey,
                    //       ),
                    //     ],
                    //   ),
                    //   onTap: () => _openAccountPicker(accounts),
                    // ),

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
                      showCupertinoDialog(
                        context: context,
                        builder: (_) => CupertinoAlertDialog(
                          title: Text(
                            type.toUpperCase(),
                            style: TextStyle(
                              color: type == "receipt"
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          content: Column(
                            children: [
                              SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      "Amount",
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      "₹ $amount",
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      "Date",
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      DateFormat('MMM d, yyyy').format(date),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      "AC Head",
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      selectedAccountName,
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      "Description",
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      descCtrl.text,
                                      textAlign: TextAlign.right,
                                      maxLines: 5,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text(
                                "Cancel",
                                style: TextStyle(
                                  color: Color.fromARGB(255, 99, 99, 101),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),

                            CupertinoDialogAction(
                              child: Text(
                                "Confirm",
                                // widget.entry == null
                                //     ? "Save Entry"
                                //     : "Update Entry",
                              ),
                              onPressed: () async {
                                try {
                                  final entryData = {
                                    'date': date,
                                    'amount': amount,
                                    'type': type == 'receipt'
                                        ? 'debit'
                                        : 'credit', // Map back to DB type
                                    'description': descCtrl.text.trim(),
                                    'account_id': selectedAccountId!,
                                    'sub_account_id':
                                        selectedSubAccountId ?? '',
                                  };

                                  if (widget.entry == null) {
                                    await entriesNotifier.addEntry(entryData);
                                    refesh();
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
                                    refesh();
                                  }

                                  if (mounted) Navigator.pop(context);
                                  Navigator.pop(context);
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
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      );
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
