import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — IAM refactor bảng 2 `iam.tenant_legal_profiles`
/// (docs/superpowers/specs/iam-schema-refactor/02-tenant-legal-profiles.md).
void main() {
  group('legal profile DDL', () {
    test('both create table statements carry the 10-13 digit tax code check', () {
      for (final file in const [
        '20260811006_iam_create_tenant_onboarding.sql',
        '20260811015_iam_tenant_profile_legal.sql',
      ]) {
        final sql = _readMigration(file);
        final start = sql.indexOf(
          'create table if not exists iam.tenant_legal_profiles (',
        );
        final table = sql.substring(start, sql.indexOf('\n);', start));
        expect(
          table,
          contains(
            "constraint tenant_legal_profiles_tax_code_format_chk\n"
            "    check (tax_code ~ '^[0-9]{10,13}\$')",
          ),
          reason: file,
        );
      }
    });
  });

  group('legal profile rpcs (final definitions)', () {
    final upsertSql = _readMigration(
      '20260826002_iam_tenant_audit_history_v2_payloads.sql',
    );
    final onboardingSql = _readMigration(
      '20260916004_iam_patch_onboarding_default_store_scope.sql',
    );

    test('upsert normalizes tax code and validates format', () {
      final body = _lastFunctionBlock(upsertSql, 'iam.upsert_legal_profile');
      expect(
        body,
        contains(
          r"v_tax_code text := regexp_replace(coalesce(p_tax_code, ''), '\D', '', 'g');",
        ),
      );
      expect(body, contains(r"if v_tax_code !~ '^[0-9]{10,13}$' then"));
      expect(body, contains('where lp.tax_code = v_tax_code'));
      expect(body, contains('    v_tax_code,\n'));
      expect(body, isNot(contains('    p_tax_code,\n')));
    });

    test('onboarding drops 18-arg signature before creating 19-arg and grants it', () {
      final drop = onboardingSql.indexOf(
        'drop function if exists iam.create_tenant_onboarding(\n'
        '  uuid, text, text, text, boolean, text, text, text, text, text, text, text, text, text, text, text, text, text\n'
        ');',
      );
      final create = onboardingSql.indexOf(
        'create or replace function iam.create_tenant_onboarding(',
      );
      expect(drop, isNonNegative);
      expect(create, greaterThan(drop));
      expect(
        onboardingSql,
        contains(
          'grant execute on function iam.create_tenant_onboarding(\n'
          '  uuid, text, text, text, boolean, text, text, text, text, text, text, text, text, text, text, text, text, text, text\n'
          ') to authenticated;',
        ),
      );
    });

    test('onboarding takes legal entity type, normalizes tax code, nulls legal province/commune', () {
      final body = _lastFunctionBlock(
        onboardingSql,
        'iam.create_tenant_onboarding',
      );
      expect(body, contains('p_org_legal_entity_type text default null'));
      expect(body, contains("not in ('HOUSEHOLD_BUSINESS', 'ENTERPRISE')"));
      expect(body, isNot(contains("then 'HOUSEHOLD_BUSINESS'")));
      expect(
        body,
        contains(
          r"nullif(regexp_replace(coalesce(p_org_tax_code, ''), '\D', '', 'g'), '')",
        ),
      );
      expect(
        body,
        contains('      v_org_registered_address_text,\n      null,\n      null,'),
      );
    });
  });
}

String _readMigration(String fileName) {
  final root = _findRepoRoot();
  return File('${root.path}/supabase/migrations/$fileName').readAsStringSync();
}

/// Last `create or replace function <qualifiedName>(` … `$$;` in [sql].
String _lastFunctionBlock(String sql, String qualifiedName) {
  final start = sql.lastIndexOf('create or replace function $qualifiedName(');
  if (start < 0) {
    throw StateError('$qualifiedName not found');
  }
  final end = sql.indexOf(r'$$;', start);
  return sql.substring(start, end + 3);
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
