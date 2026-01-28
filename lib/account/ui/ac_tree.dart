import 'package:cashledger/account/controller/account_controller.dart';
import 'package:cashledger/account/model/account_model.dart';
import 'package:cashledger/account/ui/create_ac.dart';
import 'package:cashledger/ledger/controller/ledger_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountTreeView extends ConsumerWidget {
  final String yearId;
  const AccountTreeView({super.key, required this.yearId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAccounts = ref.watch(accountsListProvider);

    return asyncAccounts.when(
      loading: () => const CupertinoActivityIndicator(),
      error: (e, _) => Text(e.toString()),
      data: (accounts) {
        final tree = buildAccountTree(accounts);
        final roots = tree[null] ?? [];

        return CupertinoListSection.insetGrouped(
          header: const Text('ACCOUNTS'),
          children: roots
              .map((acc) => AccountTreeNode(account: acc, tree: tree, depth: 0))
              .toList(),
        );
      },
    );
  }
}

class AccountTreeNode extends StatefulWidget {
  final AccountModel account;
  final Map<String?, List<AccountModel>> tree;
  final int depth;

  const AccountTreeNode({
    super.key,
    required this.account,
    required this.tree,
    required this.depth,
  });

  @override
  State<AccountTreeNode> createState() => _AccountTreeNodeState();
}

class _AccountTreeNodeState extends State<AccountTreeNode> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final children = widget.tree[widget.account.id] ?? [];
    final hasChildren = children.isNotEmpty;

    return Column(
      children: [
        CupertinoListTile(
          trailing: IconButton(
            icon: const Icon(CupertinoIcons.add),
            onPressed: () {
              showCupertinoDialog(
                context: context,
                builder: (_) => CreateAccountDialog(
                  year: widget.account.year,
                  parent: widget.account,
                ),
              );
            },
          ),
          padding: EdgeInsets.only(left: 16.0 + widget.depth * 18, right: 16),
          leading: hasChildren
              ? GestureDetector(
                  onTap: () => setState(() => expanded = !expanded),
                  child: Icon(
                    expanded
                        ? CupertinoIcons.chevron_down
                        : CupertinoIcons.chevron_right,
                    size: 16,
                  ),
                )
              : const SizedBox(width: 16),

          title: Text(
            widget.account.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: widget.account.isLocked
                  ? CupertinoColors.systemGrey
                  : CupertinoColors.label,
            ),
          ),

          // trailing: widget.account.isLocked
          //     ? const Icon(CupertinoIcons.lock, size: 16)
          //     : const Icon(CupertinoIcons.chevron_right, size: 16),
          onTap: widget.account.isLocked
              ? null
              : () {
                  // open ledger / details
                },
        ),

        if (expanded)
          ...children.map(
            (child) => AccountTreeNode(
              account: child,
              tree: widget.tree,
              depth: widget.depth + 1,
            ),
          ),
      ],
    );
  }
}
