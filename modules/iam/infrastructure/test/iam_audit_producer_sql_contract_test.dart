import 'dart:io';

import 'package:test/test.dart';

void main() {
  late Directory migrationsDir;

  setUpAll(() {
    migrationsDir = Directory(
      '${_findRepoRoot().path}/supabase/migrations',
    );
  });

  String read(String fileSuffix) {
    final files = migrationsDir.listSync(recursive: true).whereType<File>();
    final match = files.firstWhere(
      (f) => f.path.endsWith(fileSuffix) || f.path.contains(fileSuffix),
      orElse: () => throw StateError('Migration file matching $fileSuffix not found'),
    );
    return match.readAsStringSync();
  }

  int appendCalls(String sql) => 'iam.append_audit_log('.allMatches(sql).length;

  test('membership mutation appends audit for the transition event', () {
    final sql = read('014_iam_tenant_membership_lifecycle.sql');
    expect(appendCalls(sql), 1);
    // event_code is the passed p_event_type (covers all 3 transitions).
    expect(sql, contains('p_event_code => p_event_type'));
    expect(sql, contains("'iam.membership.deactivated'"));
    expect(sql, contains("'iam.membership.reactivated'"));
    expect(sql, contains("'iam.membership.removed'"));
  });

  test('membership audit is NOT swallowed (failure rolls back)', () {
    final sql = read('014_iam_tenant_membership_lifecycle.sql');
    final appendIdx = sql.indexOf('iam.append_audit_log(');
    // The append must appear before the defensive outbox begin/exception block.
    final outboxGuard = sql.indexOf('when undefined_function');
    expect(appendIdx, greaterThanOrEqualTo(0));
    expect(appendIdx, lessThan(outboxGuard));
  });

  test('tenant profile + legal profile each produce one audit row', () {
    final sql = read('015_iam_tenant_profile_legal.sql');
    expect(appendCalls(sql), 2);
    expect(sql, contains("'iam.tenant.profile_updated'"));
    expect(sql, contains("'iam.tenant.legal_profile_updated'"));
  });

  test('activation produces exactly one audit row', () {
    final sql = read('016_iam_tenant_readiness_activate.sql');
    expect(appendCalls(sql), 1);
    expect(sql, contains("'iam.tenant.activated'"));
    // tracking id is the idempotency key -> replay cannot duplicate the row.
    expect(sql, contains('p_tracking_id => p_idempotency_key'));
  });

  test('platform suspend/restore produce audit and drop dual-write', () {
    final sql = read('011_iam_platform_tenant_lifecycle.sql');
    expect(appendCalls(sql), 2);
    expect(sql, contains("'iam.tenant.suspended'"));
    expect(sql, contains("'iam.tenant.restored'"));
    expect(sql, isNot(contains('insert into iam.platform_audit_logs')));
  });

  test('ownership transfer drops dual-write', () {
    final sql = read('012_iam_platform_transfer_ownership.sql');
    expect(sql, isNot(contains('insert into iam.platform_audit_logs')));
  });

  test('self-service profile update produces audit', () {
    final sql = read('005_iam_platform_user_lifecycle.sql');
    expect(sql, contains("'iam.account.profile_updated'"));
  });
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
