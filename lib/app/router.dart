import 'package:cashledger/account/ui/account_add_screen.dart';
import 'package:cashledger/account/ui/account_edit_screen.dart';
import 'package:cashledger/auth/controller/auth_provider.dart';
import 'package:cashledger/auth/ui/login_screen.dart';
import 'package:cashledger/cash_book/ui/cash_book_add_edit_screen.dart';
import 'package:cashledger/cash_book/ui/cash_book_list_screen.dart';
import 'package:cashledger/home/home_screen.dart';
import 'package:cashledger/ledger/ui/ledger_screen.dart';
import 'package:cashledger/ledger/ui/widgets/ledger_details_pie.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final isSignedIn = ref.watch(isSignedInProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';
      final onSignUp = state.matchedLocation == '/signup';

      if (!isSignedIn) {
        return loggingIn || onSignUp ? null : '/login';
      }

      if (isSignedIn && (loggingIn || onSignUp)) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (_, __) => const DashboardScreen(),
        routes: [
          GoRoute(
            path: 'entries/add',
            builder: (_, __) => const AddEntryScreen(),
          ),
          GoRoute(
            path: 'entries/edit/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'];
              return AddEntryScreen(
                entry: id != null ? {'id': id} : null,
              );
            },
          ),
          GoRoute(
            path: 'cashbook',
            builder: (_, __) => const CashbookScreen(),
          ),
          GoRoute(
            path: 'accounts/add',
            builder: (_, __) => const AccountAddScreen(),
          ),
          GoRoute(
            path: 'accounts/edit',
            builder: (_, state) {
              final extra = state.extra;
              if (extra != null) {
                return AccountEditScreen(account: extra as dynamic);
              }
              return const AccountAddScreen();
            },
          ),
          GoRoute(
            path: 'ledger',
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
    ],
  );
});