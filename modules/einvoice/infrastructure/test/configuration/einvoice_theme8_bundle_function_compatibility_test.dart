import 'dart:io';

import 'package:test/test.dart';

Directory _repoRoot() {
  var dir = Directory.current;
  while (!File('${dir.path}/pubspec.yaml').existsSync() ||
      !Directory('${dir.path}/packages/vet45_shared').existsSync() ||
      !Directory('${dir.path}/supabase/migrations').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError(
        'Cannot locate repository root (expected pubspec.yaml, packages/vet45_shared, and supabase/migrations)',
      );
    }
    dir = parent;
  }
  return dir;
}

const _draftManifest = [
  '001_einvoice_configuration_schema.sql',
  '002_einvoice_install_module_messaging.sql',
  '003_einvoice_provider_connection_rpcs.sql',
  '004_einvoice_profile_policy_readiness_rpcs.sql',
  '005_einvoice_buyer_completion_and_preview_schema.sql',
  '018_sales_einvoice_source_contract.sql',
  '006_einvoice_buyer_completion_and_preview_rpcs.sql',
  '007_einvoice_issuance_schema_and_publish_rpcs.sql',
  '008_einvoice_auto_issuance_and_retry_rpcs.sql',
  '009_einvoice_issuance_reconciliation_rpcs.sql',
  '010_einvoice_official_view_rpcs.sql',
  '011_einvoice_document_operations_rpcs.sql',
  '012_einvoice_provider_observations_rpcs.sql',
  '013_einvoice_delivery_schema_and_start_rpcs.sql',
  '014_einvoice_delivery_results_and_projection_rpcs.sql',
  '015_einvoice_delivery_reconciliation_rpcs.sql',
  '016_partner_einvoice_recipient_snapshot.sql',
];

Iterable<String> _claimFunctionReturnRows(String sql) {
  final pattern = RegExp(
    r'create or replace function (?:%I|einvoice)\.claim_internal_commands_batch\('
    r'\s*p_tenant_id uuid,\s*p_limit int default 10\s*\)\s*'
    r'returns table\s*\(([\s\S]*?)\)\s*language plpgsql',
    caseSensitive: false,
  );
  return pattern.allMatches(sql).map((match) => match.group(1)!);
}

String _extractCreateTable(String sql, String tableName) {
  final match = RegExp(
    'create table if not exists einvoice\\.$tableName \\(([\\s\\S]*?)\\n\\);',
    caseSensitive: false,
  ).firstMatch(sql);
  if (match == null) {
    throw StateError('Missing table definition: einvoice.$tableName');
  }
  return match.group(1)!;
}

String _extractFunction(String sql, String functionName) {
  final match = RegExp(
    'create or replace function einvoice\\.${RegExp.escape(functionName)}'
    r'\([\s\S]*?\n\$\$;',
    caseSensitive: false,
  ).firstMatch(sql);
  if (match == null) {
    throw StateError('Missing function: einvoice.$functionName');
  }
  return match.group(0)!;
}

Set<String> _declaredColumns(String createTableSql) => RegExp(
  r'^  ([a-z_][a-z0-9_]*)\s+(?:uuid|text|varchar|integer|bigint|timestamptz|jsonb|boolean)\b',
  caseSensitive: false,
  multiLine: true,
).allMatches(createTableSql).map((match) => match.group(1)!).toSet();

Set<String> _addedColumns(String sql, String tableName) => RegExp(
  'alter table einvoice\\.$tableName[\\s\\S]*?add column if not exists '
  r'([a-z_][a-z0-9_]*)\b',
  caseSensitive: false,
).allMatches(sql).map((match) => match.group(1)!).toSet();

Set<String> _rowReferences(String sql, Iterable<String> aliases) {
  final aliasPattern = aliases.map(RegExp.escape).join('|');
  return RegExp(
    '(?:$aliasPattern)\\.([a-z_][a-z0-9_]*)',
    caseSensitive: false,
  ).allMatches(sql).map((match) => match.group(1)!).toSet();
}

