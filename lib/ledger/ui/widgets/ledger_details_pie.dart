import 'package:cashledger/ledger/model/ledger_entry.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Your LedgerEntry model should contain: id, accountName, date, type, amount, description.
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (entry == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Ledger entry not found',
            style: theme.textTheme.titleMedium,
          ),
        ),
      );
    }

    final isDebit = entry!.type == 'debit';
    final amountColor = isDebit ? Colors.green[700] : Colors.red[700];
    final cardColor = theme.colorScheme.surface;
    final shadowColor = Colors.black.withOpacity(0.08);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ledger Detail"),
        elevation: 1,
        backgroundColor: theme.colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                offset: const Offset(0, 3),
                color: shadowColor,
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ACCOUNT NAME
              Text(
                entry!.accountName ?? "Unknown Account",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // DATE
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    entry!.date.toIso8601String().split('T')[0],
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // TYPE
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDebit
                      ? Colors.green.withOpacity(0.15)
                      : Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isDebit ? "Receipt (Debit)" : "Expense (Credit)",
                  style: TextStyle(
                    fontSize: 14,
                    color: amountColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // AMOUNT
              Text(
                "₹${entry!.amount.toStringAsFixed(2)}",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),

              const Divider(height: 32),

              // DESCRIPTION
              Text(
                "Description",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                entry!.description?.trim().isEmpty == true
                    ? "No description"
                    : entry!.description!,
                style: theme.textTheme.bodyLarge,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// Example LedgerEntry model
// --------------------------------------------------
// class LedgerEntry {
//   final String id;
//   final String accountName;
//   final DateTime date;
//   final String type;
//   final double amount;
//   final String? description;

//   LedgerEntry({
//     required this.id,
//     required this.accountName,
//     required this.date,
//     required this.type,
//     required this.amount,
//     this.description,
//   });

//   factory LedgerEntry.fromMap(Map<String, dynamic> map) {
//     return LedgerEntry(
//       id: map['id'].toString(),
//       accountName: map['accounts']['name'] ?? 'Unknown',
//       date: DateTime.parse(map['date']),
//       type: map['type'],
//       amount: double.tryParse(map['amount'].toString()) ?? 0,
//       description: map['description'],
//     );
//   }
// }
