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

void main() {
  late String apiContract;

  setUpAll(() {
    apiContract = File(
      '${_repoRoot().path}/docs/themes/TH-08-e-invoice/harness/07-api-contracts.md',
    ).readAsStringSync();
  });

  test('S4 contract freezes ambiguous and scope requirements', () {
    expect(apiContract, contains('CHECK_REQUIRED is an unresolved lock'));
    expect(apiContract, contains('sales.can_access_sales_order'));
    expect(
      apiContract,
      isNot(contains('seed_due_provider_observation_commands')),
    );
    expect(apiContract, contains('triggerId'));
    expect(apiContract, isNot(contains('UTC-day')));
  });

  test('S4 contract freezes observation trigger idempotency by triggerId', () {
    expect(apiContract, contains('Replay same `triggerId` reuses one command'));
    expect(
      apiContract,
      contains('Distinct authorized triggers on the same day remain distinct'),
    );
  });
}
