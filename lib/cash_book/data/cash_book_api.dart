import '../../app/supabase_init.dart';

class CashBookApi {
  final _db = AppSupabase.client;

  Future<List<Map<String, dynamic>>> fetchCashBook() async {
    final res = await _db
        .from('cash_book')
        .select()
        .order('date', ascending: false);

    return res;
  }

  Future<void> addCashEntry(Map<String, dynamic> data) async {
    await _db.from('cash_book').insert(data);
  }
}
