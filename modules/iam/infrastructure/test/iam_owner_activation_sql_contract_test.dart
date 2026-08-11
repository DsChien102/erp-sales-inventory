import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String activationSql;
  late String onboardingSql;

  setUpAll(() {
    final root = _findRepoRoot();
    activationSql = File(
      '${root.path}/supabase/migrations/_drafts/023_iam_owner_activation.sql',
    ).readAsStringSync();
    onboardingSql = File(
      '${root.path}/supabase/migrations/_drafts/006_iam_create_tenant_onboarding.sql',
    ).readAsStringSync();
  });

  group('iam owner activation SQL contract', () {
    test('owner_activations table stores only a code hash', () {
      expect(
        activationSql,
        contains('create table if not exists iam.owner_activations'),
      );
      expect(activationSql, contains('code_hash text not null'));
      expect(activationSql, contains("status in ('pending','accepted','expired')"));
      expect(activationSql, isNot(contains('raw_code')));
    });

    test('onboarding issues an invitation for both new and existing owners', () {
      final onboardingFn = onboardingSql.substring(
        onboardingSql.indexOf(
          'create or replace function iam.create_tenant_onboarding(',
        ),
      );
      // Both paths store an activation code + email the ciphertext.
      expect(onboardingFn, contains('insert into iam.owner_activations'));
      expect(onboardingFn, contains('secret_payload_ciphertext'));
      expect(onboardingFn, contains('p_owner_email text'));
      // Existing-owner email is resolved from Auth (no user created either way).
      expect(onboardingFn, contains('from auth.users u'));
      // No membership is created at onboarding — it is created on accept.
      expect(onboardingFn, isNot(contains('insert into iam.memberships')));
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
