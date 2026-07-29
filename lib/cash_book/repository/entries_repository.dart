import 'dart:developer';
import 'package:cashledger/cash_book/ui/widget/financial_yeaer_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final entriesRepositoryProvider = Provider(
  (ref) => EntriesRepository(ref: ref),
);

class EntriesRepository {
  final Ref ref;
  EntriesRepository({required this.ref});

  final _supabase = Supabase.instance.client;

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<List<Map<String, dynamic>>> fetchEntries() async {
    try {
      final yearPicked = ref.watch(yearProvider);

      var query = _supabase
          .from("entries")
          .select("*, accounts(name)")
          .gte('date', '$yearPicked-01-01')
          .lt('date', '${yearPicked + 1}-01-01')
          .order('date', ascending: false);

      final result = await query;
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> addEntry({
    required DateTime date,
    required double amount,
    required String type,
    String? description,
    required String accountId,
    required String subAccountId,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      await _supabase.from('entries').insert({
        'user_id': userId,
        'date': date.toIso8601String(),
        'amount': amount,
        'type': type,
        'description': description,
        'account_id': accountId,
      });
    } on PostgrestException catch (e) {
      log(e.message ?? "Error adding entry");
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> updateEntry(String id, Map<String, dynamic> data) async {
    try {
      await _supabase.from('entries').update(data).eq('id', id);
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> deleteEntry(String id) async {
    final result = await _supabase.from('entries').delete().eq('id', id);
    log(result.toString());
  }
}