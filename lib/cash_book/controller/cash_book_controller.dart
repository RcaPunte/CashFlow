import 'package:cashledger/cash_book/controller/cash_book_filter.dart';
import 'package:cashledger/cash_book/ui/widget/financial_yeaer_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClient = Supabase.instance.client;

final entriesListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final yearPicked = ref.watch(yearProvider);
  final filter = ref.watch(cashbookFilterProvider);

  final result = await supabaseClient
      .from("entries")
      .select("*, accounts(*)")
      .gte('date', '$yearPicked-01-01')
      .lt('date', '${yearPicked + 1}-01-01')
      .order('date', ascending: false);

  List<Map<String, dynamic>> entries = List<Map<String, dynamic>>.from(result);

  if (filter.type != "all") {
    entries = entries.where((e) => e['type'] == filter.type).toList();
  }

  if (filter.fromDate != null) {
    entries = entries.where((e) {
      final d = DateTime.parse(e['date']);
      return d.isAfter(filter.fromDate!) ||
          d.isAtSameMomentAs(filter.fromDate!);
    }).toList();
  }

  if (filter.toDate != null) {
    entries = entries.where((e) {
      final d = DateTime.parse(e['date']);
      return d.isBefore(filter.toDate!) || d.isAtSameMomentAs(filter.toDate!);
    }).toList();
  }

  if (filter.search.trim().isNotEmpty) {
    final q = filter.search.toLowerCase();
    entries = entries.where((e) {
      final desc = (e['description'] ?? "").toLowerCase();
      final amt = (e['amount'] ?? "").toString();
      return desc.contains(q) || amt.contains(q);
    }).toList();
  }

  entries.sort((a, b) {
    final da = DateTime.parse(a['date']);
    final db = DateTime.parse(b['date']);

    switch (filter.sort) {
      case "date_asc":
        return da.compareTo(db);
      case "date_desc":
        return db.compareTo(da);
      case "amount_asc":
        return (a['amount'] as num).compareTo(b['amount'] as num);
      case "amount_desc":
        return (b['amount'] as num).compareTo(a['amount'] as num);
      case "desc_asc":
        return (a['description'] ?? "").compareTo(b['description'] ?? "");
      case "desc_desc":
        return (b['description'] ?? "").compareTo(a['description'] ?? "");
    }
    return 0;
  });

  return entries;
});