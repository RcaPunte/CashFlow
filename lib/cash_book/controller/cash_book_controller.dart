import 'package:cashledger/cash_book/controller/entry_contoller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class EntriesNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  EntriesNotifier(this._controller) : super(const AsyncValue.loading()) {
    fetchEntries();
  }

  final EntriesController _controller;

  Future<void> fetchEntries() async {
    try {
      final entries = await _controller.fetchEntries();
      state = AsyncValue.data(entries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Calculate total for an account within its period
  Future<double> getAccountTotal(String accountId, String limitPeriod) async {
    final now = DateTime.now();
    DateTime start;

    if (limitPeriod == "monthly") {
      start = DateTime(now.year, now.month, 1);
    } else if (limitPeriod == "yearly") {
      start = DateTime(now.year, 1, 1);
    } else {
      start = DateTime(2000);
    }

    final res = await _controller.supabase
        .from('entries')
        .select('amount')
        .eq('account_id', accountId)
        .gte('date', start.toIso8601String());

    final list = List<Map<String, dynamic>>.from(res);
    double total = 0;
    for (var e in list) {
      total += (e['amount'] ?? 0);
    }
    return total;
  }

  // Add entry with account limit check
  Future<bool> addEntryWithLimit({
    required DateTime date,
    required double amount,
    required String type,
    String? description,
    required String accountId,
  }) async {
    // fetch account info
    final accRes = await _controller.supabase
        .from('accounts')
        .select()
        .eq('id', accountId)
        .single();
    final acc = Map<String, dynamic>.from(accRes);
    final limitAmount = acc['limit_amount'];
    final limitPeriod = acc['limit_period'] ?? "monthly";

    bool exceeded = false;
    if (limitAmount != null) {
      final total = await getAccountTotal(accountId, limitPeriod);
      if (total + amount > limitAmount) exceeded = true;
    }

    // Add entry to DB
    await _controller.addEntry(
      date: date,
      amount: amount,
      type: type,
      description: description,
      accountId: accountId,
    );

    await fetchEntries(); // refresh list
    return exceeded; // return if limit was exceeded
  }

  Future<void> addEntry(Map<String, dynamic> data) async {
    await _controller.addEntry(
      date: data['date'],
      amount: data['amount'],
      type: data['type'],
      description: data['description'],
      accountId: data['accountId'],
    );
    await fetchEntries();
  }

  Future<void> updateEntry(String id, Map<String, dynamic> data) async {
    await _controller.updateEntry(id, data);
    await fetchEntries();
  }

  Future<void> deleteEntry(String id) async {
    await _controller.deleteEntry(id);
    await fetchEntries();
  }

  double get totalReceipts =>
      state
          .whenData(
            (list) => list
                .where((e) => e['type'] == "debit")
                .fold<double>(0, (sum, e) => sum + (e['amount'] ?? 0)),
          )
          .value ??
      0;

  double get totalExpenses =>
      state
          .whenData(
            (list) => list
                .where((e) => e['type'] == "credit")
                .fold<double>(0, (sum, e) => sum + (e['amount'] ?? 0)),
          )
          .value ??
      0;
}

final entriesControllerProvider = Provider((ref) => EntriesController());
final entriesListProvider =
    StateNotifierProvider<
      EntriesNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) => EntriesNotifier(ref.watch(entriesControllerProvider)));

// final entriesListProvider = FutureProvider.autoDispose((ref) async {
//   final controller = ref.watch(entriesControllerProvider);
//   return controller.fetchEntries();
// });
// final entriesControllerProvider =
//     StateNotifierProvider<
//       EntriesNotifier,
//       AsyncValue<List<Map<String, dynamic>>>
//     >((ref) {
//       // final controller = ref.watch(entriesControllerProvider);
//       return EntriesNotifier(ref);
//     });

// class EntriesNotifier
//     extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
//   final Ref ref;
//   EntriesNotifier(this.ref) : super(const AsyncValue.loading()) {
//     fetchEntries();
//   }

//   final supabase = Supabase.instance.client;

//   Future<List<Map<String, dynamic>>> fetchEntries({
//     String? search,
//     String? accountId,
//     DateTime? fromDate,
//     DateTime? toDate,
//   }) async {
//     // final user = supabase.auth.currentUser;
//     // if (user == null) throw Exception("Not logged in");

//     var query = supabase.from('entries').select('*, accounts(name)');
//     //.eq('user_id', user.id);

//     if (search != null && search.isNotEmpty) {
//       query = query.ilike('description', '%$search%');
//     }

//     if (accountId != null && accountId.isNotEmpty) {
//       query = query.eq('account_id', accountId);
//     }

//     if (fromDate != null) query = query.gte('date', fromDate.toIso8601String());
//     if (toDate != null) query = query.lte('date', toDate.toIso8601String());

//     final res = await query.order('date', ascending: false);
//     return List<Map<String, dynamic>>.from(res);
//   }

//   Future<void> addEntry({
//     required DateTime date,
//     required double amount,
//     required String type, // "receipt" or "expense" from UI
//     String? description,
//     String? category,
//     required String accountId,
//   }) async {
//     // final user = supabase.auth.currentUser;
//     // if (user == null) throw Exception("Not logged in");

//     // Map UI type to DB debit/credit
//     final dbType = type == "receipt" ? "debit" : "credit";

//     await supabase.from('entries').insert({
//       // 'user_id': '138b4fa8-b6f9-4ed2-bb73-590da1eb8bbc', //
//       'date': date.toIso8601String(),
//       'amount': amount,
//       'type': dbType,
//       'category': category,
//       'description': description,
//       'account_id': accountId,
//     });
//     fetchEntries();
//   }

//   Future<void> updateEntry(String entryId, Map<String, dynamic> data) async {
//     if (data.containsKey('type')) {
//       data['type'] = data['type'] == "receipt" ? "debit" : "credit";
//     }
//     await supabase.from('entries').update(data).eq('id', entryId);
//   }

//   Future<void> deleteEntry(String entryId) async {
//     await supabase.from('entries').delete().eq('id', entryId);
//   }

//   Future<Map<String, double>> fetchLedgerTotals() async {
//     final entries = await fetchEntries();
//     double totalReceipts = 0;
//     double totalExpenses = 0;

//     for (var e in entries) {
//       if (e['type'] == "debit") totalReceipts += (e['amount'] ?? 0);
//       if (e['type'] == "credit") totalExpenses += (e['amount'] ?? 0);
//     }

//     return {'totalReceipts': totalReceipts, 'totalExpenses': totalExpenses};
//   }
// }
