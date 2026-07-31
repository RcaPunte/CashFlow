import 'package:cashledger/account/controller/account_controller.dart'
    show accountsListProvider;
import 'package:cashledger/account/model/account_model.dart';
import 'package:cashledger/cash_book/ui/widget/financial_yeaer_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Raw per-account totals from entries (sub-accounts only)
final _rawAccountTotalsProvider =
    FutureProvider<Map<String, Map<String, double>>>((
  ref,
) async {
  final supabase = Supabase.instance.client;
  final year = ref.watch(yearProvider);

  final res = await supabase
      .from('entries')
      .select('account_id, amount, type')
      .gte('date', DateTime(year, 1, 1).toIso8601String())
      .lte('date', DateTime.now().toIso8601String());

  final totals = <String, Map<String, double>>{};

  for (final e in res) {
    final accId = e['account_id'] as String?;
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

/// Fetch total IN (debit) and OUT (credit) per account,
/// with parent accounts aggregating all children's totals.
/// from the start of the selected year to now
final accountTotalsProvider =
    FutureProvider<Map<String, Map<String, double>>>((
  ref,
) async {
  final rawTotals = await ref.watch(_rawAccountTotalsProvider.future);
  final accounts = await ref.watch(accountsListProvider.future);

  // Build parent → children map
  final Map<String, List<AccountModel>> childrenByParent = {};
  for (final acc in accounts) {
    final parentId = acc.parentId;
    if (parentId != null) {
      childrenByParent.putIfAbsent(parentId, () => []).add(acc);
    }
  }

  // Start with raw totals (for sub-accounts with direct entries)
  final aggregated = <String, Map<String, double>>{};
  for (final entry in rawTotals.entries) {
    aggregated[entry.key] = {
      'in': entry.value['in'] ?? 0,
      'out': entry.value['out'] ?? 0,
    };
  }

  /// Recursively sum children
  Map<String, double> sumChildren(String parentId) {
    double totalIn = 0;
    double totalOut = 0;

    final children = childrenByParent[parentId] ?? [];
    for (final child in children) {
      // Add child's own entries
      if (aggregated.containsKey(child.id)) {
        totalIn += aggregated[child.id]!['in']!;
        totalOut += aggregated[child.id]!['out']!;
      }
      // Recurse into grandchildren
      final grandchildTotals = sumChildren(child.id);
      totalIn += grandchildTotals['in']!;
      totalOut += grandchildTotals['out']!;
    }

    return {'in': totalIn, 'out': totalOut};
  }

  // Aggregate for all accounts that have children
  for (final acc in accounts) {
    if (childrenByParent.containsKey(acc.id)) {
      final childTotals = sumChildren(acc.id);
      aggregated.putIfAbsent(acc.id, () => {'in': 0.0, 'out': 0.0});
      aggregated[acc.id]!['in'] = childTotals['in']!;
      aggregated[acc.id]!['out'] = childTotals['out']!;
    }
  }

  // Ensure every account has at least zeroed totals
  for (final acc in accounts) {
    aggregated.putIfAbsent(acc.id, () => {'in': 0.0, 'out': 0.0});
  }

  return aggregated;
});

