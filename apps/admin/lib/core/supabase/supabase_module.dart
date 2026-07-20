import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin accessor for the initialized Supabase client (injectable in tests).
class SupabaseModule {
  SupabaseModule(this._client);

  final SupabaseClient _client;

  SupabaseClient get client => _client;

  static SupabaseClient get instance => Supabase.instance.client;
}
