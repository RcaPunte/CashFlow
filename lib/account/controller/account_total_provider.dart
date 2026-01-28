import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fetch total IN (debit) and OUT (credit) per account
final accountTotalsProvider = FutureProvider<Map<String, Map<String, double>>>((
  ref,
) async {
  final supabase = Supabase.instance.client;

  final res = await supabase
      .from('entries')
      .select('accounts(id), amount, type');

  final totals = <String, Map<String, double>>{};

  for (final e in res) {
    final accId = e['accounts']?['id'];
    if (accId == null) continue;

    totals.putIfAbsent(accId, () => {'in': 0.0, 'out': 0.0});

    final amt = (e['amount'] ?? 0).toDouble();
    if (e['type'] == 'debit') {
      totals[accId]!['in'] = totals[accId]!['in']! + amt;
    } else if (e['type'] == 'credit') {
      totals[accId]!['out'] = totals[accId]!['out']! + amt;
    }
  }

  return totals;
});
