import 'package:erp/core/supabase/supabase_module.dart';
import 'package:supabase/supabase.dart';

SupabaseModule fakeSupabaseModule() {
  return SupabaseModule(
    SupabaseClient('http://localhost', 'fake-key'),
  );
}
