import 'package:cashledger/account/ui/main_ac_page.dart';
import 'package:cashledger/cash_book/ui/cash_book_dashboard.dart';
import 'package:cashledger/ledger/ui/ledger_screen.dart';
import 'package:flutter/cupertino.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.book),
            label: "Cashbook",
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.book),
            label: "Ledger",
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.square_list),
            label: "Accounts",
          ),
        ],
      ),
      tabBuilder: (_, i) {
        if (i == 0) return const CashbookDashboard(); //CashbookScreen();
        if (i == 1) return const LedgerScreen();
        return const AccountsPage(); // AccountListScreen();
      },
    );
  }
}

// CupertinoSearchTextField(
//   onChanged: (value) {
//     ref.refresh(entriesListProvider);
//   },
// ),
