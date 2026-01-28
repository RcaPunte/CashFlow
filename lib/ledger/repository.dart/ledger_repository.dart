import 'package:cashledger/ledger/model/ledger_entry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LedgerRepository {
  final supabase = Supabase.instance.client;

  /// Fetch entries for optional account + date range.
  /// We select account_id and nested accounts(name) so models have accountName.
  Future<List<LedgerEntry>> fetchEntries({
    String? accountId,
    DateTime? from,
    DateTime? to,
  }) async {
    var query = supabase
        .from('entries')
        .select('account_id, *, accounts(name)');
    //  .order('date', ascending: true);

    if (accountId != null && accountId.isNotEmpty) {
      query = query.eq('account_id', accountId);
    }
    if (from != null) {
      query = query.gte('date', from.toIso8601String());
    }
    if (to != null) {
      query = query.lte('date', to.toIso8601String());
    }

    final res = await query;
    final rows = List<Map<String, dynamic>>.from(res);
    return rows.map((r) => LedgerEntry.fromMap(r)).toList();
  }

  /// Compute opening balance (sum of debits - credits) before `fromDate` for an account
  Future<double> computeOpeningBalance(
    String accountId,
    DateTime fromDate,
  ) async {
    // Sum debits
    final debitRes = await supabase
        .from('entries')
        .select('sum(amount)')
        .eq('account_id', accountId)
        .eq('type', 'debit')
        .lt('date', fromDate.toIso8601String());

    final creditRes = await supabase
        .from('entries')
        .select('sum(amount)')
        .eq('account_id', accountId)
        .eq('type', 'credit')
        .lt('date', fromDate.toIso8601String());

    double debits = 0;
    double credits = 0;

    if ((debitRes as List).isNotEmpty) {
      final v = (debitRes as List).first;
      debits = (v['sum'] ?? 0) is num ? (v['sum'] ?? 0).toDouble() : 0;
    }

    if ((creditRes as List).isNotEmpty) {
      final v = (creditRes as List).first;
      credits = (v['sum'] ?? 0) is num ? (v['sum'] ?? 0).toDouble() : 0;
    }

    // Opening balance = debits - credits (debit positive)
    return debits - credits;
  }

  Future<List<Map<String, dynamic>>> fetchAccounts() async {
    final res = await supabase.from('accounts').select().order('name');
    return List<Map<String, dynamic>>.from(res);
  }
}
