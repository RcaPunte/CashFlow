import 'package:cashledger/account/controller/account_controller.dart';
import 'package:cashledger/account/model/account_model.dart';
import 'package:cashledger/account/ui/ac_tree.dart';
import 'package:cashledger/account/ui/create_ac.dart';
import 'package:cashledger/cash_book/ui/widget/financial_yeaer_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Divider, IconButton, ListTile, Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';

//ACTIVE
class AccountsPage extends ConsumerWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(yearProvider);
    final accountsAsync = ref.watch(accountsListProvider);

    return Material(
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text("Accounts"),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.add),
            onPressed: () {
              showCupertinoDialog(
                context: context,
                builder: (_) => CreateAccountDialog(year: year),
              );
            },
          ),
        ),
        child: SingleChildScrollView(
          child: AccountTreeView(yearId: year.toString()),
        ),
      ),
    );
  }
}

class _AccountTile extends ConsumerWidget {
  final AccountModel account;
  final List<AccountModel> children;

  const _AccountTile({required this.account, required this.children});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(account.name),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!account.isLocked)
                IconButton(
                  icon: const Icon(CupertinoIcons.add),
                  onPressed: () {
                    showCupertinoDialog(
                      context: context,
                      builder: (_) => CreateAccountDialog(
                        year: account.year,
                        parent: account,
                      ),
                    );
                  },
                ),
              if (account.isLocked)
                const Icon(
                  CupertinoIcons.lock,
                  size: 18,
                  color: CupertinoColors.systemGrey,
                ),
            ],
          ),
        ),
        ...children.map(
          (c) => Padding(
            padding: const EdgeInsets.only(left: 24),
            child: ListTile(title: Text("• ${c.name}")),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
