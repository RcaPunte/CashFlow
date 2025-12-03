import 'package:cashledger/account/ui/account_list_screen.dart';
import 'package:cashledger/cash_book/ui/cash_book_list_screen.dart';
import 'package:cashledger/ledger/ui/ledget_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Screen')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              context.push('/entries');
            },
            child: const Text('Go to Entries'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => const LedgerScreen()),
              );
              //context.push('/ledger');
            },
            child: const Text('Go to Entries'),
          ),
          ElevatedButton(
            onPressed: () {
              context.push('/entries/add');
            },
            child: const Text('Go to Entries'),
          ),
        ],
      ),
    );
  }
}

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
        if (i == 0) return const CashbookScreen();
        if (i == 1) return const LedgerScreen();
        return const AccountListScreen();
      },
    );
  }
}

// CupertinoSearchTextField(
//   onChanged: (value) {
//     ref.refresh(entriesListProvider);
//   },
// ),
