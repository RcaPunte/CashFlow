import 'package:cashledger/account/model/account_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountRepository {
  final supabase = Supabase.instance.client;

  Future<List<AccountModel>> fetchAccounts() async {
    final resp = await supabase
        .from('accounts')
        .select()
        .order('created_at', ascending: false);

    return resp.map((e) => AccountModel.fromMap(e)).toList();
  }

  Future<void> addAccount(AccountModel acc) async {
    await supabase.from('accounts').insert(acc.toMap());
  }

  Future<void> updateAccount(String id, AccountModel acc) async {
    await supabase.from('accounts').update(acc.toMap()).eq('id', id);
  }

  Future<void> deleteAccount(String id) async {
    await supabase.from('accounts').delete().eq('id', id);
  }
}
