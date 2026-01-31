import 'package:cashledger/account/model/account_model.dart';

class MonthlyCashSummary {
  final String monthKey; // "2025-01"
  final double openingBalance;
  final double receipts;
  final double expenses;
  final Map<String, AccountModel>? accountsById;
  double get closingBalance => openingBalance + receipts - expenses;

  final Map<String, double> receiptsByAccount;
  final Map<String, double> expensesByAccount;

  MonthlyCashSummary({
    required this.monthKey,
    required this.openingBalance,
    required this.receipts,
    required this.expenses,
    required this.receiptsByAccount,
    required this.expensesByAccount,
    required double closingBalance,
    required this.accountsById,
  });
}
