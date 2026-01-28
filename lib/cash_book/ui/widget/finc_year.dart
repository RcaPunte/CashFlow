import 'package:cashledger/cash_book/ui/widget/financial_yeaer_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CashbookDashboard extends ConsumerWidget {
  const CashbookDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fy = ref.watch(financialYearProvider);
    final openingBalance = ref.watch(openingBalanceProvider(fy));

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text("Cash Book"),
        trailing: const FinancialYearSelector(),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle("Opening Balance (${fy.toString()})"),

            _openingTile(
              title: "General Account",
              amount: openingBalance.generalAc,
            ),

            _openingTile(
              title: "Building Account",
              amount: openingBalance.buildingAc,
            ),

            const Divider(),

            _openingTile(
              title: "Total Opening Balance",
              amount: openingBalance.total,
              bold: true,
            ),

            const SizedBox(height: 24),

            _sectionTitle("Monthly Summary"),
            _monthList(fy),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _openingTile({
    required String title,
    required double amount,
    bool bold = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            "₹ ${amount.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthList(FinancialYear fy) {
    final months = List.generate(12, (i) => DateTime(fy.startYear, 4 + i));

    return Column(
      children: months.map((m) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey5,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${_monthName(m.month)} ${m.year}",
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const Text(
                "View",
                style: TextStyle(color: CupertinoColors.activeBlue),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _monthName(int m) {
    const names = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return names[m - 1];
  }
}
