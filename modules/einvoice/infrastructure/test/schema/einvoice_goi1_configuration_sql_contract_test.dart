import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Einvoice refactor gói 1 (cấu hình).
/// Spec: docs/superpowers/specs/einvoice-schema-refactor/
void main() {
  final schemaSql = _readDraft('001_einvoice_configuration_schema.sql');

  group('Task 1 — bảng chết', () {
    test('no draft creates or uses the dead configuration tables', () {
      for (final draft in _allDrafts()) {
        final sql = draft.readAsStringSync();
        expect(
          sql,
          isNot(contains('einvoice.idempotency_records')),
          reason: draft.path,
        );
        expect(sql, isNot(contains('einvoice.audit_logs')), reason: draft.path);
      }
      expect(schemaSql, isNotEmpty);
    });
  });

  group('Task 2 — provider_connections', () {
    test('table keeps 7 columns and a tenant-scoped unique key', () {
      final table = _createTable(schemaSql, 'einvoice.provider_connections');
      expect(table, contains("status text not null default 'DISCONNECTED'"));
      expect(table, contains('capabilities_snapshot jsonb'));
      expect(table, contains('connection_version int not null default 1'));
      expect(table, contains('created_at timestamptz not null default now()'));
      expect(table, contains('unique (tenant_id, id)'));
      expect(table, isNot(contains('provider_code')));
      expect(table, isNot(contains('created_by')));
      expect(table, isNot(contains('updated_at')));
    });

    test('no postgres enum type survives in the einvoice schema', () {
      for (final draft in _allDrafts()) {
        expect(
          draft.readAsStringSync(),
          isNot(contains('create type einvoice.')),
          reason: draft.path,
        );
      }
    });

    test('every draft uses upper-case connection status literals', () {
      for (final draft in _allDrafts()) {
        final sql = draft.readAsStringSync();
        for (final legacy in const [
          "'disconnected'",
          "'connected'",
          "'checkRequired'",
          "'reconnectRequired'",
        ]) {
          expect(sql, isNot(contains(legacy)), reason: '${draft.path} $legacy');
        }
      }
    });

    test('connection updates drop updated_at and redundant ordering', () {
      final connectionSql = _readDraft(
        '003_einvoice_provider_connection_rpcs.sql',
      );
      expect(connectionSql, isNot(contains('order by pc.updated_at')));
      final issuanceSql = _readDraft(
        '008_einvoice_auto_issuance_and_retry_rpcs.sql',
      );
      expect(issuanceSql, isNot(contains('order by pc.created_at')));
      for (final name in const [
        'einvoice.issue_invoice',
        'einvoice.start_auto_issuance',
        'einvoice.reevaluate_auto_issuance',
        'einvoice.retry_issuance',
      ]) {
        expect(
          _lastFunctionBlock(issuanceSql, name),
          contains("    and pc.status = 'CONNECTED'\n  limit 1;"),
          reason: name,
        );
      }
    });

    test('connect_provider inserts without created_by', () {
      final connectionSql = _readDraft(
        '003_einvoice_provider_connection_rpcs.sql',
      );
      final body = _lastFunctionBlock(
        connectionSql,
        'einvoice.connect_provider',
      );
      expect(
        body,
        contains(
          'insert into einvoice.provider_connections (tenant_id, status)',
        ),
      );
      expect(body, contains("values (p_tenant_id, 'CHECK_REQUIRED')"));
    });
  });

  group('Task 3 — provider_credentials', () {
    test('table keeps 5 columns with a tenant-scoped foreign key', () {
      final table = _createTable(schemaSql, 'einvoice.provider_credentials');
      expect(table, contains('connection_id uuid primary key'));
      expect(table, contains('username text not null'));
      expect(table, contains('password_ciphertext bytea not null'));
      expect(table, contains('created_at timestamptz not null default now()'));
      expect(table, contains('foreign key (tenant_id, connection_id)'));
      expect(table, isNot(contains('tax_code')));
      expect(table, isNot(contains('updated_at')));
    });

    test('credential writes no longer touch updated_at', () {
      final connectionSql = _readDraft(
        '003_einvoice_provider_connection_rpcs.sql',
      );
      for (final name in const [
        'einvoice.connect_provider',
        'einvoice.reconnect_provider',
      ]) {
        expect(
          _lastFunctionBlock(connectionSql, name),
          isNot(contains('updated_at')),
          reason: name,
        );
      }
    });

    test(
      'disconnect deletes the stored credentials after the status change',
      () {
        final body = _lastFunctionBlock(
          _readDraft('003_einvoice_provider_connection_rpcs.sql'),
          'einvoice.disconnect_provider',
        );
        final notFound = body.indexOf("'NOT_FOUND: provider connection'");
        final deleted = body.indexOf(
          'delete from einvoice.provider_credentials\n'
          '  where connection_id = p_connection_id and tenant_id = p_tenant_id;',
        );
        final returns = body.lastIndexOf(
          "return query select p_connection_id, 'DISCONNECTED'::text;",
        );
        expect(notFound, greaterThan(0));
        expect(deleted, greaterThan(notFound));
        expect(returns, greaterThan(deleted));
      },
    );

    test(
      'disconnecting an already-disconnected connection touches nothing else',
      () {
        final body = _lastFunctionBlock(
          _readDraft('003_einvoice_provider_connection_rpcs.sql'),
          'einvoice.disconnect_provider',
        );
        // Only an active connection may move to DISCONNECTED; otherwise a stale
        // id (e.g. a tab opened before a reconnect) would wipe the settings of
        // the connection that is active now.
        expect(
          body,
          contains(
            "  where id = p_connection_id\n"
            "    and tenant_id = p_tenant_id\n"
            "    and status <> 'DISCONNECTED';",
          ),
        );
        final alreadyDisconnected = body.indexOf(
          "return query select p_connection_id, 'DISCONNECTED'::text;\n"
          '      return;',
        );
        final notFound = body.indexOf("'NOT_FOUND: provider connection'");
        final deleted = body.indexOf('delete from einvoice.provider_credentials');
        expect(alreadyDisconnected, greaterThan(0));
        expect(notFound, greaterThan(alreadyDisconnected));
        expect(deleted, greaterThan(notFound));
      },
    );

    test('worker credentials read takes tax code from the legal profile', () {
      final body = _lastFunctionBlock(
        _readDraft('003_einvoice_provider_connection_rpcs.sql'),
        'einvoice.read_provider_credentials',
      );
      expect(
        body,
        contains(
          'returns table(username text, password text, tax_code text, base_url text)',
        ),
      );
      expect(body, contains('lp.tax_code as tax_code,'));
      expect(body, isNot(contains('c.tax_code')));
    });
  });

  group('Task 4 — tenant_settings', () {
    test('one settings row per tenant with typed defaults', () {
      final table = _createTable(schemaSql, 'einvoice.tenant_settings');
      expect(table, contains('tenant_id uuid primary key'));
      expect(table, contains('default_template_id text'));
      expect(table, contains('default_invoice_series varchar(100)'));
      expect(table, contains('profile_version int not null default 0'));
      expect(
        table,
        contains('auto_issue_enabled boolean not null default false'),
      );
      expect(
        table,
        contains('auto_send_enabled boolean not null default false'),
      );
      expect(table, contains('policy_version int not null default 0'));
      expect(table, contains('updated_at timestamptz not null default now()'));
      expect(table, contains('created_at timestamptz not null default now()'));
      expect(table, isNot(contains('jsonb')));
    });

    test('old configuration tables are gone from every draft', () {
      for (final draft in _allDrafts()) {
        final sql = draft.readAsStringSync();
        expect(
          sql,
          isNot(contains('einvoice.issuance_profiles')),
          reason: draft.path,
        );
        expect(
          sql,
          isNot(contains('einvoice.invoice_automation_policies')),
          reason: draft.path,
        );
      }
    });

    test(
      'profile read keeps its four columns and derives the signing method',
      () {
        final body = _lastFunctionBlock(
          _readDraft('004_einvoice_profile_policy_readiness_rpcs.sql'),
          'einvoice.get_issuance_profile',
        );
        expect(body, contains('compatibility_warnings jsonb'));
        expect(body, contains("'[]'::jsonb"));
        expect(body, contains("substr(ts.default_invoice_series, 5, 1) = 'M'"));
        expect(body, contains("'sign-nosign'"));
        expect(body, contains("'sign-hsm'"));
      },
    );

    test('policy read and write no longer touch a blockers column', () {
      final configurationSql = _readDraft(
        '004_einvoice_profile_policy_readiness_rpcs.sql',
      );
      expect(configurationSql, isNot(contains('.blockers')));
      expect(
        _lastFunctionBlock(
          configurationSql,
          'einvoice.update_automation_policy',
        ),
        contains(
          "select v_auto_issue_enabled, v_auto_send_enabled, v_version, '[]'::jsonb;",
        ),
      );
    });

    test('readiness checks the configured template, not row existence', () {
      final body = _lastFunctionBlock(
        _readDraft('004_einvoice_profile_policy_readiness_rpcs.sql'),
        'einvoice.get_configuration_readiness',
      );
      expect(body, isNot(contains('ip.id is null')));
      expect(body, contains('ts.default_template_id is null'));
    });

    test('disconnect clears the default issuance configuration', () {
      final body = _lastFunctionBlock(
        _readDraft('003_einvoice_provider_connection_rpcs.sql'),
        'einvoice.disconnect_provider',
      );
      final deleted = body.indexOf('delete from einvoice.provider_credentials');
      final cleared = body.indexOf(
        'update einvoice.tenant_settings\n'
        '  set default_template_id = null,\n'
        '      default_invoice_series = null,\n'
        '      profile_version = profile_version + 1,\n'
        '      updated_at = now()\n'
        '  where tenant_id = p_tenant_id;',
      );
      expect(deleted, greaterThan(0));
      expect(cleared, greaterThan(deleted));
    });
  });
}

/// Thân `create table <qualifiedName> (` … `\n);` trong [sql].
String _createTable(String sql, String qualifiedName) {
  final start = sql.indexOf('create table if not exists $qualifiedName (');
  if (start < 0) {
    throw StateError('$qualifiedName not found');
  }
  return sql.substring(start, sql.indexOf('\n);', start));
}

/// `create or replace function <qualifiedName>(` … `$$;` cuối cùng trong [sql].
String _lastFunctionBlock(String sql, String qualifiedName) {
  final start = sql.lastIndexOf('create or replace function $qualifiedName(');
  if (start < 0) {
    throw StateError('$qualifiedName not found');
  }
  final end = sql.indexOf(r'$$;', start);
  return sql.substring(start, end + 3);
}

Iterable<File> _allDrafts() => Directory(
  '${_findRepoRoot().path}/supabase/migrations/_drafts',
).listSync().whereType<File>().where((f) => f.path.endsWith('.sql'));

String _readDraft(String fileName) => File(
  '${_findRepoRoot().path}/supabase/migrations/_drafts/$fileName',
).readAsStringSync();

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
