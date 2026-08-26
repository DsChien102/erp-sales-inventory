import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final root = _findRepoRoot();
    sql = File(
      '${root.path}/supabase/migrations/20260811025_iam_password_reset_by_email.sql',
    ).readAsStringSync();
  });

  group('iam password reset by email SQL contract', () {
    test('public RPCs do not require auth.uid()', () {
      expect(sql, contains('begin_password_reset_operation_by_email'));
      expect(sql, contains('verify_password_reset_code_by_email'));
      expect(sql, contains('complete_password_reset_operation_by_email'));
      expect(sql, contains('grant execute'));
      expect(sql, contains('to anon, authenticated'));
    });

    test('unknown email does not leak and stores only a hash', () {
      expect(sql, contains('Unknown email'));
      expect(sql, contains('email_hash'));
      expect(sql, contains('RESET_CODE_INVALID'));
      expect(sql.toLowerCase(), isNot(contains('user not found')));
    });

    test('complete revokes other sessions after setting credential', () {
      expect(sql, contains('encrypted_password'));
      expect(sql, contains('delete from auth.refresh_tokens'));
      expect(sql, contains('current_session_rotated'));
    });
  });
}

Directory _findRepoRoot() {
  var current = Directory.current.absolute;
  while (!Directory('${current.path}/supabase/migrations').existsSync()) {
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not find repo root from ${Directory.current.path}');
    }
    current = parent;
  }
  return current;
}
