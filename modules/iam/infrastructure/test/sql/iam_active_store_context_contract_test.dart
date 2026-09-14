import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('IAM active-store draft defines the fail-closed session contract', () {
    final sql = File(
      'supabase/migrations/_drafts/001_iam_active_store_context_group_a.sql',
    ).readAsStringSync();

    expect(sql, contains('create table if not exists iam.stores'));
    expect(sql, contains('create table if not exists iam.membership_store_scopes'));
    expect(sql, contains('active_store_id'));
    expect(sql, contains("'active_store_code', v_active_store_code"));
    expect(
      sql,
      contains("'active_store_display_name', v_active_store_display_name"),
    );
    expect(sql, contains('iam.get_session_context'));
    expect(sql, contains("raise exception using errcode = 'P0001'"));
    expect(sql, isNot(contains('limit 1')));
    expect(
      sql,
      contains("set display_name = excluded.display_name, status = 'active'"),
    );

    final ownerGuard = "if v_role not in ('owner', 'store_owner') then";
    final storeWrite = 'insert into iam.stores';
    final guardIndex = sql.indexOf(ownerGuard);
    final writeIndex = sql.indexOf(storeWrite);

    expect(guardIndex, greaterThanOrEqualTo(0));
    expect(writeIndex, greaterThan(guardIndex));
    expect(
      sql.substring(guardIndex, writeIndex),
      allOf(
        contains("raise exception using errcode = 'P0001'"),
        contains('"code":"PERMISSION_DENIED"'),
      ),
    );
  });
}
