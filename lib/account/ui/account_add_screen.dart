import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
// or your own AccountController if separate

class AccountAddScreen extends HookConsumerWidget {
  const AccountAddScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final limitController = TextEditingController();
    String accountType = 'custom';

    return Material(
      child: CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text("Add Account"),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text("Account Name", style: TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              CupertinoTextField(
                controller: nameController,
                placeholder: "Cash, Bank, Wallet…",
              ),

              const SizedBox(height: 16),
              const Text("Description", style: TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              CupertinoTextField(
                controller: descriptionController,
                placeholder: "Optional description",
                maxLines: 3,
              ),

              const SizedBox(height: 16),
              const Text("Account Type", style: TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              CupertinoSlidingSegmentedControl<String>(
                groupValue: accountType,
                children: const {
                  "custom": Text("Custom"),
                  "cash": Text("Cash"),
                  "bank": Text("Bank"),
                },
                onValueChanged: (v) {
                  if (v != null) accountType = v;
                },
              ),

              const SizedBox(height: 16),
              const Text(
                "Monthly Limit Amount (Optional)",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              CupertinoTextField(
                controller: limitController,
                keyboardType: TextInputType.number,
                placeholder: "5000, 10000…",
              ),

              const SizedBox(height: 24),
              CupertinoButton.filled(
                child: const Text("Create Account"),
                onPressed: () async {
                  if (nameController.text.isEmpty) {
                    showCupertinoDialog(
                      context: context,
                      builder: (_) => CupertinoAlertDialog(
                        title: const Text("Error"),
                        content: const Text("Account name is required"),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text("OK"),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    );
                    return;
                  }

                  final id = const Uuid().v4();

                  final account = {
                    'user_id':
                        "dae942b7-4188-4283-8a90-1a1cc224b167", //Supabase.instance.client.auth.currentUser.id??"sdf",
                    "id": id,
                    "name": nameController.text,
                    "description": descriptionController.text,
                    "account_type": accountType,
                    "limit_amount": limitController.text.isEmpty
                        ? null
                        : double.parse(limitController.text),
                  };

                  final supabase = Supabase.instance.client;

                  await supabase.from('accounts').insert(account);

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