Set<String> _insertColumns(String sql, String tableName) {
  final match = RegExp(
    'insert into einvoice\\.$tableName \\(([\\s\\S]*?)\\n  \\) values',
    caseSensitive: false,
  ).firstMatch(sql);
  if (match == null) {
    throw StateError('Missing insert into einvoice.$tableName');
  }
  return match
      .group(1)!
      .split(',')
      .map((column) => column.trim())
      .where((column) => column.isNotEmpty)
      .toSet();
}

Set<String> _requiredInsertColumns(String createTableSql) => RegExp(
  r'^  ([a-z_][a-z0-9_]*)\s+[^\n]*\bnot null\b(?![^\n]*\bdefault\b)',
  caseSensitive: false,
  multiLine: true,
).allMatches(createTableSql).map((match) => match.group(1)!).toSet();

void main() {
  late Directory tempDir;
  late String installerSql;
  late String bundleSql;
  late String s2bSql;
  late String s3bSql;

  setUpAll(() {
    final root = _repoRoot();
    installerSql = File(
      '${root.path}/supabase/migrations/_drafts/'
      '002_einvoice_install_module_messaging.sql',
    ).readAsStringSync();
    s2bSql = File(
      '${root.path}/supabase/migrations/_drafts/'
      '007_einvoice_issuance_schema_and_publish_rpcs.sql',
    ).readAsStringSync();
    s3bSql = File(
      '${root.path}/supabase/migrations/_drafts/'
      '009_einvoice_issuance_reconciliation_rpcs.sql',
    ).readAsStringSync();

    tempDir = Directory.systemTemp.createTempSync('theme8_test_bundle_');
    final tempBundleFile = File('${tempDir.path}/theme8.sql');
    final buffer = StringBuffer();
    for (final draft in _draftManifest) {
      final file = File('${root.path}/supabase/migrations/_drafts/$draft');
      buffer.writeln(file.readAsStringSync());
    }
    tempBundleFile.writeAsStringSync(buffer.toString());
    bundleSql = tempBundleFile.readAsStringSync();
  });

  tearDownAll(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test(
    'installer recreates the claim RPC before applying its final row type',
    () {
      expect(
        installerSql,
        contains(
          'drop function if exists %I.claim_internal_commands_batch(uuid, integer)',
        ),
      );
    },
  );

  test(
    'every bundled claim RPC definition keeps the seven-column contract',
    () {
      final returnRows = _claimFunctionReturnRows(bundleSql).toList();

      expect(returnRows, hasLength(3));
      for (final row in returnRows) {
        expect(row, contains('retry_count int'));
      }
    },
  );

  test('theme8 bundle embeds the repaired S2b and S3b drafts', () {
    expect(bundleSql, contains(s2bSql.trim()));
    expect(bundleSql, contains(s3bSql.trim()));
  });

  test('S3b rowtype references exist in the schema assembled from S2b', () {
    final attemptColumns = _declaredColumns(
      _extractCreateTable(s2bSql, 'issuance_attempts'),
    );
    final reconciliationColumns = {
      ..._declaredColumns(
        _extractCreateTable(s2bSql, 'invoice_reconciliation_cases'),
      ),
      ..._addedColumns(s3bSql, 'invoice_reconciliation_cases'),
    };
    final reconciliationRowtypeSql = [
      'claim_issuance_reconciliation_case',
      'record_reconciliation_pending',
      'resolve_reconciliation_case',
      'recover_internal_finalization',
      'get_issuance_attempt_status',
    ].map((name) => _extractFunction(s3bSql, name)).join('\n');

    expect(
      _rowReferences(s3bSql, const [
        'v_attempt',
        'ia',
      ]).difference(attemptColumns),
      isEmpty,
      reason: 'S3b must not reference stale issuance_attempts columns',
    );
    expect(
      _rowReferences(reconciliationRowtypeSql, const [
        'v_case',
        'irc',
      ]).difference(reconciliationColumns),
      isEmpty,
      reason: 'S3b must declare every reconciliation rowtype column it uses',
    );
  });

  test('recovery uses the canonical ElectronicInvoice schema completely', () {
    final tableSql = _extractCreateTable(s2bSql, 'electronic_invoices');
    final tableColumns = _declaredColumns(tableSql);
    final recoverySql = _extractFunction(
      s3bSql,
      'recover_internal_finalization',
    );
    final referencedColumns = _rowReferences(recoverySql, const [
      'v_existing_invoice',
      'ei',
    ]);
    final insertedColumns = _insertColumns(recoverySql, 'electronic_invoices');

    expect(
      referencedColumns.difference(tableColumns),
      isEmpty,
      reason: 'Recovery must only read canonical ElectronicInvoice columns',
    );
    expect(
      insertedColumns.difference(tableColumns),
      isEmpty,
      reason: 'Recovery must only insert canonical ElectronicInvoice columns',
    );
    expect(
      _requiredInsertColumns(tableSql).difference(insertedColumns),
      isEmpty,
      reason: 'Recovery must populate every required ElectronicInvoice field',
    );
  });

  test('S3b recovery emits the canonical invoice registration event', () {
    final recoverySql = _extractFunction(
      s3bSql,
      'recover_internal_finalization',
    );

    expect(recoverySql, contains("'einvoice.electronic_invoice.registered'"));
    expect(recoverySql, contains('einvoice.enqueue_outbox_message('));
  });

  test('S3b recovery never fabricates legal invoice identity', () {
    final recoverySql = _extractFunction(
      s3bSql,
      'recover_internal_finalization',
    );

    expect(recoverySql, isNot(contains("'RECOVERED-'")));
    expect(recoverySql, isNot(contains("'REC'")));
    expect(
      recoverySql,
      contains('STATE_INVALID: complete success evidence is required'),
    );
    expect(
      recoverySql,
      contains("nullif(trim(v_case.terminal_evidence->>'invoice_number'), '')"),
      reason: 'UNRESOLVED reason evidence must not hide later success evidence',
    );
    expect(recoverySql, contains('terminal_evidence = v_success_evidence'));
  });

  test(
    'S2b preserves provider success evidence when local finalization fails',
    () {
      final attemptTableSql = _extractCreateTable(s2bSql, 'issuance_attempts');
      final recordSuccessSql = _extractFunction(
        s2bSql,
        'record_issuance_success',
      );

      expect(attemptTableSql, contains('provider_result_snapshot jsonb null'));
      expect(
        recordSuccessSql,
        contains('provider_result_snapshot = jsonb_build_object('),
      );
      expect(recordSuccessSql, contains("'invoice_series', p_invoice_series"));
      expect(recordSuccessSql, contains("'issued_at', p_issued_at"));
      expect(
        recordSuccessSql,
        contains('update einvoice.invoice_reconciliation_cases'),
      );
      expect(recordSuccessSql, contains("resolution_code = 'SUCCESS'"));
    },
  );

  test('S3b only resolves success with complete provider evidence', () {
    final resolveSql = _extractFunction(s3bSql, 'resolve_reconciliation_case');

    for (final key in const [
      'provider_reference',
      'invoice_number',
      'invoice_series',
      'issued_at',
    ]) {
      expect(resolveSql, contains("p_evidence->>'$key'"));
    }
    expect(
      resolveSql,
      contains('INVALID_EVIDENCE: incomplete success evidence'),
    );
  });

  test('S3b starts reconciliation on the frozen first 30-second delay', () {
    final openCaseSql = _extractFunction(s3bSql, 'open_reconciliation_case');
    final recordUndeterminedSql = _extractFunction(
      s3bSql,
      'record_issuance_undetermined',
    );

    expect(openCaseSql, contains("interval '30 seconds'"));
    expect(recordUndeterminedSql, contains("interval '30 seconds'"));
  });

  test('S3b reports the persisted internal finalization state', () {
    final statusSql = _extractFunction(s3bSql, 'get_issuance_attempt_status');

    expect(statusSql, contains('lower(v_attempt.internal_finalization_state)'));
  });
}
