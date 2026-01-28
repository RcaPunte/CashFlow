import 'package:cashledger/auth/controller/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// provide the AuthService instance
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Watch Supabase auth state (session changes)
final supabaseAuthStateProvider = StreamProvider<AuthState>((ref) {
  final auth = Supabase.instance.client.auth;
  return auth.onAuthStateChange;
});

// Expose current user as a Provider (nullable)
final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

// Simple convenience provider for signed-in boolean
final isSignedInProvider = Provider<bool>((ref) {
  return Supabase.instance.client.auth.currentUser != null;
});
