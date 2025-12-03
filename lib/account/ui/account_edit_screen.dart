import 'package:cashledger/account/controller/account_controller.dart';
import 'package:cashledger/account/model/account_model.dart';
import 'package:cashledger/account/ui/account_add_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AccountEditScreen extends HookConsumerWidget {
  final AccountModel account;
  const AccountEditScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = TextEditingController(text: account.name);
    final description = TextEditingController(text: account.description);
    final limit = TextEditingController(
      text: account.limitAmount?.toString() ?? "",
    );

    return Material(
      child: CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text("Edit Account"),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CupertinoTextField(controller: name, placeholder: "Account name"),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: description,
                placeholder: "Description",
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: limit,
                placeholder: "Limit amount",
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              CupertinoButton.filled(
                child: const Text("Save"),
                onPressed: () async {
                  final updated = AccountModel(
                    id: account.id,
                    name: name.text,
                    description: description.text,
                    accountType: account.accountType,
                    limitAmount: limit.text.isEmpty
                        ? null
                        : double.parse(limit.text),
                  );

                  await ref
                      .read(accountControllerProvider.notifier)
                      .update(account.id, updated);

                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showAccountAddBottomSheet(BuildContext context, WidgetRef ref) {
  showCupertinoModalPopup(
    context: context,
    builder: (_) => SizedBox(
      height: 400,
      child: CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text("Update Account"),
        ),
        child: SafeArea(
          child: AccountAddScreen(), // reuse the same widget
        ),
      ),
    ),
  );
}
