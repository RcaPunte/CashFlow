import 'package:cashledger/auth/controller/auth_provider.dart';
import 'package:cashledger/auth/ui/login_screen.dart';
import 'package:cashledger/home/home_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      loading: () => const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('Loading')),
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (_, __) => const LoginScreen(),
      data: (state) {
        if (state.session == null) {
          return const LoginScreen();
        }
        return const DashboardScreen();
      },
    );
  }
}