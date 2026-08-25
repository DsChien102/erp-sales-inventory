import 'dart:io';

import 'package:test/test.dart';

void main() {
  final root = _findRepoRoot();

  test('tenant and platform apps identify their audit source', () {
    final tenantMain = File('${root.path}/apps/erp/lib/main.dart').readAsStringSync();
    final platformMain = File('${root.path}/apps/admin/lib/main.dart').readAsStringSync();

    expect(
      tenantMain,
      contains("headers: const {'X-Vet45-App': 'tenant_app'}"),
    );
    expect(
      platformMain,
      contains("headers: const {'X-Vet45-App': 'platform_admin_app'}"),
    );
  });

  test('audit writer accepts only the two known client app sources', () {
    final sql = File(
      '${root.path}/supabase/migrations/_drafts/007_iam_audit_logs_v2_rebuild.sql',
    ).readAsStringSync();

    expect(sql, contains("current_setting('request.headers', true)"));
    expect(sql, contains("'x-vet45-app'"));
    expect(
      sql,
      contains("v_request_source in ('tenant_app', 'platform_admin_app')"),
    );
    expect(sql, contains('else p_source'));
  });
}

Directory _findRepoRoot() {
  var current = Directory.current.absolute;
  while (!Directory('${current.path}/supabase/migrations').existsSync()) {
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not locate Vet45 workspace root');
    }
    current = parent;
  }
  return current;
}
