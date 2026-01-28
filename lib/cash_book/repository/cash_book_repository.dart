import 'package:cashledger/cash_book/model/cash_book_entry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EntryRepository {
  final SupabaseClient supabase;

  EntryRepository({SupabaseClient? client})
    : supabase = client ?? Supabase.instance.client;

  // Create
  Future<void> createEntry(EntryModel e) async {
    await supabase.from('entries').insert(e.toMap());
  }

  // Read with search & filters
  Future<List<EntryModel>> fetchEntries({
    String? search, // search in description/category
    String? accountId, // filter by account
    String? type, // 'debit' or 'credit'
    DateTime? from,
    DateTime? to,
    int? limit,
    int? offset,
  }) async {
    // start query - for supabase_flutter v2.10.3 select() then filter helpers
    var query = supabase.from('entries').select();

    if (search != null && search.isNotEmpty) {
      // search in description or category (use ilike)
      query = query
          .ilike('description', '%$search%')
          .or('category.ilike.%$search%');
      // Note: .or used on same builder; if it fails in your SDK, do separate filter OR client-side filter
    }

    if (accountId != null && accountId.isNotEmpty) {
      query = query.eq('account_id', accountId);
    }

    if (type != null && (type == 'debit' || type == 'credit')) {
      query = query.eq('type', type);
    }

    if (from != null) {
      query = query.gte('date', from.toIso8601String());
    }
    if (to != null) {
      query = query.lte('date', to.toIso8601String());
    }

    // if (limit != null) {
    //   final start = offset ?? 0;
    //   query = query.range(start, start + limit - 1);
    // }

    final res = await query.order('date', ascending: false);

    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map((m) => EntryModel.fromMap(m)).toList();
  }

  // Update
  Future<void> updateEntry(String id, EntryModel e) async {
    await supabase.from('entries').update(e.toMap()).eq('id', id);
  }

  // Delete
  Future<void> deleteEntry(String id) async {
    await supabase.from('entries').delete().eq('id', id);
  }
}
