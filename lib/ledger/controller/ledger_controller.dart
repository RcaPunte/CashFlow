import 'package:cashledger/account/model/account_model.dart';
import 'package:cashledger/cash_book/ui/widget/financial_yeaer_selector.dart';
import 'package:cashledger/ledger/model/ledger_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final selectedLedgerFromYear = StateProvider<int>((ref) {
  return DateTime.now().year;
});
final selectedLedgerToYear = StateProvider<int>((ref) {
  return DateTime.now().year;
});

// ───── Params record for fetch ─────
class LedgerFetchParams {
  final DateTime from;
  final DateTime to;
  final String? accountId;
  const LedgerFetchParams({
    required this.from,
    required this.to,
    this.accountId,
  });
}

// ───── State ─────
class LedgerState {
  final List<LedgerEntry> entries;
  final double openingBalance;
  const LedgerState({required this.entries, this.openingBalance = 0.0});
}

// ───── AsyncNotifier (Riverpod 3) ─────
final ledgerControllerProvider =
    AsyncNotifierProvider<LedgerControllerNotifier, LedgerState>(
      LedgerControllerNotifier.new,
    );

class LedgerControllerNotifier extends AsyncNotifier<LedgerState> {
  @override
  Future<LedgerState> build() async {
    final now = DateTime.now();
    return _fetchLedger(
      from: DateTime(now.year, now.month, 1),
      to: DateTime(now.year, now.month + 1, 0),
    );
  }

  Future<void> fetchLedger({
    required DateTime from,
    required DateTime to,
    String? accountId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchLedger(from: from, to: to, accountId: accountId),
    );
  }

  Future<LedgerState> _fetchLedger({
    required DateTime from,
    required DateTime to,
    String? accountId,
  }) async {
    final supabase = Supabase.instance.client;

    const fromCol = 'date';
    final fromStr = from.toIso8601String();
    final toStr = to.toIso8601String();

    // ───── 1. Compute Opening Balance (before 'from' date) ─────
    double openingBalance = 0.0;
    var beforeQuery = supabase
        .from("entries")
        .select("amount, type")
        .lt(fromCol, fromStr);

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
        .gte(fromCol, fromStr)
        .lte(fromCol, toStr);

    if (accountId != null && accountId.isNotEmpty) {
      query = query.eq('account_id', accountId);
    }

    final res = await query;
    final entries = (res as List).map((e) => LedgerEntry.fromMap(e)).toList();

    return LedgerState(entries: entries, openingBalance: openingBalance);
  }
}

// ───── Account List ─────
final accountListProvider = FutureProvider<List<AccountModel>>((ref) async {
  final supabase = Supabase.instance.client;
  final year = ref.watch(yearProvider);

  final res = await supabase
      .from('accounts')
      .select()
      .eq('year', year)
      .order('name', ascending: true);
  final rawAccount = (res as List).map((e) => AccountModel.fromMap(e)).toList();
  final accounts = rawAccount.where((ac) => ac.parentId == null).toList();
  accounts.insert(
    0,
    AccountModel(id: "", name: "All Accounts", accountType: "Both", userId: ""),
  );
  return accounts;
});