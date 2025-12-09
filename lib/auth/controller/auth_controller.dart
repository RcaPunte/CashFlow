import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // stream of auth changes (session)
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  User? get currentUser => _supabase.auth.currentUser;

  Future<AuthResponse> signInWithPassword(String email, String password) {
    return _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(
    String email,
    String password, {
    Map<String, dynamic>? data,
  }) {
    return _supabase.auth.signUp(email: email, password: password, data: data);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    // sends reset link to email using Supabase (ensure you've configured SMTP)
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    await _supabase.from('profiles').upsert(updates);
  }
}

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
