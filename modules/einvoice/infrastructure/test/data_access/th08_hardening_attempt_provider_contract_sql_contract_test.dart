import 'dart:io';

import 'package:test/test.dart';

Directory _repoRoot() {
  var dir = Directory.current;
  while (!Directory('${dir.path}/supabase/migrations/_drafts').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return dir;
}

String _read(String name) => File(
  '${_repoRoot().path}/supabase/migrations/_drafts/$name',
).readAsStringSync();

String _function(String sql, String prefix) {
  final start = sql.indexOf(prefix);
  expect(start, greaterThanOrEqualTo(0), reason: 'missing $prefix');
  final end = sql.indexOf('\n\$\$;', start);
  expect(end, greaterThan(start));
  return sql.substring(start, end + 4);
}

void main() {
  late String draft007;
  late String draft008;
  late String issue007;
  late String start008;

  setUpAll(() {
    draft007 = _read('007_einvoice_issuance_schema_and_publish_rpcs.sql');
    draft008 = _read('008_einvoice_auto_issuance_and_retry_rpcs.sql');
    issue007 = _function(
      draft007,
      'create or replace function einvoice.issue_invoice(',
    );
    start008 = _function(
      draft008,
      'create or replace function einvoice._start_issuance_attempt(',
    );
  });

  group('th08_hardening_attempt_provider_contract', () {
    test('draft 007 owns required typed provider contract columns', () {
      expect(draft007, contains('invoice_series varchar(100) not null'));
      expect(draft007, contains('invoice_with_code boolean not null'));
      expect(draft007, contains('is_invoice_summary boolean not null'));
      expect(
        draft007,
        contains('sign_type smallint not null check (sign_type in (2, 5))'),
      );
      expect(draft007, contains("invoice_series ~ '^[1256][CK].{2}[TM]'"));
      expect(draft007, contains('invoice_with_code ='));
      expect(draft007, contains('sign_type = case'));
    });

    test('clean rebuild has no compatibility repair alters', () {
      expect(
        draft007,
        isNot(contains('add column if not exists invoice_series')),
      );
      expect(
        draft008,
        isNot(contains('add column if not exists provider_result_snapshot')),
      );
    });

    test('manual issue resolves the configured tenant profile', () {
      expect(issue007, isNot(contains('ip.is_active')));
      expect(issue007, isNot(contains('ip.created_at')));
      expect(issue007, contains('ip.default_template is not null'));
      expect(issue007, contains('ip.default_signing is not null'));
    });

    for (final entry in <(String, String)>[
      ('draft 007 manual issue', 'issue007'),
      ('draft 008 shared start helper', 'start008'),
    ]) {
      test('${entry.$1} validates and freezes all provider fields', () {
        final fn = entry.$2 == 'issue007' ? issue007 : start008;
        expect(fn, contains("v_canonical_jsonb ->> 'invSeries'"));
        expect(
          fn,
          contains("jsonb_typeof(v_canonical_jsonb -> 'invoiceWithCode')"),
        );
        expect(
          fn,
          contains("jsonb_typeof(v_canonical_jsonb -> 'isInvoiceSummary')"),
        );
        expect(fn, contains("jsonb_typeof(v_canonical_jsonb -> 'signType')"));
        expect(fn, contains("'provider_contract', jsonb_build_object("));
        expect(fn, contains("'invoice_series', v_invoice_series"));
        expect(fn, contains("'invoice_with_code', v_invoice_with_code"));
        expect(fn, contains("'is_invoice_summary', v_is_invoice_summary"));
        expect(fn, contains("'sign_type', v_sign_type"));
        expect(fn, contains('invoice_series,'));
        expect(fn, contains('invoice_with_code,'));
        expect(fn, contains('is_invoice_summary,'));
        expect(fn, contains('sign_type,'));
      });
    }

    test('all draft 008 entry points delegate to the shared helper', () {
      expect(
        RegExp(
          r'einvoice\._start_issuance_attempt\(',
        ).allMatches(draft008).length,
        6,
        reason:
            'definition + revoke signature + manual/auto/reevaluation/retry callers',
      );
    });

    test('PL/pgSQL IF guards parenthesize nested CASE expressions', () {
      final parenthesizedCase = RegExp(
        r'is distinct from\s*\(\s*case\s+when',
        caseSensitive: false,
      );

      expect(
        issue007,
        matches(parenthesizedCase),
        reason:
            'Without parentheses, PL/pgSQL can consume the CASE WHEN THEN '
            'token as the IF delimiter and report syntax error at end of input.',
      );
      expect(start008, matches(parenthesizedCase));
    });
  });
}
