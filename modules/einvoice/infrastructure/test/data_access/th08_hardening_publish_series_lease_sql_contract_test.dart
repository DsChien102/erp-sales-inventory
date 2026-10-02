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
  final grant = sql.indexOf('grant execute on function', start);
  final nextCreate = sql.indexOf(
    '\ncreate or replace function',
    start + signaturePrefix.length,
  );
  final endCandidates = [
    if (grant > start) grant,
    if (nextCreate > start) nextCreate,
    sql.length,
  ]..sort();
  return sql.substring(start, endCandidates.first);
}

void main() {
  late String sql;
  late String acquireFn;
  late String renewFn;
  late String releaseFn;
  late String rescheduleFn;

  setUpAll(() {
    sql = File(
      '${_repoRoot().path}/supabase/migrations/_drafts/'
      '019_einvoice_misa_publish_series_lease.sql',
    ).readAsStringSync();
    acquireFn = _extractFunction(
      sql,
      'create or replace function einvoice.acquire_publish_series_lease(',
    );
    releaseFn = _extractFunction(
      sql,
      'create or replace function einvoice.release_publish_series_lease(',
    );
    renewFn = _extractFunction(
      sql,
      'create or replace function einvoice.renew_publish_series_lease(',
    );
    rescheduleFn = _extractFunction(
      sql,
      'create or replace function einvoice.reschedule_internal_command(',
    );
  });

  group('th08_hardening_publish_series_lease — draft 019', () {
    test('declares Touches header matching lease and reschedule RPCs', () {
      expect(
        sql,
        contains(
          '-- Touches: einvoice.publish_series_leases, einvoice.acquire_publish_series_lease, einvoice.renew_publish_series_lease, einvoice.release_publish_series_lease, einvoice.reschedule_internal_command',
        ),
      );
    });

    test('lease table uses composite PK and owner_token + leased_until', () {
      expect(sql, contains('einvoice.publish_series_leases'));
      expect(sql, isNot(contains('einvoice.provider_series_dispatch_leases')));
      expect(sql, contains('primary key (tenant_id, invoice_series)'));
      expect(
        sql,
        isNot(
          contains(
            'primary key (tenant_id, provider_connection_id, invoice_series)',
          ),
        ),
      );
      expect(sql, contains('owner_token varchar(100)'));
      expect(sql, contains('leased_until timestamptz'));
      expect(sql, contains('lease_version bigint not null default 1'));
    });

    test('acquire reads immutable series and returns fencing metadata', () {
      expect(acquireFn, contains('v_attempt.invoice_series'));
      expect(acquireFn, contains('acquired boolean'));
      expect(acquireFn, contains('lease_version bigint'));
      expect(acquireFn, contains('leased_until timestamptz'));
      expect(acquireFn, contains('retry_after_seconds integer'));
      expect(acquireFn, contains('p_lease_seconds integer default 300'));
    });

    test('first insert is race-safe and conflict path locks current row', () {
      expect(acquireFn, contains('#variable_conflict use_column'));
      expect(
        acquireFn,
        contains(
          'on conflict (tenant_id, invoice_series) do nothing',
        ),
      );
      expect(acquireFn, contains('for update'));
    });

    test('lease mutations qualify columns that collide with table outputs', () {
      expect(
        acquireFn,
        contains('update einvoice.publish_series_leases as psdl'),
      );
      expect(acquireFn, isNot(contains('psdl.provider_connection_id')));
      expect(acquireFn, contains('and psdl.invoice_series = v_series'));
      expect(
        renewFn,
        contains('update einvoice.publish_series_leases as psdl'),
      );
      expect(renewFn, isNot(contains('psdl.provider_connection_id')));
      expect(renewFn, contains('and psdl.leased_until > v_now'));
    });

    test('same owner keeps version while expired takeover increments it', () {
      expect(acquireFn, contains('v_existing.owner_token = p_owner_token'));
      expect(acquireFn, contains('lease_version = v_existing.lease_version'));
      expect(
        acquireFn,
        contains('lease_version = v_existing.lease_version + 1'),
      );
      expect(acquireFn, contains('greatest(\n        1,'));
      expect(acquireFn, contains('extract(epoch from'));
    });

    test('renew requires live matching owner and fencing version', () {
      expect(renewFn, contains('owner_token = p_owner_token'));
      expect(renewFn, contains('lease_version = p_lease_version'));
      expect(renewFn, contains('leased_until > v_now'));
      expect(renewFn, contains('p_lease_seconds integer default 300'));
      expect(renewFn, contains('renewed boolean'));
    });

    test(
      'release is owner and fencing-version scoped and does not delete row',
      () {
        expect(releaseFn, contains('owner_token = p_owner_token'));
        expect(releaseFn, contains('lease_version = p_lease_version'));
        expect(releaseFn, contains('leased_until = now()'));
        expect(releaseFn, isNot(contains('delete from')));
      },
    );

    test('reschedule clears claim without incrementing retry_count', () {
      expect(rescheduleFn, contains('enqueued_at = now() + v_delay'));
      expect(rescheduleFn, contains('claimed_at = null'));
      expect(rescheduleFn, contains('claim_token = null'));
      expect(rescheduleFn, isNot(contains('retry_count')));
    });
  });
}
