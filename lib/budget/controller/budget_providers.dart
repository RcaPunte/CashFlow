import 'package:cashledger/account/model/account_model.dart';
import 'package:cashledger/budget/model/budget_approval_model.dart';
import 'package:cashledger/budget/model/budget_item_model.dart';
import 'package:cashledger/budget/model/budget_model.dart';
import 'package:cashledger/budget/repository/budget_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider for the budget repository
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository();
});

// ──────────────────────────────────────────────
// Budget List
// ──────────────────────────────────────────────

final budgetListProvider = FutureProvider.autoDispose<List<Budget>>((ref) async {
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.fetchBudgets();
});

// ──────────────────────────────────────────────
// Single Budget Detail
// ──────────────────────────────────────────────

final budgetDetailProvider =
    FutureProvider.autoDispose.family<Budget, String>((ref, budgetId) async {
  final repo = ref.watch(budgetRepositoryProvider);
  final budget = await repo.fetchBudget(budgetId);
  if (budget == null) {
    throw Exception('Budget not found');
  }
  return budget;
});

// ──────────────────────────────────────────────
// Budget Items (with actuals)
// ──────────────────────────────────────────────

final budgetItemsProvider =
    FutureProvider.autoDispose.family<List<BudgetItem>, Budget>(
        (ref, budget) async {
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.fetchBudgetItemsWithActuals(budget);
});

// ──────────────────────────────────────────────
// Budget Items (simple, without actuals)
// ──────────────────────────────────────────────

final budgetItemsSimpleProvider =
    FutureProvider.autoDispose.family<List<BudgetItem>, String>(
        (ref, budgetId) async {
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.fetchBudgetItems(budgetId);
});

// ──────────────────────────────────────────────
// Previous Year Actuals (for budget creation)
// ──────────────────────────────────────────────

final previousYearActualsProvider =
    FutureProvider.autoDispose
        .family<Map<String, double>, Budget>((ref, budget) async {
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.fetchPreviousYearActuals(budget: budget);
});

// ──────────────────────────────────────────────
// Budget Summary (aggregated)
// ──────────────────────────────────────────────

class BudgetSummary {
  final double totalBudgeted;
  final double totalActualIncome;
  final double totalActualExpense;
  final double totalPrevious;
  final double openingBalance;

  double get totalActual => totalActualIncome + totalActualExpense;
  double get variance => totalActualExpense - totalBudgeted;
  double get utilizationPercent =>
      totalBudgeted == 0 ? 0 : (totalActualExpense / totalBudgeted) * 100;
  double get remainingBalance => totalBudgeted - totalActualExpense;

  BudgetSummary({
    required this.totalBudgeted,
    required this.totalActualIncome,
    required this.totalActualExpense,
    required this.totalPrevious,
    required this.openingBalance,
  });
}

final budgetSummaryProvider =
    FutureProvider.autoDispose.family<BudgetSummary, Budget>(
        (ref, budget) async {
  final items = await ref.watch(budgetItemsProvider(budget).future);
  final totalBudgeted =
      items.fold<double>(0, (sum, item) => sum + item.budgetedAmount);
  final totalActualIncome =
      items.fold<double>(0, (sum, item) => sum + (item.actualIncome ?? 0));
  final totalActualExpense =
      items.fold<double>(0, (sum, item) => sum + (item.actualExpense ?? 0));
  final totalPrevious =
      items.fold<double>(0, (sum, item) => sum + item.previousActual);
  return BudgetSummary(
    totalBudgeted: totalBudgeted,
    totalActualIncome: totalActualIncome,
    totalActualExpense: totalActualExpense,
    totalPrevious: totalPrevious,
    openingBalance: budget.openingBalance ?? 0,
  );
});

// ──────────────────────────────────────────────
// Accounts List (for budget item selection)
// ──────────────────────────────────────────────

final accountsForBudgetProvider =
    FutureProvider.autoDispose<List<AccountModel>>((ref) async {
  final supabase = Supabase.instance.client;
  final now = DateTime.now();
  final year = now.year;

  final query = supabase.from('accounts').select().eq('year', year);

  final rows = await query.order('name', ascending: true);
  return rows.map((r) => AccountModel.fromMap(r)).toList();
});
