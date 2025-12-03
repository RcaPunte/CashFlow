import 'package:cashledger/account/model/account_model.dart';
import 'package:cashledger/ledger/controller/ledget_controller.dart';
import 'package:cashledger/ledger/ui/widgets/ledger_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  String selectedAccountId = '';
  late DateTime from;
  late DateTime to;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    from = DateTime(now.year, now.month, 1);
    to = DateTime(now.year, now.month + 1, 0);
    _applyFilters();
  }

  void _applyFilters() {
    ref
        .read(ledgerControllerProvider.notifier)
        .fetchLedger(
          from: from,
          to: to,
          accountId: selectedAccountId.isEmpty ? null : selectedAccountId,
        );
  }

  void _showAccountPicker(BuildContext context, List<AccountModel> accounts) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 260,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: CupertinoPicker(
          itemExtent: 32,
          onSelectedItemChanged: (index) {
            setState(() => selectedAccountId = accounts[index].id);
            _applyFilters();
          },
          children: accounts.map((a) => Text(a.name)).toList(),
        ),
      ),
    );
  }

  Future<void> _pickDate({
    required DateTime initial,
    required ValueChanged<DateTime> onChanged,
  }) async {
    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) => SizedBox(
        height: 260,
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          initialDateTime: initial,
          onDateTimeChanged: onChanged,
        ),
      ),
    );
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerControllerProvider);
    final accountsAsync = ref.watch(accountListProvider);

    // Reset running balance each build
    double runningBalance = 0;

    return Material(
      child: CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text("Ledger")),
        child: SafeArea(
          child: Column(
            children: [
              // ---------------------------
              // FILTER BAR
              // ---------------------------
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // Account picker
                    Expanded(
                      child: accountsAsync.when(
                        data: (accounts) => CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Text(
                            selectedAccountId.isEmpty
                                ? 'All Accounts'
                                : accounts
                                      .firstWhere(
                                        (a) => a.id == selectedAccountId,
                                      )
                                      .name,
                            style: const TextStyle(fontSize: 15),
                          ),
                          onPressed: () =>
                              _showAccountPicker(context, accounts),
                        ),
                        loading: () => const CupertinoActivityIndicator(),
                        error: (_, __) =>
                            const Text("Error", style: TextStyle(fontSize: 14)),
                      ),
                    ),

                    // From date
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Column(
                        children: [
                          Text(
                            "From",
                            style: TextStyle(color: CupertinoColors.activeBlue),
                          ),
                          Text(
                            DateFormat('MMM d, yy').format(from),
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      onPressed: () => _pickDate(
                        initial: from,
                        onChanged: (d) => setState(() => from = d),
                      ),
                    ),

                    // To date
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Column(
                        children: [
                          Text(
                            "To",
                            style: TextStyle(color: CupertinoColors.activeBlue),
                          ),
                          Text(
                            DateFormat('MMM d, yy').format(to),
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      onPressed: () => _pickDate(
                        initial: to,
                        onChanged: (d) => setState(() => to = d),
                      ),
                    ),
                  ],
                ),
              ),

              // ---------------------------
              // TABLE HEADER
              // ---------------------------
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                color: CupertinoColors.systemGrey5,
                child: Row(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.14,
                      child: const Text(
                        'Date',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: const Text(
                        'Description',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.16,
                      child: const Text(
                        'Dr',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.16,
                      child: const Text(
                        'Cr',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.18,
                      child: const Text(
                        'Balance',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ---------------------------
              // LEDGER LIST
              // ---------------------------
              Expanded(
                child: ListView.builder(
                  itemCount: ledger.length,
                  itemBuilder: (context, index) {
                    final e = ledger[index];
                    if (e.type == 'debit') {
                      runningBalance += e.amount;
                    } else {
                      runningBalance -= e.amount;
                    }

                    return LedgerRowWidget(
                      entry: e,
                      runningBalance: runningBalance,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
