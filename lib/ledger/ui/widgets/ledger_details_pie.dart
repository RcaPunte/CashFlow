import 'package:cashledger/ledger/model/ledger_entry.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show
        CircularProgressIndicator; // Keep for the loading indicator if no Cupertino alternative is available/preferred
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// Assuming LedgerEntry model structure is available (id, accountName, date, type, amount, description).

class LedgerDetailPage extends StatefulWidget {
  final String entryId;
  const LedgerDetailPage({required this.entryId, super.key});

  @override
  State<LedgerDetailPage> createState() => _LedgerDetailPageState();
}

class _LedgerDetailPageState extends State<LedgerDetailPage> {
  LedgerEntry? entry;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final supabase = Supabase.instance.client;

    try {
      final res = await supabase
          .from('entries')
          .select('account_id, *, accounts(name)')
          .eq('id', widget.entryId)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        if (res != null) {
          entry = LedgerEntry.fromMap(Map<String, dynamic>.from(res));
        }
        loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        // Optional: show a CupertinoAlertDialog on error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator(radius: 18)),
      );
    }

    if (entry == null) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('Detail')),
        child: Center(
          child: Text(
            'Ledger entry not found',
            style: TextStyle(color: CupertinoColors.systemGrey),
          ),
        ),
      );
    }

    final isDebit = entry!.type == 'debit';
    final amountColor = isDebit
        ? CupertinoColors.activeGreen.resolveFrom(context)
        : CupertinoColors.systemRed.resolveFrom(context);
    final dateFormatter = DateFormat('EEE, MMM d, yyyy');

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Entry Detail"),
        // Add a trailing button for editing or other actions
        trailing: Icon(CupertinoIcons.ellipsis_circle),
      ),
      // Use systemGroupedBackground for the standard iOS detail page background
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Amount and Type Summary (Header Area)
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 20, left: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDebit ? "Receipt (Debit)" : "Expense (Credit)",
                      style: TextStyle(
                        fontSize: 16,
                        color: amountColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "₹${NumberFormat('#,##0.00').format(entry!.amount)}",
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: amountColor,
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Main Details Section (Grouped List)
              CupertinoListSection.insetGrouped(
                header: const Text('TRANSACTION DETAILS'),
                children: [
                  // Account Name
                  CupertinoListTile(
                    title: const Text('Account'),
                    leading: const Icon(CupertinoIcons.bag_fill),
                    trailing: Text(
                      entry!.accountName ?? "Unknown",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),

                  // Date
                  CupertinoListTile(
                    title: const Text('Date'),
                    leading: const Icon(CupertinoIcons.calendar),
                    trailing: Text(
                      dateFormatter.format(
                        DateTime.parse(entry!.date.toString()),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),

                  // ID (Optional for reference)
                  CupertinoListTile(
                    title: const Text('Entry ID'),
                    leading: const Icon(CupertinoIcons.number),
                    trailing: Text(
                      entry!.id,
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),

              // 3. Description Section (Grouped List)
              CupertinoListSection.insetGrouped(
                header: const Text('DESCRIPTION'),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Text(
                      entry!.description?.trim().isEmpty == true
                          ? "No description provided."
                          : entry!.description!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.label,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
