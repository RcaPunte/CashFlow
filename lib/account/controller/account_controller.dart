import 'package:cashledger/account/model/account_model.dart';
import 'package:cashledger/account/repository/account_repositry.dart';
import 'package:cashledger/cash_book/ui/widget/financial_yeaer_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountsListProvider = FutureProvider<List<AccountModel>>((ref) async {
  try {
    final supabase = Supabase.instance.client;

    final year = ref.watch(yearProvider);

    final res = await supabase
        .from('accounts')
        .select()
        .eq('year', year);
    final accountList = (res as List)
        .map((e) => AccountModel.fromMap(e as Map<String, dynamic>))
        .toList();

    final sortedList = accountList;
    sortedList.sort((a, b) {
      if (a.parentId == null && b.parentId != null) {
        return -1; // a comes before b
      } else if (a.parentId != null && b.parentId == null) {
        return 1; // b comes before a
      } else {
        return a.name.compareTo(b.name); // sort by name
      }
    });
    return sortedList;
  } catch (e) {
    //throw Exception(e.toString());
    return <AccountModel>[];
  }
  // return List<Map<String, dynamic>>.from(res);
});
Map<String?, List<AccountModel>> buildAccountTree(List<AccountModel> accounts) {
  final Map<String?, List<AccountModel>> tree = {};
  for (final acc in accounts) {
    tree.putIfAbsent(acc.parentId, () => []).add(acc);
  }
  return tree;
}

class AccountController extends StateNotifier<AsyncValue<List<AccountModel>>> {
  AccountController(this.repo) : super(const AsyncValue.loading()) {
    loadAccounts();
  }

  final AccountRepository repo;

  Future<void> loadAccounts() async {
    state = const AsyncValue.loading();
    try {
      final accounts = await repo.fetchAccounts();
      state = AsyncValue.data(accounts);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> add(AccountModel acc) async {
    await repo.addAccount(acc);
    await loadAccounts();
  }

  Future<void> update(String id, AccountModel acc) async {
    await repo.updateAccount(id, acc);
    await loadAccounts();
  }

  Future<void> delete(String id) async {
    await repo.deleteAccount(id);
    await loadAccounts();
  }
}

/// Riverpod provider
final accountControllerProvider =
    StateNotifierProvider<AccountController, AsyncValue<List<AccountModel>>>(
      (ref) => AccountController(AccountRepository()),
    );
