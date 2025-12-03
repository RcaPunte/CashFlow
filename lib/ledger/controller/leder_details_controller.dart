import 'package:cashledger/ledger/model/ledger_entry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LedgerDetailController {
  final supabase = Supabase.instance.client;

  Future<LedgerEntry?> getEntry(String id) async {
    final res = await supabase
        .from('entries')
        .select('*, accounts(name)')
        .eq('id', id)
        .maybeSingle();

    if (res == null) return null;
    return LedgerEntry.fromMap(res);
  }

  Future<void> deleteEntry(String id) async {
    await supabase.from('entries').delete().eq('id', id);
  }
}
