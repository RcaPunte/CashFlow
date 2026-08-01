import 'package:cashledger/budget/model/budget_approval_model.dart';
import 'package:cashledger/budget/model/budget_item_model.dart';
import 'package:cashledger/budget/model/budget_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BudgetRepository {
  final SupabaseClient _client;

  BudgetRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // ──────────────────────────────────────────────
  // Budgets CRUD
  // ──────────────────────────────────────────────

  Future<List<Budget>> fetchBudgets({int? year}) async {
    var query = _client.from('budgets').select('*, accounts(id, name)');

    if (year != null) {
      query = query.eq('year', year);
    }

    final rows = await query.order('created_at', ascending: false);
    return rows.map((r) => Budget.fromMap(r)).toList();
  }

  Future<Budget?> fetchBudget(String id) async {
    final row = await _client
        .from('budgets')
        .select('*, accounts(id, name)')
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return Budget.fromMap(row);
  }

  Future<Budget> createBudget(Budget budget) async {
    final map = budget.toMap();
    // Remove empty id so Supabase auto-generates a UUID
    if (map['id'] == null || (map['id'] as String).isEmpty) {
      map.remove('id');
    }
    // user_id is NOT NULL in DB — use current auth user to satisfy constraint
    map['user_id'] = _client.auth.currentUser?.id ?? '';
    final row = await _client
        .from('budgets')
        .insert(map)
        .select()
        .single();
    return Budget.fromMap(row);
  }

  Future<Budget> updateBudget(Budget budget) async {
    final map = budget.toMap();
    // user_id is NOT NULL in DB — use current auth user to satisfy constraint
    map['user_id'] = _client.auth.currentUser?.id ?? '';
    final row = await _client
        .from('budgets')
        .update(map)
        .eq('id', budget.id)
        .select()
        .single();
    return Budget.fromMap(row);
  }

  Future<void> deleteBudget(String id) async {
    await _client.from('budget_items').delete().eq('budget_id', id);
    await _client.from('budget_approvals').delete().eq('budget_id', id);
    await _client.from('budgets').delete().eq('id', id);
  }

  // ──────────────────────────────────────────────
  // Budget Items CRUD
  // ──────────────────────────────────────────────

  Future<List<BudgetItem>> fetchBudgetItems(String budgetId) async {
    final rows = await _client
        .from('budget_items')
        .select('*, accounts(id, name, account_type, parent_account_id)')
        .eq('budget_id', budgetId)
        .order('created_at');
    return rows.map((r) => BudgetItem.fromMap(r)).toList();
  }

  /// Fetch budget items with actual amounts computed from entries
  Future<List<BudgetItem>> fetchBudgetItemsWithActuals(
    Budget budget,
  ) async {
    // 1. Fetch budget items with account info
    final itemsRaw = await _client
        .from('budget_items')
        .select('*, accounts(id, name, account_type, parent_account_id)')
        .eq('budget_id', budget.id)
        .order('created_at');

    final items = itemsRaw.map((r) => BudgetItem.fromMap(r)).toList();

    // 2. Fetch actuals from entries for the budget period
    final entries = await _client
        .from('entries')
        .select('account_id, type, amount')
        .gte('date', budget.periodStart.toIso8601String())
        .lte('date', budget.periodEnd.toIso8601String());

    // 3. Aggregate actuals by account_id — separate income (debit) and expense (credit)
    final Map<String, double> actualIncomeByAccount = {};
    final Map<String, double> actualExpenseByAccount = {};
    for (final e in entries) {
      final accId = e['account_id'] as String;
      final amt = (e['amount'] as num).toDouble();
      final type = e['type'] as String;
      if (type == 'debit') {
        // debit = income (money received)
        actualIncomeByAccount.update(
          accId,
          (v) => v + amt,
          ifAbsent: () => amt,
        );
      } else {
        // credit = expense (money spent)
        actualExpenseByAccount.update(
          accId,
          (v) => v + amt,
          ifAbsent: () => amt,
        );
      }
    }

    // 4. Attach actuals to items
    return items.map((item) {
      return item.copyWith(
        actualIncome: actualIncomeByAccount[item.accountId],
        actualExpense: actualExpenseByAccount[item.accountId],
      );
    }).toList();
  }

  /// Fetch previous year actuals per account for budget planning
  Future<Map<String, double>> fetchPreviousYearActuals({
    required Budget budget,
  }) async {
    final prev = budget.previousPeriod;

    final rows = await _client
        .from('entries')
        .select('account_id, type, amount')
        .gte('date', prev.from.toIso8601String())
        .lte('date', prev.to.toIso8601String());

    final Map<String, double> map = {};
    for (final r in rows) {
      final accId = r['account_id'] as String;
      final amt = (r['amount'] as num).toDouble();
      final type = r['type'] as String;
      map.update(
        accId,
        (v) => v + (type == 'debit' ? amt : amt),
        ifAbsent: () => type == 'debit' ? amt : amt,
      );
    }
    return map;
  }

  Future<void> saveBudgetItems(
    String budgetId,
    List<BudgetItem> items,
    Map<String, double> previousActuals,
  ) async {
    // Delete existing items
    await _client.from('budget_items').delete().eq('budget_id', budgetId);

    // Insert new items with frozen previous actuals
    // Supabase auto-generates UUID via gen_random_uuid()
    for (final item in items) {
      final data = item.toMap();
      data.remove('id');
      data['budget_id'] = budgetId;
      data['previous_actual'] = previousActuals[item.accountId] ?? 0;
      await _client.from('budget_items').insert(data);
    }
  }

  /// Add or update a single budget item without affecting others.
  /// If an item with the same budget_id + account_id already exists, its
  /// budgeted_amount is updated in-place. Otherwise a new row is inserted.
  Future<void> addOrUpdateBudgetItem(
    String budgetId,
    BudgetItem item,
    Map<String, double> previousActuals,
  ) async {
    // Check if this account already has a budget item
    final existing = await _client
        .from('budget_items')
        .select('id')
        .eq('budget_id', budgetId)
        .eq('account_id', item.accountId)
        .maybeSingle();

    if (existing != null) {
      // Update existing item
      await _client
          .from('budget_items')
          .update({
            'budgeted_amount': item.budgetedAmount,
            'previous_actual': previousActuals[item.accountId] ?? 0,
          })
          .eq('id', existing['id'] as String);
    } else {
      // Insert new item — Supabase auto-generates UUID
      final data = item.toMap();
      data.remove('id');
      data['budget_id'] = budgetId;
      data['previous_actual'] = previousActuals[item.accountId] ?? 0;
      await _client.from('budget_items').insert(data);
    }
  }
}