import 'package:cashledger/auth/controller/auth_controller.dart';
import 'package:cashledger/auth/ui/login_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthGate extends ConsumerWidget {
  final Widget child;
  const AuthGate({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(supabaseAuthStateProvider);

    return authState.when(
      loading: () {
        return const CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(middle: Text('Loading')),
          child: Center(child: CupertinoActivityIndicator()),
        );
      },
      error: (e, st) {
        // On error, show login (or an error page)
        return const LoginScreen();
      },
      data: (state) {
        // state contains (event, session). session is null when signed out.
        final session = state.session;
        if (session == null) {
          return const LoginScreen();
        } else {
          return child;
        }
      },
    );
  }
}
