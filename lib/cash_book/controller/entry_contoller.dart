import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final entriesControllerProvider = Provider((ref) => EntriesController());

class EntriesController {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchEntries() async {
    // final user = supabase.auth.currentUser;
    // if (user == null) return [];
    final res = await supabase
        .from('entries')
        .select('*, accounts(name)')
        // .eq('user_id', user.id)
        .order('date', ascending: true);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> addEntry({
    required DateTime date,
    required double amount,
    required String type, // receipt/expense
    String? description,
    required String accountId,
  }) async {
    // final user = supabase.auth.currentUser;
    // if (user == null) return;

    try {
      final dbType = type == "receipt" ? "debit" : "credit";

      await supabase.from('entries').insert({
        // 'user_id': user.id,
        'date': date.toIso8601String(),
        'amount': amount,
        'type': dbType,
        'description': description,
        'account_id': accountId,
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
    }
  }

  Future<void> updateEntry(String id, Map<String, dynamic> data) async {
    if (data.containsKey('type')) {
      data['type'] = data['type'] == "receipt" ? "debit" : "credit";
    }
    await supabase.from('entries').update(data).eq('id', id);
  }

  Future<void> deleteEntry(String id) async {
    final result = await supabase.from('entries').delete().eq('id', id);
    log(result.toString());
  }
}
