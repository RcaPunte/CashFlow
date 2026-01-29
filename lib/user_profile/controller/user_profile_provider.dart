import 'package:cashledger/auth/controller/auth_controller.dart';
import 'package:cashledger/user_profile/model/user_profile_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return null;

  final supabase = Supabase.instance.client;

  try {
    // 1️⃣ Try to fetch existing profile
    final res = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return UserProfile.fromJson(res);
  } catch (_) {
    // 2️⃣ Profile not found → create it
    try {
      if (user.userMetadata == null) {
        throw Exception('User metadata is null');
      }
      final profile = UserProfile(
        id: user.id,
        fullName: user.userMetadata?['full_name'] ?? "Unknown",
        phone: null,
        role: 'user',
      );

      await supabase.from('profiles').insert(profile.toJson());
    } catch (e) {
      // If insertion fails, rethrow the error
      throw Exception('Failed to create user profile: $e');
    }
  }
  return null;
});
