import 'package:cashledger/account/model/account_model.dart';

/// A single line item in a budget, linked to an account
class BudgetItem {
  final String id;
  final String budgetId;
  final String accountId;
  final double budgetedAmount;
  final double previousActual;

  /// Optional — resolved from account lookup for display
  final String? accountName;
  final String? accountType;
  final String? parentAccountId;

  /// Computed at query time — actuals from entries table during this budget period
  final double? actualIncome;
  final double? actualExpense;

  /// Total actual = income + expense (for backward compat)
  double? get actualAmount {
    if (actualIncome == null && actualExpense == null) return null;
    return (actualIncome ?? 0) + (actualExpense ?? 0);
  }

  BudgetItem({
    required this.id,
    required this.budgetId,
    required this.accountId,
    required this.budgetedAmount,
    required this.previousActual,
    this.accountName,
    this.accountType,
    this.parentAccountId,
    this.actualIncome,
    this.actualExpense,
  });

  /// Utilization percentage = (actualExpense / budgetedAmount) × 100
  double? get utilizationPercent {
    if (actualExpense == null || budgetedAmount == 0) return null;
    return (actualExpense! / budgetedAmount) * 100;
  }

  /// Remaining balance = budgetedAmount - actualExpense
  double? get remainingBalance {
    if (actualExpense == null) return null;
    return budgetedAmount - actualExpense!;
  }

  /// Budget variance = actualExpense - budgetedAmount
  double? get variance {
    if (actualExpense == null) return null;
    return actualExpense! - budgetedAmount;
  }

  factory BudgetItem.fromMap(Map<String, dynamic> m) {
    return BudgetItem(
      id: m['id'] as String,
      budgetId: m['budget_id'] as String,
      accountId: m['account_id'] as String,
      budgetedAmount: (m['budgeted_amount'] as num).toDouble(),
      previousActual: (m['previous_actual'] as num?)?.toDouble() ?? 0,
      accountName: m['account_name'] as String? ?? m['accounts']?['name'] as String?,
      accountType: m['account_type'] as String? ?? m['accounts']?['account_type'] as String?,
      parentAccountId: m['parent_account_id'] as String? ?? m['accounts']?['parent_account_id'] as String?,
      actualIncome: m['actual_income'] != null
          ? (m['actual_income'] as num).toDouble()
          : null,
      actualExpense: m['actual_expense'] != null
          ? (m['actual_expense'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'budget_id': budgetId,
      'account_id': accountId,
      'budgeted_amount': budgetedAmount,
      'previous_actual': previousActual,
    };
  }

  BudgetItem copyWith({
    String? id,
    String? budgetId,
    String? accountId,
    double? budgetedAmount,
    double? previousActual,
    String? accountName,
    String? accountType,
    String? parentAccountId,
    double? actualIncome,
    double? actualExpense,
  }) {
    return BudgetItem(
      id: id ?? this.id,
      budgetId: budgetId ?? this.budgetId,
      accountId: accountId ?? this.accountId,
      budgetedAmount: budgetedAmount ?? this.budgetedAmount,
      previousActual: previousActual ?? this.previousActual,
      accountName: accountName ?? this.accountName,
      accountType: accountType ?? this.accountType,
      parentAccountId: parentAccountId ?? this.parentAccountId,
      actualIncome: actualIncome ?? this.actualIncome,
      actualExpense: actualExpense ?? this.actualExpense,
    );
  }
}

/// A budget item with its associated account model
class BudgetItemWithAccount {
  final BudgetItem item;
  final AccountModel? account;

  BudgetItemWithAccount({required this.item, this.account});
}