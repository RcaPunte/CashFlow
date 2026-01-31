// class AccountSummaryCard extends StatelessWidget {
//   final MonthlyCashSummary summary;

//   const AccountSummaryCard({super.key, required this.summary});

//   Widget _row(BuildContext context, String label, double value,
//       {Color? color}) {
//     final resolved = color ??
//         (value >= 0
//             ? CupertinoColors.label.resolveFrom(context)
//             : CupertinoColors.systemRed.resolveFrom(context));

//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label,
//               style: TextStyle(
//                   color: CupertinoColors.secondaryLabel
//                       .resolveFrom(context))),
//           Text(
//             "₹${value.toStringAsFixed(2)}",
//             style: TextStyle(fontWeight: FontWeight.w600, color: resolved),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final totalIncome = summary.openingBalance + summary.receipts;

//     return Container(
//       margin: const EdgeInsets.all(12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: CupertinoColors.systemBackground.resolveFrom(context),
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: [
//           BoxShadow(
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//             color: CupertinoColors.systemGrey
//                 .resolveFrom(context)
//                 .withOpacity(0.2),
//           )
//         ],
//       ),
//       child: Column(
//         children: [
//           _row(context, "Opening Balance", summary.openingBalance),
//           const Divider(),
//           _row(context, "New Income", summary.receipts,
//               color: CupertinoColors.activeGreen),
//           const Divider(),
//           _row(context, "Total Income", totalIncome,
//               color: CupertinoColors.activeGreen),
//           const Divider(),
//           _row(context, "Total Expenditure", summary.expenses,
//               color: CupertinoColors.systemRed),
//           const Divider(),
//           _row(context, "Closing Balance", summary.closingBalance,
//               color: summary.closingBalance >= 0
//                   ? CupertinoColors.activeBlue
//                   : CupertinoColors.systemRed),
//         ],
//       ),
//     );
//   }
// }

// final summaryAsync = ref.watch(monthlySummaryProvider(selectedMonth));

// // summaryAsync.when(
// //   data: (summary) => AccountSummaryCard(summary: summary),
// //   loading: () => const Padding(
// //     padding: EdgeInsets.all(24),
// //     child: CupertinoActivityIndicator(),
// //   ),
// //   error: (_, __) => const SizedBox(),
// // ),

// // ------------------------------------------------------------
// // MODELS
// // ------------------------------------------------------------
// class AccountNode {
//   final String id;
//   final String name;
//   final String? parentId;

//   AccountNode({required this.id, required this.name, this.parentId});
// }

// class AccountTotal {
//   double receipts = 0;
//   double expenses = 0;
// }

// // ------------------------------------------------------------
// // PROVIDERS
// // ------------------------------------------------------------

// /// toggle expand / collapse per parent
// final expandedAccountsProvider = StateProvider<Set<String>>((ref) => {});

// /// toggle show sub-accounts
// final showSubAccountsProvider = StateProvider<bool>((ref) => true);

// /// fetch accounts tree
// final accountsTreeProvider = FutureProvider<List<AccountNode>>((ref) async {
//   final res = await Supabase.instance.client
//       .from('accounts')
//       .select('id, name, parent_account_id');

//   return res
//       .map<AccountNode>((e) => AccountNode(
//             id: e['id'],
//             name: e['name'],
//             parentId: e['parent_account_id'],
//           ))
//       .toList();
// });

// /// monthly totals grouped by account id
// final monthlyAccountTotalsProvider = FutureProvider.family<
//     Map<String, AccountTotal>, DateTime>((ref, date) async {
//   final supabase = Supabase.instance.client;

//   final from = DateTime(date.year, date.month, 1);
//   final to = DateTime(date.year, date.month + 1, 0);

//   final rows = await supabase
//       .from('entries')
//       .select('type, amount, account_id')
//       .gte('date', from.toIso8601String())
//       .lte('date', to.toIso8601String());

//   final map = <String, AccountTotal>{};

//   for (final e in rows) {
//     final id = e['account_id'] as String;
//     final amt = (e['amount'] as num).toDouble();

//     map.putIfAbsent(id, () => AccountTotal());

//     if (e['type'] == 'debit') {
//       map[id]!.receipts += amt;
//     } else {
//       map[id]!.expenses += amt;
//     }
//   }

//   return map;
// });

// // ------------------------------------------------------------
// // SCREEN
// // ------------------------------------------------------------

// class MonthlyReportScreen extends ConsumerWidget {
//   final DateTime month;
//   const MonthlyReportScreen({super.key, required this.month});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final showSubs = ref.watch(showSubAccountsProvider);
//     final expanded = ref.watch(expandedAccountsProvider);

//     final accountsAsync = ref.watch(accountsTreeProvider);
//     final totalsAsync = ref.watch(monthlyAccountTotalsProvider(month));

//     return CupertinoPageScaffold(
//       navigationBar: CupertinoNavigationBar(
//         middle: const Text('Monthly Report'),
//         trailing: CupertinoSwitch(
//           value: showSubs,
//           onChanged: (v) =>
//               ref.read(showSubAccountsProvider.notifier).state = v,
//         ),
//       ),
//       child: SafeArea(
//         child: accountsAsync.when(
//           data: (accounts) => totalsAsync.when(
//             data: (totals) {
//               final parents = accounts
//                   .where((a) => a.parentId == null)
//                   .toList();

//               return ListView.builder(
//                 itemCount: parents.length,
//                 itemBuilder: (_, i) {
//                   final parent = parents[i];
//                   final isOpen = expanded.contains(parent.id);

//                   final children = accounts
//                       .where((a) => a.parentId == parent.id)
//                       .toList();

//                   final parentTotal = _aggregate(parent.id, children, totals);

//                   return Column(
//                     children: [
//                       _ParentTile(
//                         name: parent.name,
//                         total: parentTotal,
//                         expanded: isOpen,
//                         hasChildren: children.isNotEmpty,
//                         onTap: () {
//                           final set = {...expanded};
//                           isOpen ? set.remove(parent.id) : set.add(parent.id);
//                           ref.read(expandedAccountsProvider.notifier).state =
//                               set;
//                         },
//                       ),
//                       if (showSubs && isOpen)
//                         ...children.map((c) => _ChildTile(
//                               name: c.name,
//                               total: totals[c.id],
//                             )),
//                     ],
//                   );
//                 },
//               );
//             },
//             loading: () => const Center(child: CupertinoActivityIndicator()),
//             error: (_, __) => const Center(child: Text('Error loading totals')),
//           ),
//           loading: () => const Center(child: CupertinoActivityIndicator()),
//           error: (_, __) => const Center(child: Text('Error loading accounts')),
//         ),
//       ),
//     );
//   }

//   AccountTotal _aggregate(
//     String parentId,
//     List<AccountNode> children,
//     Map<String, AccountTotal> totals,
//   ) {
//     final total = AccountTotal();

//     if (totals[parentId] != null) {
//       total.receipts += totals[parentId]!.receipts;
//       total.expenses += totals[parentId]!.expenses;
//     }

//     for (final c in children) {
//       if (totals[c.id] != null) {
//         total.receipts += totals[c.id]!.receipts;
//         total.expenses += totals[c.id]!.expenses;
//       }
//     }

//     return total;
//   }
// }

// // ------------------------------------------------------------
// // UI TILES
// // ------------------------------------------------------------

// class _ParentTile extends StatelessWidget {
//   final String name;
//   final AccountTotal total;
//   final bool expanded;
//   final bool hasChildren;
//   final VoidCallback onTap;

//   const _ParentTile({
//     required this.name,
//     required this.total,
//     required this.expanded,
//     required this.hasChildren,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return CupertinoListTile(
//       title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
//       subtitle: Text(
//           'In: ₹${total.receipts.toStringAsFixed(2)}  Out: ₹${total.expenses.toStringAsFixed(2)}'),
//       trailing: hasChildren
//           ? Icon(expanded
//               ? CupertinoIcons.chevron_down
//               : CupertinoIcons.chevron_right)
//           : null,
//       onTap: hasChildren ? onTap : null,
//     );
//   }
// }

// class _ChildTile extends StatelessWidget {
//   final String name;
//   final AccountTotal? total;

//   const _ChildTile({required this.name, this.total});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(left: 32),
//       child: CupertinoListTile(
//         title: Text(name),
//         subtitle: Text(
//             'In: ₹${(total?.receipts ?? 0).toStringAsFixed(2)}  Out: ₹${(total?.expenses ?? 0).toStringAsFixed(2)}'),
//       ),
//     );
//   }
// }
