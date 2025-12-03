import 'package:cashledger/account/model/account_model.dart';
import 'package:cashledger/account/repository/account_repositry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountsListProvider = FutureProvider((ref) async {
  final supabase = Supabase.instance.client;
  //final user = supabase.auth.currentUser;
  // if (user == null) return [];

  final res = await supabase
      .from('accounts')
      .select()
      // .eq('user_id', user.id)
      .order('name');

  return List<Map<String, dynamic>>.from(res);
});

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
