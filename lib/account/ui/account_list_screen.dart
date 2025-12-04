import 'package:cashledger/account/controller/account_controller.dart'
    show accountControllerProvider;
import 'package:cashledger/account/ui/account_edit_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AccountListScreen extends HookConsumerWidget {
  const AccountListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountControllerProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text("Accounts"),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.push('/accounts/add'),
          child: const Icon(CupertinoIcons.add, size: 22),
        ),
      ),
      backgroundColor: CupertinoColors.systemGroupedBackground,

      child: accountsAsync.when(
        loading: () =>
            const Center(child: CupertinoActivityIndicator(radius: 18)),
        error: (e, _) => Center(
          child: Text(
            "Error loading accounts: ${e.toString()}",
            style: const TextStyle(color: CupertinoColors.systemRed),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  "No accounts found. Tap '+' to add a new account.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: CupertinoColors.systemGrey),
                ),
              ),
            );
          }

          // 🛠️ FIX APPLIED HERE: Wrap CupertinoListSection in a ListView
          return ListView(
            // Use a slight top padding to give space below the navigation bar
            padding: const EdgeInsets.only(top: 10),
            children: [
              CupertinoListSection.insetGrouped(
                children: [
                  for (final acc in list)
                    CupertinoListTile(
                      title: Text(acc.name, overflow: TextOverflow.ellipsis),
                      trailing: const Icon(
                        CupertinoIcons.chevron_right,
                        size: 18,
                        color: CupertinoColors.systemGrey,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) => AccountEditScreen(account: acc),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
