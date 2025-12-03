import 'package:supabase_flutter/supabase_flutter.dart';

class AppSupabase {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://xqpyswjocnbsfvmsjdqn.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhxcHlzd2pvY25ic2Z2bXNqZHFuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNjY3NjYsImV4cCI6MjA3OTc0Mjc2Nn0.YTl4Pf3cM0JmTa5t0I0pE5iKnUfHaGD_h5iXhP1Iy50',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
