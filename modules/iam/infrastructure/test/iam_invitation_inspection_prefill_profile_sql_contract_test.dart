import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final root = _findRepoRoot();
    sql = File(
      '${root.path}/supabase/migrations/_drafts/iam_invitation_inspection_prefill_profile.sql',
    ).readAsStringSync();
  });

  test('owner activation inspection returns saved profile prefill fields', () {
    final ownerActivationBranch = sql.substring(
      sql.indexOf('from iam.owner_activations oa'),
      sql.indexOf('raise;', sql.indexOf('from iam.owner_activations oa')),
    );

    expect(ownerActivationBranch, contains("'given_name', v_owner_activation.given_name"));
    expect(ownerActivationBranch, contains("'family_name', v_owner_activation.family_name"));
    expect(ownerActivationBranch, contains("'phone', v_owner_activation.phone"));
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
