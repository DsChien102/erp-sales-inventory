import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final root = _findRepoRoot();
    sql = File(
      '${root.path}/supabase/migrations/_drafts/iam_audit_owner_activation_cleanup.sql',
    ).readAsStringSync();
  });

  group('iam owner activation retirement contract', () {
    test('legacy owner activation RPCs and table are dropped', () {
      expect(sql, contains('drop function if exists iam.inspect_owner_activation(text)'));
      expect(sql, contains('drop function if exists iam.accept_owner_activation(text, text)'));
      expect(sql, contains('drop table if exists iam.owner_activations'));
    });

    test('onboarding issues an owner invitation via tenant_invitations', () {
      final start = sql.indexOf('create or replace function iam.create_tenant_onboarding(');
      final end = start < 0 ? -1 : sql.indexOf(r'$$;', start);
      final fn = start < 0 ? '' : sql.substring(start, end < 0 ? null : end);
      expect(fn, contains('insert into iam.tenant_invitations'));
      expect(fn, contains('is_owner'));
      expect(fn, isNot(contains('insert into iam.memberships')));
      expect(fn, isNot(contains('owner_activations')));
    });
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
