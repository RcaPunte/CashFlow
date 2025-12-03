import 'package:cashledger/account/controller/account_controller.dart'
    show accountControllerProvider;
import 'package:cashledger/account/ui/account_edit_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AccountListScreen extends HookConsumerWidget {
  const AccountListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountControllerProvider);

    return Material(
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text("Accounts"),
          trailing: GestureDetector(
            onTap: () => context.push('/accounts/add'),
            child: const Icon(CupertinoIcons.add),
          ),
        ),
        child: accounts.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (list) => ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final acc = list[i];
              return CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                onPressed: () => Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => AccountEditScreen(account: acc),
                  ),
                ), //context.push('/accounts/edit', extra: acc),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(acc.name),
                    const Icon(CupertinoIcons.chevron_forward),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
