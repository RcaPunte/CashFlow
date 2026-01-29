import 'package:cashledger/auth/controller/auth_controller.dart';
import 'package:cashledger/user_profile/ui/user_profile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserProfileButton extends ConsumerWidget {
  const UserProfileButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) return const SizedBox.shrink();

    return CupertinoButton(
      padding: EdgeInsets.zero,
      child: const Icon(CupertinoIcons.person),
      onPressed: () {
        Navigator.of(
          context,
        ).push(CupertinoPageRoute(builder: (_) => const UserProfilePage()));
      },
    );

    // IconButton(
    //   icon: const Icon(Icons.),
    //   tooltip: 'My Profile',
    //   onPressed: () {
    //     Navigator.of(
    //       context,
    //     ).push(CupertinoPageRoute(builder: (_) => const UserProfilePage()));
    //   },
    // );
  }
}
