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
  if (start < 0) {
    return '';
  }
  final revoke = sql.indexOf('revoke all on function', start);
  final nextCreate = sql.indexOf(
    '\ncreate or replace function',
    start + signaturePrefix.length,
  );
  final endCandidates = [
    if (revoke > start) revoke,
    if (nextCreate > start) nextCreate,
    sql.length,
  ]..sort();
  return sql.substring(start, endCandidates.first);
}

void main() {
  late String draft006;
  late String readinessFn;
  late String canonicalFn;

  setUpAll(() {
    final root = _repoRoot();
    draft006 = File(
      '${root.path}/supabase/migrations/_drafts/'
      '006_einvoice_buyer_completion_and_preview_rpcs.sql',
    ).readAsStringSync();
    readinessFn = _extractFunction(
      draft006,
      'create or replace function einvoice.get_issuance_readiness(',
    );
    canonicalFn = _extractFunction(
      draft006,
      'create or replace function einvoice.build_canonical_invoice(',
    );
  });

  group('th08_hardening_buyer — organization address requirement', () {
    test('readiness blocks org with tax code but missing address', () {
      expect(readinessFn, contains('BUYER_ADDRESS_REQUIRED'));
      expect(readinessFn, contains("v_buyer_type = 'organization'"));
      expect(readinessFn, contains('v_buyer_tax_code'));
      expect(readinessFn, contains('v_buyer_address'));
    });

    test('canonical blocks org with tax code but missing address', () {
      expect(canonicalFn, contains('BUYER_ADDRESS_REQUIRED'));
      expect(canonicalFn, contains("v_buyer_type = 'organization'"));
      expect(canonicalFn, contains('v_buyer_tax_code'));
      expect(canonicalFn, contains('v_buyer_address'));
    });
  });
}
