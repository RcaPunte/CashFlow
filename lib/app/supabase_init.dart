import 'package:supabase_flutter/supabase_flutter.dart';

class AppSupabase {
  static const _defaultUrl = String.fromEnvironment(
    'SUPABASE_URL',
  );
  static const _defaultAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static Future<void> initialize() async {
    final url = _defaultUrl;
    final anonKey = _defaultAnonKey;

    if (url.isEmpty || anonKey.isEmpty) {
      throw Exception(
        'Missing Supabase environment variables. '
        'Pass them via --dart-define:\n'
        'flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co '
        '--dart-define=SUPABASE_ANON_KEY=your-anon-key',
      );
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}