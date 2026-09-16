import 'dart:io';

import 'package:test/test.dart';

Directory _repoRoot() {
  var dir = Directory.current;
  while (!File('${dir.path}/pubspec.yaml').existsSync() ||
      !Directory('${dir.path}/packages/vet45_shared').existsSync() ||
      !Directory('${dir.path}/supabase/migrations').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('Cannot locate repository root');
    }
    dir = parent;
  }
  return dir;
}

void main() {
  late String draft003;
  late String draft004;

  setUpAll(() {
    final root = _repoRoot();
    draft003 = File(
      '${root.path}/supabase/migrations/_drafts/003_einvoice_provider_connection_rpcs.sql',
    ).readAsStringSync();
    draft004 = File(
      '${root.path}/supabase/migrations/_drafts/004_einvoice_profile_policy_readiness_rpcs.sql',
    ).readAsStringSync();
  });

  group('th08_hardening_capability — SQL capability versioning', () {
    test(
      '003 documents additive template JSON fields for legacy snapshots',
      () {
        expect(draft003, contains('invoice_series'));
        expect(draft003, contains('invoice_with_code'));
        expect(draft003, contains('is_send_summary'));
        expect(draft003, contains('Legacy rows may omit'));
      },
    );

    test(
      '004 list_provider_templates returns classification columns and filter',
      () {
        expect(draft004, contains('invoice_series text'));
        expect(draft004, contains('invoice_with_code boolean'));
        expect(draft004, contains('is_mtt boolean'));
        expect(draft004, contains('is_send_summary boolean'));
        expect(draft004, contains('p_invoice_with_code is null'));
        expect(
          draft004,
          contains("coalesce(elem ->> 'invoice_series', elem ->> 'symbol')"),
        );
      },
    );
  });
}
