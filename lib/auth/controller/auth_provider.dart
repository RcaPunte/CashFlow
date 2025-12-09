import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<User?> {
  AuthNotifier() : super(Supabase.instance.client.auth.currentUser) {
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      state = event.session?.user;
    });
  }

  Future<void> signInWithGoogle() async {
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: "io.supabase.flutter://login-callback/",

      //  kIsWeb
      //     ? "https://xqpyswjocnbsfvmsjdqn.supabase.co/auth/v1/callback"
      //     : "io.supabase.flutter://login-callback/",
    );
    //redirectTo:

    // await supabase.auth.signInWithOAuth(
    //   OAuthProvider.google,
    //   redirectTo: "https://xqpyswjocnbsfvmsjdqn.supabase.co/auth/v1/callback",
    // );
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}
