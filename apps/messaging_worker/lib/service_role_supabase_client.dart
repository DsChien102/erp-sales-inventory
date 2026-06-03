import 'package:supabase/supabase.dart';

SupabaseClient createServiceRoleSupabaseClient({
  required String url,
  required String serviceRoleKey,
}) {
  return SupabaseClient(url, serviceRoleKey);
}
