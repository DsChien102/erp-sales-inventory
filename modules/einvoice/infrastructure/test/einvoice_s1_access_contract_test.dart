import 'dart:io';

import 'package:test/test.dart';

Directory _repoRoot() {
  var dir = Directory.current;
  while (!File('${dir.path}/theme8.sql').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('Cannot locate repository root');
    }
    dir = parent;
  }
  return dir;
}

String _read(Directory root, String path) =>
    File('${root.path}/$path').readAsStringSync();

void _expectUserRpcGuard(String sql, String functionName) {
  final function = RegExp(
    'create or replace function einvoice\\.${RegExp.escape(functionName)}\\('
    r'[\s\S]*?\n\$\$;',
    caseSensitive: false,
  ).firstMatch(sql)?.group(0);

  expect(function, isNotNull, reason: '$functionName must exist');
  expect(function, contains('p_actor_id <> auth.uid()'));
  expect(
    function,
    contains(
      "iam.has_permission(p_tenant_id, 'einvoice.manage_configuration')",
    ),
  );
}

void main() {
  late String schemaSql;
  late String installerSql;
  late String connectionSql;
  late String configurationSql;
  late String previewSql;
  late String bundleSql;

  setUpAll(() {
    final root = _repoRoot();
    schemaSql = _read(
      root,
      'supabase/migrations/_drafts/001_einvoice_configuration_schema.sql',
    );
    installerSql = _read(
      root,
      'supabase/migrations/_drafts/002_einvoice_install_module_messaging.sql',
    );
    connectionSql = _read(
      root,
      'supabase/migrations/_drafts/003_einvoice_provider_connection_rpcs.sql',
    );
    configurationSql = _read(
      root,
      'supabase/migrations/_drafts/004_einvoice_profile_policy_readiness_rpcs.sql',
    );
    previewSql = _read(
      root,
      'supabase/migrations/_drafts/006_einvoice_buyer_completion_and_preview_rpcs.sql',
    );
    bundleSql = _read(root, 'theme8.sql');
  });

  test('authenticated receives schema usage but not messaging worker RPCs', () {
    expect(installerSql, contains('grant usage on schema %I to authenticated'));
    expect(
      installerSql,
      isNot(
        contains(
          'claim_internal_commands_batch(uuid, int)\n    to authenticated',
        ),
      ),
    );
    expect(
      installerSql,
      matches(
        RegExp(
          r'grant execute on function[\s\S]*claim_internal_commands_batch\(uuid, int\)[\s\S]*to service_role',
        ),
      ),
    );
    expect(
      installerSql,
      contains(
        'revoke execute on all functions in schema einvoice from public, anon',
      ),
    );
    expect(
      installerSql,
      isNot(
        contains(
          'revoke execute on all functions in schema %I from public, anon, authenticated',
        ),
      ),
    );
    expect(
      schemaSql,
      contains(
        'alter default privileges in schema einvoice revoke execute on functions from public, anon, authenticated',
      ),
    );
  });

  test('credential helpers are not directly executable by API roles', () {
    for (final signature in <String>[
      'einvoice._credential_encryption_key()',
      'einvoice._encrypt_credential(text)',
      'einvoice._decrypt_credential(bytea)',
    ]) {
      expect(
        schemaSql,
        contains(
          'revoke all on function $signature from public, anon, authenticated',
        ),
      );
    }
  });

  test(
    'credential helpers resolve pgcrypto from Supabase extensions schema',
    () {
      expect(
        schemaSql,
        contains(
          'create extension if not exists pgcrypto with schema extensions',
        ),
      );
      expect(
        schemaSql,
        contains('extensions.pgp_sym_encrypt(p_plaintext, v_key)'),
      );
      expect(
        schemaSql,
        contains('extensions.pgp_sym_decrypt(p_ciphertext, v_key)'),
      );
    },
  );

  test('connection user RPCs bind actor and permission to auth context', () {
    for (final functionName in <String>[
      'connect_provider',
      'get_provider_connection_screen',
      'verify_provider_connection',
      'reconnect_provider',
      'disconnect_provider',
    ]) {
      _expectUserRpcGuard(connectionSql, functionName);
    }
  });

  test('configuration user RPCs bind actor and permission to auth context', () {
    for (final functionName in <String>[
      'get_issuance_profile',
      'set_default_issuance_configuration',
      'get_automation_policy',
      'update_automation_policy',
      'get_configuration_readiness',
      'list_provider_templates',
    ]) {
      _expectUserRpcGuard(configurationSql, functionName);
    }
  });

  test('connection grants separate authenticated and service-role surfaces', () {
    expect(
      connectionSql,
      contains(
        'grant execute on function einvoice.get_provider_connection_screen(uuid, uuid) to authenticated',
      ),
    );
    expect(
      connectionSql,
      contains(
        'grant execute on function einvoice.record_connection_verified(uuid, uuid, integer, text, jsonb, timestamptz, text) to service_role',
      ),
    );
    expect(
      connectionSql,
      isNot(
        contains(
          'record_connection_verified(uuid, uuid, integer, text, jsonb, timestamptz, text) to authenticated',
        ),
      ),
    );
    expect(
      connectionSql,
      contains(
        'grant execute on function einvoice.read_provider_credentials(uuid) to service_role',
      ),
    );
  });

  test('worker RPC guards read the current PostgREST JWT claims object', () {
    for (final sql in <String>[connectionSql, previewSql]) {
      expect(sql, contains("current_setting('request.jwt.claims', true)"));
    }
    expect(
      RegExp(
        r"current_setting\('request\.jwt\.claims', true\)",
      ).allMatches(connectionSql),
      hasLength(2),
    );
    expect(
      RegExp(
        r"current_setting\('request\.jwt\.claims', true\)",
      ).allMatches(bundleSql),
      hasLength(greaterThanOrEqualTo(3)),
    );
  });

  test('worker verification is compare-and-set against queued version', () {
    final recordFunction = RegExp(
      r'create or replace function einvoice\.record_connection_verified\([\s\S]*?\n\$\$;',
      caseSensitive: false,
    ).firstMatch(connectionSql)?.group(0);
    expect(recordFunction, isNotNull);
    expect(
      RegExp('expected_connection_version').allMatches(connectionSql),
      hasLength(greaterThanOrEqualTo(7)),
    );
    expect(recordFunction, contains("pc.status = 'checkRequired'"));
    expect(
      recordFunction,
      contains('pc.connection_version = p_expected_connection_version'),
    );
    expect(
      RegExp(
        r'update einvoice\.provider_connections pc',
      ).allMatches(recordFunction!).length,
      1,
    );
    expect(connectionSql, contains("'expected_connection_version', v_version"));
  });

  test(
    'connect credential upsert does not collide with output connection_id',
    () {
      final connectFunction = RegExp(
        r'create or replace function einvoice\.connect_provider\([\s\S]*?\n\$\$;',
        caseSensitive: false,
      ).firstMatch(connectionSql)?.group(0);

      expect(connectFunction, isNotNull);
      expect(
        connectFunction,
        contains(
          'on conflict on constraint provider_credentials_pkey do update',
        ),
      );
      expect(connectFunction, isNot(contains('on conflict (connection_id)')));
    },
  );

  test('reconnect qualifies credential columns against output parameters', () {
    for (final sql in <String>[connectionSql, bundleSql]) {
      final reconnectFunction = RegExp(
        r'create or replace function einvoice\.reconnect_provider\([\s\S]*?\n\$\$;',
        caseSensitive: false,
      ).firstMatch(sql)?.group(0);

      expect(reconnectFunction, isNotNull);
      expect(
        reconnectFunction,
        contains('update einvoice.provider_credentials as credentials'),
      );
      expect(
        reconnectFunction,
        contains(
          'where credentials.connection_id = p_connection_id\n'
          '    and credentials.tenant_id = p_tenant_id',
        ),
      );
      expect(
        reconnectFunction,
        isNot(contains('where connection_id = p_connection_id')),
      );
    }
  });

  test('disconnect handles a missing connection exactly once', () {
    final disconnectFunction = RegExp(
      r'create or replace function einvoice\.disconnect_provider\([\s\S]*?\n\$\$;',
      caseSensitive: false,
    ).firstMatch(connectionSql)?.group(0);

    expect(disconnectFunction, isNotNull);
    expect(
      RegExp(
        "raise exception 'NOT_FOUND: provider connection'",
      ).allMatches(disconnectFunction!).length,
      1,
    );
  });

  test('profile and policy mutations qualify insert target returns', () {
    expect(
      configurationSql,
      contains('returning ip.profile_version into v_version'),
    );
    expect(configurationSql, contains('returning iap.policy_version,'));
    expect(configurationSql, contains('iap.auto_issue_enabled,'));
    expect(configurationSql, contains('iap.auto_send_enabled,'));
    expect(configurationSql, contains('iap.blockers'));
  });

  test('theme8 bundle carries the same S1 access contract', () {
    expect(bundleSql, contains('grant usage on schema %I to authenticated'));
    expect(
      RegExp(
        "iam\\.has_permission\\(p_tenant_id, 'einvoice\\.manage_configuration'\\)",
      ).allMatches(bundleSql),
      hasLength(greaterThanOrEqualTo(11)),
    );
    expect(
      bundleSql,
      contains(
        'grant execute on function einvoice.record_connection_verified(uuid, uuid, integer, text, jsonb, timestamptz, text) to service_role',
      ),
    );
  });
}
