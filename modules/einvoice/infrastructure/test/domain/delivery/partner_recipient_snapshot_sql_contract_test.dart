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
  expect(start, greaterThanOrEqualTo(0), reason: 'missing $signaturePrefix');
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
  late String sql;
  late String draftPath;
  late String snapshotFn;
  late String grantsTail;

  setUpAll(() {
    draftPath =
        '${_repoRoot().path}/supabase/migrations/_drafts/'
        '016_partner_einvoice_recipient_snapshot.sql';
    final draft = File(draftPath);
    expect(
      draft.existsSync(),
      isTrue,
      reason:
          'Partner e-invoice recipient snapshot draft must exist under '
          'supabase/migrations/_drafts/',
    );
    sql = draft.readAsStringSync();
    snapshotFn = _extractFunction(
      sql,
      'create or replace function partner.get_einvoice_recipient_snapshot(',
    );
    final revokeStart = sql.indexOf(
      'revoke all on function partner.get_einvoice_recipient_snapshot(',
    );
    expect(
      revokeStart,
      greaterThanOrEqualTo(0),
      reason: 'missing revoke for get_einvoice_recipient_snapshot',
    );
    grantsTail = sql.substring(revokeStart);
  });

  group('Draft metadata', () {
    test('declares Kind, Intent, and Touches for only this function', () {
      expect(sql, contains('-- Kind: surgical'));
      expect(sql, contains('-- Intent: partner_einvoice_recipient_snapshot'));
      expect(sql, contains('-- Touches: get_einvoice_recipient_snapshot'));
      expect(
        RegExp(
          r'^-- Touches:\s*(.+)$',
          multiLine: true,
        ).firstMatch(sql)?.group(1),
        equals('get_einvoice_recipient_snapshot'),
      );
    });

    test('does not invent a parallel Partner email store', () {
      expect(sql, isNot(contains('create table')));
      expect(sql, isNot(contains('einvoice.')));
      expect(sql, contains('partner.person_profiles'));
      expect(sql, contains('partner.organization_profiles'));
      expect(sql, contains('invoice_email'));
    });
  });

  group('Function signature and security', () {
    test('uses the frozen source-owned signature and return columns', () {
      expect(snapshotFn, contains('partner.get_einvoice_recipient_snapshot('));
      expect(snapshotFn, contains('p_tenant_id uuid'));
      expect(snapshotFn, contains('p_partner_id uuid'));
      expect(snapshotFn, contains('returns table ('));
      expect(snapshotFn, contains('partner_id uuid,'));
      expect(snapshotFn, contains('invoice_email text,'));
      expect(snapshotFn, contains('recipient_name text,'));
      expect(snapshotFn, contains('source_version bigint,'));
      expect(snapshotFn, contains('is_active boolean'));
    });

    test('is security definer with pinned partner search_path', () {
      expect(snapshotFn, contains('security definer'));
      expect(snapshotFn, contains('set search_path = partner, pg_temp'));
    });

    test('filters by tenant and partner id', () {
      expect(snapshotFn, contains('p.tenant_id = p_tenant_id'));
      expect(snapshotFn, contains('p.partner_id = p_partner_id'));
      expect(snapshotFn, contains('from partner.partners p'));
    });

    test('derives recipient fields from canonical Partner profiles', () {
      expect(snapshotFn, contains('nullif(btrim('));
      expect(
        snapshotFn,
        contains('coalesce(pp.invoice_email, op.invoice_email)'),
      );
      expect(
        snapshotFn,
        contains('coalesce(pp.invoice_name, op.invoice_name)'),
      );
      expect(snapshotFn, contains('p.display_name'));
      expect(snapshotFn, contains('p.version::bigint'));
      expect(snapshotFn, contains("p.status = 'active'"));
      expect(snapshotFn, contains('partner.partner_roles'));
      expect(snapshotFn, contains('pr.is_active = true'));
    });
  });

  group('Grants and revokes', () {
    test('revokes client roles and grants only service_role execute', () {
      expect(
        grantsTail,
        contains(
          'revoke all on function partner.get_einvoice_recipient_snapshot(uuid, uuid)',
        ),
      );
      expect(grantsTail, contains('from public, anon, authenticated'));
      expect(
        grantsTail,
        contains(
          'grant execute on function partner.get_einvoice_recipient_snapshot(uuid, uuid)',
        ),
      );
      expect(grantsTail, contains('to service_role;'));
      expect(grantsTail, isNot(contains('to authenticated')));
      expect(grantsTail, isNot(contains('to authenticated, service_role')));
    });
  });
}
