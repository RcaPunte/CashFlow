import 'package:cashledger/cash_book/ui/widget/financial_yeaer_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final yearOpeningBalanceProvider = FutureProvider<double>((ref) async {
  final year = ref.watch(yearProvider);
  final supabase = Supabase.instance.client;

  final res = await supabase
      .from('opening_balances')
      .select('amount')
      .eq('year', year)
      .maybeSingle();

  if (res == null) return 0.0;

  return (res['amount'] as num).toDouble();
});
