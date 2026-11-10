import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String root;

  String read(String name) =>
      File('$root/supabase/migrations/$name').readAsStringSync();

  setUpAll(() {
    root = _findRepoRoot().path;
  });

  group('partner system partner SQL contract', () {
    test('partners_has_is_system', () {
      final sql = read('20260714001_partner_v2_schema.sql');
      expect(sql, contains('is_system boolean not null default false'));
      expect(sql, contains('partners_one_system_per_tenant'));
      expect(sql, contains('where is_system'));
    });

    test('lock_partner_blocks_system', () {
      final sql = read('20260714004_partner_v2_write_rpc.sql');
      final start = sql.indexOf('function partner._lock_partner(');
      final end = sql.indexOf('function partner._upsert_roles(');
      expect(start, greaterThan(-1));
      final body = sql.substring(start, end);
      expect(body, contains("'PARTNER_SYSTEM_LOCKED'"));
      expect(body, contains('v_partner.is_system'));
    });

    test('detail_returns_is_system', () {
      final sql = read('20260714003_partner_v2_read.sql');
      expect(sql, contains('p.is_system'));
      final start = sql.indexOf('function partner.get_partner_detail(');
      final body = sql.substring(start, sql.indexOf('function partner.check_duplicate('));
      expect(body, contains("'is_system'"));
      expect(body, contains('not v_row.is_system'));
    });

    test('default_pair_ensures_walk_in', () {
      final sql = read('20261104001_inventory_default_pair.sql');
      final start = sql.indexOf(
        'function inventory.ensure_default_store_warehouse_pair(',
      );
      final body = sql.substring(start);
      final call = body.indexOf('perform inventory._ensure_walk_in_supplier(p_tenant_id)');
      final firstReturn = body.indexOf('return ');
      expect(call, greaterThan(-1));
      expect(call, lessThan(firstReturn));
    });

    test('org_phone_check_allows_system', () {
      final sql = read('20260714001_partner_v2_schema.sql');
      expect(sql, contains('allow_blank_phone or length(btrim(phone)) > 0'));
      expect(sql, contains('allow_blank_phone boolean not null default false'));
    });
  });
}

Directory _findRepoRoot() {
  var current = Directory.current.absolute;
  while (!Directory('${current.path}/supabase/migrations').existsSync()) {
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not locate workspace root');
    }
    current = parent;
  }
  return current;
}
