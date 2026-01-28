import 'dart:developer';

import 'package:cashledger/cash_book/ui/widget/financial_yeaer_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final entriesRepositoryProvider = Provider(
  (ref) => EntriesRepository(ref: ref),
);

class EntriesRepository {
  final Ref ref;
  EntriesRepository({required this.ref});
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchEntries() async {
    // final user = supabase.auth.currentUser;
    // if (user == null) return [];
    try {
      final yearPicked = ref.watch(yearProvider);
      // final res = await supabase
      //     .from('entries')
      //     .select('*, accounts(name)')
      //     // .eq('user_id', user.id)
      //     .order('date', ascending: true);

      final result = await supabase
          .from("entries")
          .select("*, accounts(name)")
          .gte('date', '$yearPicked-01-01')
          .lt('date', '${yearPicked + 1}-01-01')
          .order('date', ascending: false);

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> addEntry({
    required DateTime date,
    required double amount,
    required String type, // receipt/expense
    String? description,
    required String accountId,
    required String subAccountId,
  }) async {
    // final user = supabase.auth.currentUser;
    // if (user == null) return;

    try {
      // final dbType = type == "receipt" ? "debit" : "credit";

      await supabase.from('entries').insert({
        // 'user_id': user.id,
        'user_id': supabase.auth.currentUser?.id,
        'date': date.toIso8601String(),
        'amount': amount,
        'type': type,
        'description': description,
        'account_id': accountId,
        // 'sub_account_id': subAccountId,
      });
    } on PostgrestException catch (e) {
      //  supabase.from('accounts').select().eq('id', accountId).single();
      log(e.message ?? "Error adding entry");
      // showCupertinoDialog(
      //   context: context,
      //   builder: (_) => CupertinoAlertDialog(
      //     title: Text("Budget Limit Exceeded"),
      //     content: Text(e.message ?? "You cannot add this entry."),
      //     actions: [
      //       CupertinoDialogAction(
      //         child: Text("OK"),
      //         onPressed: () => Navigator.pop(context),
      //       ),
      //     ],
      //   ),
      // );
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> updateEntry(String id, Map<String, dynamic> data) async {
    try {
      // if (data.containsKey('type')) {
      //   data['type'] = data['type'] == "receipt" ? "debit" : "credit";
      // }
      await supabase.from('entries').update(data).eq('id', id);
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> deleteEntry(String id) async {
    final result = await supabase.from('entries').delete().eq('id', id);
    log(result.toString());
  }
}
