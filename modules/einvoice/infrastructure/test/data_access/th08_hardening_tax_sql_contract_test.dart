import 'dart:io';

import 'package:test/test.dart';

Directory _repoRoot() {
  var dir = Directory.current;
  while (!Directory('${dir.path}/supabase/migrations/_drafts').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      break;
    }
    dir = parent;
  }
  return dir;
}

String _extractFunction(String sql, String signaturePrefix) {
  final start = sql.indexOf(signaturePrefix);
  if (start < 0) {
    return '';
  }
  final revoke = sql.indexOf('revoke all on function', start);
  final nextCreate = sql.indexOf(
    '\ncreate or replace function',
    start + signaturePrefix.length,
  );
  final endCandidates = [
    if (revoke > start) revoke,
    if (nextCreate > start) nextCreate,
    sql.length,
  ]..sort();
  return sql.substring(start, endCandidates.first);
}

void main() {
  late String draft006;

  setUpAll(() {
    final root = _repoRoot();
    draft006 = File(
      '${root.path}/supabase/migrations/_drafts/'
      '006_einvoice_buyer_completion_and_preview_rpcs.sql',
    ).readAsStringSync();
  });

  group('th08_hardening_tax — KCT-only invariant at canonical boundary', () {
    late String canonicalFn;

    setUp(() {
      canonicalFn = _extractFunction(
        draft006,
        'create or replace function einvoice.build_canonical_invoice(',
      );
      expect(canonicalFn.isNotEmpty, isTrue);
    });

    test('happy path keeps KCT hard-code only in build_canonical_invoice', () {
      expect(canonicalFn, contains("'vatRateName', 'KCT'"));
      expect(canonicalFn, contains("'taxRateInfo', v_tax_rates"));
      expect(canonicalFn, contains('ADR-TH08-KCT'));
    });

    test('validates line taxAmountMinor before applying KCT', () {
      expect(
        canonicalFn,
        contains(
          "jsonb_typeof(ln -> 'taxAmountMinor') is distinct from 'number'",
        ),
      );
      expect(canonicalFn, contains("ln -> 'taxAmountMinor' <> '0'::jsonb"));
      expect(
        canonicalFn,
        isNot(contains("(ln ->> 'taxAmountMinor')::numeric")),
        reason: 'malformed tax JSON must map to the stable blocker, not cast',
      );
      expect(canonicalFn, contains('UNSUPPORTED_TAX_DATA'));
    });

    test('validates totals taxMinor before applying KCT', () {
      expect(
        canonicalFn,
        contains(
          "jsonb_typeof(v_totals -> 'taxMinor') is distinct from 'number'",
        ),
      );
      expect(canonicalFn, contains("v_totals -> 'taxMinor' <> '0'::jsonb"));
      expect(
        canonicalFn,
        isNot(contains("(v_totals ->> 'taxMinor')::numeric")),
        reason: 'missing or malformed totals tax must fail without a cast',
      );
      expect(canonicalFn, contains("'code', 'UNSUPPORTED_TAX_DATA'"));
    });

    test('blocks non-empty taxSnapshot before applying KCT', () {
      expect(canonicalFn, contains("ln ? 'taxSnapshot'"));
      expect(
        canonicalFn,
        contains("ln -> 'taxSnapshot' not in ('null'::jsonb, '{}'::jsonb)"),
      );
    });

    test('ADR documents BA approval and change control, not auto-removal', () {
      expect(canonicalFn, contains('16/09/2026'));
      expect(canonicalFn, contains('Change control'));
      expect(canonicalFn, isNot(contains('GỠ BỎ KHI')));
      expect(canonicalFn, isNot(contains('tripwire')));
    });

    test('KCT totals remain zeroed under policy', () {
      expect(canonicalFn, contains("'totalVatAmount',      0"));
      expect(canonicalFn, contains("'vatAmount',        0"));
    });
  });
}
