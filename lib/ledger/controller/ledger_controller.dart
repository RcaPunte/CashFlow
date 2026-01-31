import 'package:cashledger/account/model/account_model.dart';
import 'package:cashledger/cash_book/ui/widget/financial_yeaer_selector.dart';
import 'package:cashledger/ledger/model/ledger_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final selectedLedgerFromYear = StateProvider<int>((ref) {
  return DateTime.now().year; // default selected year
});
final selectedLedgerToYear = StateProvider<int>((ref) {
  return DateTime.now().year; // default selected year
});

class LedgerControllerNotifier extends StateNotifier<AsyncValue<LedgerState>> {
  final Ref ref;

  LedgerControllerNotifier(this.ref) : super(const AsyncValue.loading()) {
    // Optional: auto-load current month
    final selectedFromYear = ref.watch(selectedLedgerFromYear);
    final selectedToYear = ref.watch(selectedLedgerToYear);
    final now = DateTime.now();
    fetchLedger(
      from: DateTime(selectedFromYear, now.month, 1),
      to: DateTime(selectedToYear, now.month + 1, 0),
    );
  }

  Future<void> fetchLedger({
    required DateTime from,
    required DateTime to,
    String? accountId,
  }) async {
    state = const AsyncValue.loading();

    try {
      final selectedFromYear = ref.watch(selectedLedgerFromYear);
      final selectedToYear = ref.watch(selectedLedgerToYear);
      final supabase = Supabase.instance.client;

      // ───── 1. Compute Opening Balance (before 'from' date) ─────
      double openingBalance = 0.0;

      var beforeQuery = supabase
          .from("entries")
          .select("amount, type")
          .lt(
            "date",
            DateTime(selectedFromYear, from.month, 1).toIso8601String(),
          );

      if (accountId != null && accountId.isNotEmpty) {
        beforeQuery = beforeQuery.eq("account_id", accountId);
      }

      final beforeData = await beforeQuery;
      for (var row in beforeData as List) {
        final amount = (row['amount'] as num).toDouble();
        if (row['type'] == 'debit') {
          openingBalance += amount;
        } else {
          openingBalance -= amount;
        }
      }

      // ───── 2. Fetch Entries in Range ─────
      var query = supabase
          .from("entries")
          .select('*, accounts(name)')
          .gte('date', from.toIso8601String())
          .lte('date', to.toIso8601String());
      //.order('date', ascending: true);

      if (accountId != null && accountId.isNotEmpty) {
        query = query.eq('account_id', accountId);
      }

      final res = await query;
      final entries = (res as List).map((e) => LedgerEntry.fromMap(e)).toList();

      // ───── 3. Update State ─────
      state = AsyncValue.data(
        LedgerState(entries: entries, openingBalance: openingBalance),
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// ───── New Model to Hold Both Entries + Opening Balance ─────
class LedgerState {
  final List<LedgerEntry> entries;
  final double openingBalance;

  const LedgerState({required this.entries, this.openingBalance = 0.0});
}

// ───── Updated Provider (Now Returns AsyncValue!) ─────
final ledgerControllerProvider =
    StateNotifierProvider<LedgerControllerNotifier, AsyncValue<LedgerState>>(
      (ref) => LedgerControllerNotifier(ref),
    );

// ───── Account List (unchanged, but cleaned) ─────
final accountListProvider = FutureProvider<List<AccountModel>>((ref) async {
  final supabase = Supabase.instance.client;
  final year = ref.watch(yearProvider);
  final res = await supabase
      .from('accounts')
      .select()
      .eq('year', year)
      .order('name', ascending: true);

  final rawAccount = (res as List).map((e) => AccountModel.fromMap(e)).toList();
  final accounts = (rawAccount).where((ac) => ac.parentId == null).toList();
  accounts.insert(
    0,
    AccountModel(id: "", name: "All Accounts", accountType: "Both"),
  );
  return accounts;
});
