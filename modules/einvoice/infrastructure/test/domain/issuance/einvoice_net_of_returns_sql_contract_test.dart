import 'dart:io';

import 'package:test/test.dart';

/// SQL contract — spec 2026-09-25 einvoice net-of-returns (§4.6, §4.7).
void main() {
  late String d005;
  late String d006;
  late String d007;
  late String d008;

  setUpAll(() {
    d005 = _readDraft('005_einvoice_buyer_completion_and_preview_schema.sql');
    d006 = _readDraft('006_einvoice_buyer_completion_and_preview_rpcs.sql');
    d007 = _readDraft('007_einvoice_issuance_schema_and_publish_rpcs.sql');
    d008 = _readDraft('008_einvoice_auto_issuance_and_retry_rpcs.sql');
  });

  group('buyer completion is keyed by order, not version', () {
    test('unique constraint is per order', () {
      expect(d005, contains('unique (tenant_id, sales_order_id)\n'));
      expect(d005, isNot(contains('unique (tenant_id, sales_order_id, sales_order_version)')));
    });

    test('no lookup filters completion by version', () {
      for (final sql in [d006, d007, d008]) {
        expect(sql, isNot(contains('bc.sales_order_version =')));
      }
    });

    test('complete_buyer_invoice_data upserts per order with the real buyer partner', () {
      final fn = _lastFunctionBlock(d006, 'einvoice.complete_buyer_invoice_data');
      expect(fn, contains('on conflict (tenant_id, sales_order_id) do update set'));
      expect(fn, isNot(contains('gen_random_uuid()')));
      expect(fn, contains('from sales.get_einvoice_source_snapshot(p_tenant_id, p_sales_order_id) s'));
      expect(fn, contains('VALIDATION_ERROR: buyer partner required'));
    });
  });

  group('sales source blockers are honored', () {
    test('readiness exposes source blockers and is recreated', () {
      expect(d006, contains('drop function if exists einvoice.get_issuance_readiness(uuid, uuid, uuid);'));
      final fn = _lastFunctionBlock(d006, 'einvoice.get_issuance_readiness');
      expect(fn, contains('  config_warnings jsonb,\n  source_blockers jsonb\n'));
      expect(fn, contains("    v_warnings,\n    coalesce(v_source.blockers, '[]'::jsonb);"));
    });

    test('manual issue and retry reject any source blocker', () {
      for (final name in ['einvoice.issue_invoice', 'einvoice.retry_issuance']) {
        final fn = _lastFunctionBlock(d008, name);
        expect(fn, contains("if jsonb_array_length(coalesce(v_source.blockers, '[]'::jsonb)) > 0 then"), reason: name);
        expect(fn, contains("'blockers', v_source.blockers"), reason: name);
      }
    });

    test('auto start and reevaluate skip fully returned orders', () {
      final start = _lastFunctionBlock(d008, 'einvoice.start_auto_issuance');
      expect(start, contains("if coalesce(v_source.blockers, '[]'::jsonb) ? 'ORDER_FULLY_RETURNED' then"));
      expect(start, contains("'ORDER_FULLY_RETURNED'::text as reason;"));
      final reevaluate = _lastFunctionBlock(d008, 'einvoice.reevaluate_auto_issuance');
      expect(reevaluate, contains("if coalesce(v_source.blockers, '[]'::jsonb) ? 'ORDER_FULLY_RETURNED' then"));
      expect(reevaluate, contains("set process_status = 'SKIPPED',"));
    });

    test('reevaluate refreshes the process source version before starting', () {
      final reevaluate = _lastFunctionBlock(d008, 'einvoice.reevaluate_auto_issuance');
      expect(reevaluate, contains('if v_source.source_version is distinct from v_proc.sales_order_version then'));
      expect(reevaluate, contains('v_proc.sales_order_version := v_source.source_version;'));
    });
  });
}

String _readDraft(String name) {
  var dir = Directory.current.absolute;
  while (!Directory('${dir.path}/supabase/migrations/_drafts').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('Could not locate Vet45 workspace root');
    }
    dir = parent;
  }
  return File('${dir.path}/supabase/migrations/_drafts/$name').readAsStringSync();
}

String _lastFunctionBlock(String sql, String qualifiedName) {
  final start = sql.lastIndexOf('create or replace function $qualifiedName(');
  if (start < 0) {
    throw StateError('$qualifiedName not found');
  }
  final end = sql.indexOf(r'$$;', start);
  return sql.substring(start, end + 3);
}
