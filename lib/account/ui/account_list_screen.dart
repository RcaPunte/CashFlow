import 'package:cashledger/account/controller/account_controller.dart'
    show accountControllerProvider;
import 'package:cashledger/account/controller/account_total_provider.dart';
import 'package:cashledger/export/account_export.dart' show AccountExportUtils;
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AccountListScreen extends HookConsumerWidget {
  const AccountListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountControllerProvider);
    final totalsAsync = ref.watch(accountTotalsProvider);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text("Accounts"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () async {
                final accounts = accountsAsync.asData?.value ?? [];
                final totals = totalsAsync.asData?.value ?? {};
                if (accounts.isEmpty) return;

                await AccountExportUtils.openExportSheet(
                  context: context,
                  totals: totals,
                  accounts: accounts,
                );
              },
              child: const Icon(CupertinoIcons.square_arrow_up, size: 22),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => context.push('/accounts/add'),
              child: const Icon(CupertinoIcons.add, size: 22),
            ),
          ],
        ),
      ),

      // ======================= BODY ==========================
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

          final totals = totalsAsync.asData?.value ?? {};

          final totalIn = totals.values.fold(0.0, (s, v) => s + (v['in'] ?? 0));
          final totalOut = totals.values.fold(
            0.0,
            (s, v) => s + (v['out'] ?? 0),
          );
          final net = totalIn - totalOut;

          return ListView(
            padding: const EdgeInsets.only(top: 12),
            children: [
              // Summary Section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: _AccountSummaryCard(
                  totalIn: totalIn,
                  totalOut: totalOut,
                  net: net,
                ),
              ),

              // Accounts List
              CupertinoListSection.insetGrouped(
                children: [
                  for (final acc in list)
                    CupertinoListTile(
                      title: Text(acc.name, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        "In: ₹${(totals[acc.id]?['in'] ?? 0).toStringAsFixed(2)}   "
                        "Out: ₹${(totals[acc.id]?['out'] ?? 0).toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                      trailing: Text(
                        "₹${((totals[acc.id]?['in'] ?? 0) - (totals[acc.id]?['out'] ?? 0)).toStringAsFixed(2)}",
                        style: TextStyle(
                          color:
                              ((totals[acc.id]?['in'] ?? 0) -
                                      (totals[acc.id]?['out'] ?? 0)) >=
                                  0
                              ? CupertinoColors.activeGreen
                              : CupertinoColors.destructiveRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/accounts/edit',
                          arguments: acc,
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

// ======================= SUMMARY CARD ==========================
class _AccountSummaryCard extends StatelessWidget {
  final double totalIn;
  final double totalOut;
  final double net;

  const _AccountSummaryCard({
    required this.totalIn,
    required this.totalOut,
    required this.net,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGroupedBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CupertinoColors.separator.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStat('Total In', totalIn, CupertinoColors.activeGreen),
          _buildStat('Total Out', totalOut, CupertinoColors.destructiveRed),
          _buildStat('Net', net, CupertinoColors.activeBlue),
        ],
      ),
    );
  }

  Widget _buildStat(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: color)),
        const SizedBox(height: 4),
        Text(
          '₹${value.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// class AccountListScreen extends HookConsumerWidget {
//   const AccountListScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final accountsAsync = ref.watch(accountControllerProvider);

//     return CupertinoPageScaffold(
//       navigationBar: CupertinoNavigationBar(
//         middle: const Text("Accounts"),
//         trailing: CupertinoButton(
//           padding: EdgeInsets.zero,
//           onPressed: () => context.push('/accounts/add'),
//           child: const Icon(CupertinoIcons.add, size: 22),
//         ),
//       ),
//       backgroundColor: CupertinoColors.systemGroupedBackground,

//       child: accountsAsync.when(
//         loading: () =>
//             const Center(child: CupertinoActivityIndicator(radius: 18)),
//         error: (e, _) => Center(
//           child: Text(
//             "Error loading accounts: ${e.toString()}",
//             style: const TextStyle(color: CupertinoColors.systemRed),
//           ),
//         ),
//         data: (list) {
//           if (list.isEmpty) {
//             return const Center(
//               child: Padding(
//                 padding: EdgeInsets.all(32.0),
//                 child: Text(
//                   "No accounts found. Tap '+' to add a new account.",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(color: CupertinoColors.systemGrey),
//                 ),
//               ),
//             );
//           }

//           // 🛠️ FIX APPLIED HERE: Wrap CupertinoListSection in a ListView
//           return ListView(
//             // Use a slight top padding to give space below the navigation bar
//             padding: const EdgeInsets.only(top: 10),
//             children: [
//               CupertinoListSection.insetGrouped(
//                 children: [
//                   for (final acc in list)
//                     CupertinoListTile(
//                       title: Text(acc.name, overflow: TextOverflow.ellipsis),
//                       trailing: const Icon(
//                         CupertinoIcons.chevron_right,
//                         size: 18,
//                         color: CupertinoColors.systemGrey,
//                       ),
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           CupertinoPageRoute(
//                             builder: (_) => AccountEditScreen(account: acc),
//                           ),
//                         );
//                       },
//                     ),
//                 ],
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }
