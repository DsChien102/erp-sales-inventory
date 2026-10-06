import 'dart:io';

import 'package:test/test.dart';

/// SQL contract — trường người mua trống trên snapshot lấy từ hồ sơ đối tác.
void main() {
  final sql = _readDraft('023_einvoice_buyer_partner_fallback.sql');

  test(
    'partner profile function returns invoice fields and hides client execute',
    () {
      final body = _lastFunctionBlock(
        sql,
        'partner.get_einvoice_buyer_profile',
      );
      expect(body, contains('pp.invoice_name'));
      expect(body, contains('op.invoice_name'));
      expect(body, contains('pp.tax_code'));
      expect(body, contains('op.tax_code'));
      expect(body, contains('pp.invoice_address'));
      expect(body, contains('op.invoice_address'));
      expect(
        sql,
        contains(
          'revoke all on function partner.get_einvoice_buyer_profile(uuid, uuid)'
          '\n  from public, anon, authenticated;',
        ),
      );
      expect(
        sql,
        contains(
          'grant execute on function partner.get_einvoice_buyer_profile(uuid, uuid)'
          '\n  to service_role;',
        ),
      );
    },
  );

  test('effective buyer fills blanks from the partner function', () {
    final helper = _lastFunctionBlock(
      sql,
      'einvoice._effective_buyer_snapshot',
    );
    expect(helper, contains('bc.buyer_tax_code'));
    expect(helper, contains("'buyerTaxCode'"));
    expect(helper, contains('partner.get_einvoice_buyer_profile('));
    expect(helper, contains('s.buyer_partner_id'));
    expect(helper, contains('einvoice.electronic_invoices'));
    expect(helper, isNot(contains('partner.organization_profiles')));
    expect(helper, isNot(contains('partner.person_profiles')));
  });

  test('readiness uses the shared helper and does not write completion', () {
    final body = _lastFunctionBlock(sql, 'einvoice.get_issuance_readiness');
    expect(body, contains('einvoice._effective_buyer_snapshot('));
    expect(body, contains('buyer_tax_code text'));
    expect(
      body,
      isNot(contains('insert into einvoice.buyer_invoice_completions')),
    );
    expect(body, isNot(contains('partner.organization_profiles')));
    expect(body, isNot(contains('partner.person_profiles')));
  });

  test(
    'user issuance stores partner fills without touching the sales snapshot',
    () {
      final start = _lastFunctionBlock(sql, 'einvoice._start_issuance_attempt');
      expect(start, contains('partner.get_einvoice_buyer_profile('));
      expect(start, contains('insert into einvoice.buyer_invoice_completions'));
      expect(start, contains('on conflict (tenant_id, sales_order_id)'));
      expect(
        start,
        contains('coalesce(bc.buyer_tax_code, excluded.buyer_tax_code)'),
      );
      expect(start, contains('p_actor_id is not null'));
      expect(start, contains('einvoice._effective_buyer_snapshot('));
      expect(start, contains('for share'));
      expect(sql, isNot(contains('buyer_tax_snapshot')));
    },
  );
}

String _readDraft(String fileName) => File(
  '${_findRepoRoot().path}/supabase/migrations/_drafts/$fileName',
).readAsStringSync();

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
