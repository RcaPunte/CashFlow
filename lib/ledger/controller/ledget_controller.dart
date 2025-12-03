import 'package:cashledger/account/model/account_model.dart';
import 'package:cashledger/ledger/model/ledger_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Ledger entries state
final ledgerControllerProvider =
    StateNotifierProvider<LedgerControllerNotifier, List<LedgerEntry>>(
      (ref) => LedgerControllerNotifier(ref),
    );

// Accounts list
final accountListProvider = FutureProvider<List<AccountModel>>((ref) async {
  final supabase = Supabase.instance.client;
  final res = await supabase
      .from('accounts')
      .select()
      .order('name', ascending: true);
  final ac = (res as List).map((e) => AccountModel.fromMap(e)).toList();
  ac.add(AccountModel(id: "", name: "All Account", accountType: "Both"));
  return ac;
});

class LedgerControllerNotifier extends StateNotifier<List<LedgerEntry>> {
  final Ref ref;
  double openingBalance = 0;

  LedgerControllerNotifier(this.ref) : super([]);

  Future<void> fetchLedger({
    required DateTime from,
    required DateTime to,
    String? accountId,
  }) async {
    final supabase = Supabase.instance.client;

    // --- Compute Opening Balance ---
    double opening = 0;
    var beforeQuery = supabase
        .from("entries")
        .select()
        .lt("date", from.toIso8601String());
    if (accountId != null && accountId.isNotEmpty) {
      beforeQuery = beforeQuery.eq("account_id", accountId);
    }
    final beforeData = await beforeQuery;

    for (var row in beforeData) {
      if (row['type'] == 'debit') {
        opening += (row['amount'] as num).toDouble();
      } else {
        opening -= (row['amount'] as num).toDouble();
      }
    }

    openingBalance = opening;

    // --- Ledger Entries within range ---
    var query = supabase
        .from("entries")
        .select('*, accounts(name)')
        .gte('date', from.toIso8601String())
        .lte('date', to.toIso8601String());
    // .order('date', ascending: true);

    if (accountId != null && accountId.isNotEmpty) {
      query = query.eq('account_id', accountId);
    }

    final res = await query;
    state = (res as List).map((e) => LedgerEntry.fromMap(e)).toList();
  }
}

// class LedgerController {
//   final supabase = Supabase.instance.client;
//   Future<List<LedgerEntry>> fetchFilteredLedger({
//     required DateTime from,
//     required DateTime to,
//     required String? accountId,
//   }) async {
//     List<LedgerEntry> data = [];

//     var query = supabase.from('ledger').select();
//     // .gte('date', from.toIso8601String())
//     // .lte('date', to.toIso8601String());

//     if (accountId != null && accountId.isNotEmpty) {
//       query = query.eq('account_id', accountId);
//     }

//     final result = await query; //.order('date', ascending: true);

//     data = result.map((e) => LedgerEntry.fromMap(e)).toList();

//     return data;
//   }

//   /// Fetch entries with filters
//   Future<List<LedgerEntry>> fetchLedger({
//     String? accountId,
//     DateTime? from,
//     DateTime? to,
//   }) async {
//     final query = supabase.from('entries').select('*, accounts(name)');
//     // .order('date');

//     if (accountId != null) {
//       query.eq('account_id', accountId);
//     }

//     if (from != null) {
//       query.gte('date', from.toIso8601String());
//     }

//     if (to != null) {
//       query.lte('date', to.toIso8601String());
//     }

//     final res = await query;

//     return List<Map<String, dynamic>>.from(
//       res,
//     ).map((m) => LedgerEntry.fromMap(m)).toList();
//   }

//   /// Opening balance = total credits - total debits BEFORE selected period
//   // Future<double> fetchOpeningBalance({
//   //   required String? accountId,
//   //   required DateTime from,
//   // }) async {
//   //   // final query = supabase.from('entries').select('amount, type');

//   //   // if (accountId != null) {
//   //   //   query.eq('account_id', accountId);
//   //   // }

//   //   // query.lt('date', from.toIso8601String());

//   //   // final res = await query;

//   //   // double balance = 0;

//   //   // for (var e in res) {
//   //   //   final amt = (e['amount'] as num).toDouble();
//   //   //   final type = e['type'];

//   //   //   if (type == 'credit') balance += amt;
//   //   //   if (type == 'debit') balance -= amt;
//   //   // }

//   //   return 0; // /balance;
//   // }

//   /// Export to CSV
//   Future<String> exportToCsv(List<LedgerEntry> entries) async {
//     final buffer = StringBuffer();
//     buffer.writeln("Date,Account,Description,Debit,Credit");

//     for (final e in entries) {
//       buffer.writeln(
//         "${e.date.toIso8601String()},"
//         "${e.accountName},"
//         "\"${e.description ?? ''}\","
//         "${e.type == 'debit' ? e.amount : ''},"
//         "${e.type == 'credit' ? e.amount : ''}",
//       );
//     }

//     return buffer.toString();
//   }
// }
