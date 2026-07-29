import 'package:cashledger/auth/controller/auth_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showLogoutDialog(BuildContext context, WidgetRef ref) async {
  showCupertinoDialog(
    context: context,
    builder: (_) => CupertinoAlertDialog(
      title: const Text("Logout"),
      content: const Text("Are you sure you want to log out?"),
      actions: [
        CupertinoDialogAction(
          child: const Text("Cancel"),
          onPressed: () => Navigator.pop(context),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          child: const Text("Logout"),
          onPressed: () async {
            Navigator.pop(context);
          //  AuthService().signOut();
            // await ref.read(authProvider).logout();

            // if (context.mounted) {
            //   Navigator.of(
            //     context,
            //   ).pushNamedAndRemoveUntil('/login', (_) => false);
            // }
          },
        ),
      ],
    ),
  );
}
