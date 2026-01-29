import 'package:cashledger/account/model/account_model.dart';
import 'package:cashledger/account/ui/account_add_screen.dart';
import 'package:cashledger/account/ui/account_edit_screen.dart';
import 'package:cashledger/auth/controller/auth_controller.dart';
import 'package:cashledger/auth/ui/login_screen.dart';
import 'package:cashledger/cash_book/ui/cash_book_add_edit_screen.dart';
import 'package:cashledger/cash_book/ui/cash_book_list_screen.dart';
import 'package:cashledger/home/home_screen.dart';
import 'package:cashledger/ledger/ui/ledger_screen.dart';
import 'package:cashledger/ledger/ui/widgets/ledger_details_pie.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: cashbookRoutes,
    redirect: (context, state) {
      final user = ref.watch(authServiceProvider).currentUser;
      final loggingIn = state.matchedLocation == "/login";

      if (user == null) {
        return loggingIn ? null : "/login";
      }

      if (loggingIn) return "/";

      return null;
    },
  );
});
final cashbookRoutes = <GoRoute>[
  GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
  GoRoute(
    path: '/ledger/detail/:id',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return LedgerDetailPage(entryId: id);
    },
  ),
  GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
  GoRoute(path: '/cashbook', builder: (_, __) => const CashbookScreen()),
  GoRoute(path: '/accounts/add', builder: (_, __) => const AccountAddScreen()),
  //  '/accounts/edit'
  GoRoute(
    path: '/accounts/edit',
    builder: (_, state) {
      final ac = state.pathParameters as AccountModel;
      return AccountEditScreen(account: ac);
    },
  ),
  GoRoute(
    path: '/entries',
    builder: (_, __) => const CashbookScreen(),
    routes: [
      GoRoute(path: 'add', builder: (_, __) => const AddEntryScreen()),
      GoRoute(
        path: 'edit/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AddEntryScreen();
        },
      ),
      GoRoute(path: '/ledger', builder: (_, __) => const LedgerScreen()),
      GoRoute(
        path: '/ledger',
        builder: (_, __) => const LedgerScreen(),
        routes: [
          GoRoute(
            path: 'detail/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return LedgerDetailPage(entryId: id);
            },
          ),
        ],
      ),
    ],
  ),
];
