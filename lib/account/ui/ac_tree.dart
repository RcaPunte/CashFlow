import 'package:cashledger/account/controller/account_controller.dart';
import 'package:cashledger/account/controller/account_total_provider.dart';
import 'package:cashledger/account/model/account_model.dart';
import 'package:cashledger/account/ui/create_ac.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AccountTreeView extends ConsumerWidget {
  final String yearId;
  const AccountTreeView({super.key, required this.yearId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAccounts = ref.watch(accountsListProvider);

    return asyncAccounts.when(
      loading: () =>
          const Center(child: CupertinoActivityIndicator(radius: 18)),
      error: (e, _) => Center(
        child: Text(e.toString(),
            style: const TextStyle(
                color: Color(0xFF8E8E93), fontSize: 14)),
      ),
      data: (accounts) {
        final tree = buildAccountTree(accounts);
        final roots = tree[null] ?? [];

        return Column(
          children: roots
              .map((acc) => AccountTreeNode(
                    account: acc,
                    tree: tree,
                    depth: 0,
                  ))
              .toList(),
        );
      },
    );
  }
}

class AccountTreeNode extends ConsumerStatefulWidget {
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
  ConsumerState<AccountTreeNode> createState() => _AccountTreeNodeState();
}

class _AccountTreeNodeState extends ConsumerState<AccountTreeNode> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final children = widget.tree[widget.account.id] ?? [];
    final hasChildren = children.isNotEmpty;
    final fmt = NumberFormat('#,##,##0', 'en_IN');

    final totalsAsync = ref.watch(accountTotalsProvider);
    final totals = totalsAsync.asData?.value ?? {};
    final totalIn = (totals[widget.account.id]?['in'] ?? 0);
    final totalOut = (totals[widget.account.id]?['out'] ?? 0);
    final net = totalIn - totalOut;

    return Container(
      margin: EdgeInsets.only(left: widget.depth * 20.0),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CupertinoColors.separator.withValues(alpha: 0.3),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: CupertinoButton(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              borderRadius: BorderRadius.circular(12),
              onPressed: () {},
              child: Row(
                children: [
                  if (hasChildren)
                    GestureDetector(
                      onTap: () => setState(() => expanded = !expanded),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          expanded
                              ? CupertinoIcons.chevron_down
                              : CupertinoIcons.chevron_right,
                          size: 14,
                          color: const Color(0xFF007AFF),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 24),
                  const SizedBox(width: 8),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.depth == 0
                            ? const [Color(0xFF007AFF), Color(0xFF5856D6)]
                            : const [Color(0xFF8E8E93), Color(0xFF8E8E93)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        widget.account.name.isNotEmpty
                            ? widget.account.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.account.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1C1C1E)
                                .withValues(alpha: 0.95),
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'Income: ₹${fmt.format(totalIn)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF34C759),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Expense: ₹${fmt.format(totalOut)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFFF3B30),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${fmt.format(net)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: net >= 0
                          ? const Color(0xFF34C759)
                          : const Color(0xFFFF3B30),
                    ),
                  ),
                  const SizedBox(width: 4),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      showCupertinoDialog(
                        context: context,
                        builder: (_) => CreateAccountDialog(
                          year: widget.account.year,
                          parent: widget.account,
                        ),
                      );
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Icon(CupertinoIcons.add, size: 14,
                          color: Color(0xFF007AFF)),
                    ),
                  ),
                ],
              ),
            ),
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
      ),
    );
  }
}