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
  late String draft004;
  late String draft006;
  late String draft007;
  late String draft008;

  setUpAll(() {
    final root = _repoRoot();
    draft004 = File(
      '${root.path}/supabase/migrations/_drafts/'
      '004_einvoice_profile_policy_readiness_rpcs.sql',
    ).readAsStringSync();
    draft006 = File(
      '${root.path}/supabase/migrations/_drafts/'
      '006_einvoice_buyer_completion_and_preview_rpcs.sql',
    ).readAsStringSync();
    draft007 = File(
      '${root.path}/supabase/migrations/_drafts/'
      '007_einvoice_issuance_schema_and_publish_rpcs.sql',
    ).readAsStringSync();
    draft008 = File(
      '${root.path}/supabase/migrations/_drafts/'
      '008_einvoice_auto_issuance_and_retry_rpcs.sql',
    ).readAsStringSync();
  });

  group('th08_hardening_resolve — SQL no fabricated template/series', () {
    test('list_provider_templates does not fabricate tpl-default', () {
      final fn = _extractFunction(
        draft004,
        'create or replace function einvoice.list_provider_templates(',
      );
      expect(fn, isNot(contains("'tpl-default'")));
      expect(fn, isNot(contains("'Default template'")));
    });

    test('set_default validates template against capability', () {
      final fn = _extractFunction(
        draft004,
        'create or replace function einvoice.set_default_issuance_configuration(',
      );
      expect(fn, contains('TEMPLATE_NOT_AVAILABLE'));
      expect(fn, contains('SIGNING_CONFIGURATION_NOT_AVAILABLE'));
      expect(fn, contains('invoice_series'));
      expect(fn, contains('sign_type'));
    });

    test(
      'build_canonical_invoice does not fallback to 1C26TAA or first template',
      () {
        final fn = _extractFunction(
          draft006,
          'create or replace function einvoice.build_canonical_invoice(',
        );
        expect(fn, isNot(contains("'1C26TAA'")));
        expect(fn, contains('TEMPLATE_NOT_AVAILABLE'));
        expect(
          fn,
          contains('v_sign_type := case when v_is_mtt then 5 else 2 end;'),
        );
        expect(fn, contains("'signType'"));
        expect(fn, contains("'invoiceWithCode'"));
        expect(fn, contains("'isInvoiceSummary'"));
        expect(fn, contains("'code', 'TEMPLATE_NOT_AVAILABLE'"));
        expect(fn, isNot(contains("v_inv_series := '1C26TAA'")));
      },
    );

    test(
      'build_canonical_invoice resolves an active capability by selected template id',
      () {
        final fn = _extractFunction(
          draft006,
          'create or replace function einvoice.build_canonical_invoice(',
        );

        expect(fn, contains('v_selected_template_id text'));
        expect(fn, contains('v_selected_inv_series text'));
        expect(fn, contains('v_current_inv_series text'));
        expect(fn, contains("pc.status = 'CONNECTED'"));
        expect(
          fn,
          contains("jsonb_typeof(elem -> 'is_available') = 'boolean'"),
        );
        expect(fn, contains("(elem ->> 'is_available')::boolean"));
        expect(
          fn,
          contains(
            "coalesce(elem ->> 'template_id', elem ->> 'templateId') "
            '= v_selected_template_id',
          ),
        );
        expect(fn, contains('ts.default_invoice_series'));
      },
    );

    test(
      'build_canonical_invoice accepts only year rollover for strict series',
      () {
        final fn = _extractFunction(
          draft006,
          'create or replace function einvoice.build_canonical_invoice(',
        );

        expect(
          RegExp(r"!~ '\^\[1256\]\[CK\]\.\{2\}\[TM\]'").allMatches(fn).length,
          2,
          reason: 'selected and current InvSeries must both be strict',
        );
        expect(
          fn,
          contains(
            'upper(substr(v_selected_inv_series, 1, 2) || '
            'substr(v_selected_inv_series, 5))',
          ),
        );
        expect(
          fn,
          contains(
            'upper(substr(v_current_inv_series, 1, 2) || '
            'substr(v_current_inv_series, 5))',
          ),
        );
        expect(fn, contains("'code', 'TEMPLATE_NOT_AVAILABLE'"));
        expect(fn, contains('v_inv_series := upper(v_current_inv_series)'));
      },
    );

    test('build_canonical_invoice never infers SignType', () {
      final fn = _extractFunction(
        draft006,
        'create or replace function einvoice.build_canonical_invoice(',
      );

      expect(
        fn,
        contains('v_sign_type := case when v_is_mtt then 5 else 2 end;'),
      );
      expect(fn, isNot(contains('v_sign_type_jsonb')));
      expect(fn, isNot(contains('v_signing_method')));
      expect(fn, isNot(contains("'sign-nosign'")));
      expect(fn, isNot(contains("'sign-mtt'")));
      expect(fn, isNot(contains("'sign-hsm'")));
    });

    test(
      'issue_invoice persists immutable invoice_series from canonical snapshot',
      () {
        final fn = _extractFunction(
          draft008,
          'create or replace function einvoice._start_issuance_attempt(',
        );
        expect(draft007, contains('invoice_series varchar(100) not null'));
        expect(
          draft007,
          isNot(contains('add column if not exists invoice_series')),
        );
        expect(fn, contains('invoice_series,'));
        expect(fn, contains("v_canonical_jsonb ->> 'invSeries'"));
      },
    );
  });
}
