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
  late String draft006Sql;
  late String draft007Sql;

  setUpAll(() {
    final root = _repoRoot();
    final draft006 = File(
      '${root.path}/supabase/migrations/_drafts/'
      '006_einvoice_buyer_completion_and_preview_rpcs.sql',
    );
    final draft007 = File(
      '${root.path}/supabase/migrations/_drafts/'
      '007_einvoice_issuance_schema_and_publish_rpcs.sql',
    );
    draft006Sql = draft006.existsSync() ? draft006.readAsStringSync() : '';
    draft007Sql = draft007.existsSync() ? draft007.readAsStringSync() : '';
  });

  group('Canonical invoice SQL contract parity', () {
    test('defines einvoice.build_canonical_invoice helper', () {
      final combined = '$draft006Sql\n$draft007Sql';
      expect(
        combined,
        contains('create or replace function einvoice.build_canonical_invoice('),
        reason:
            'Must define unified einvoice.build_canonical_invoice helper in drafts',
      );
    });

    test('build_canonical_invoice produces all MISA-required canonical fields', () {
      final combined = '$draft006Sql\n$draft007Sql';
      final helperFn = _extractFunction(
        combined,
        'create or replace function einvoice.build_canonical_invoice(',
      );
      expect(helperFn.isNotEmpty, isTrue, reason: 'Helper function must exist');

      final requiredFields = <String>[
        'invSeries',
        'invDate',
        'currencyCode',
        'exchangeRate',
        'paymentMethodName',
        'buyerLegalName',
        'buyerAddress',
        'totalSaleAmount',
        'totalAmountWithoutVat',
        'totalVatAmount',
        'totalAmount',
        'originalInvoiceDetail',
        'taxRateInfo',
      ];

      for (final field in requiredFields) {
        expect(
          helperFn,
          contains("'$field'"),
          reason: 'build_canonical_invoice must produce required field: $field',
        );
      }
    });

    test('request_invoice_preview invokes build_canonical_invoice and does not enqueue empty payload', () {
      final previewFn = _extractFunction(
        draft006Sql,
        'create or replace function einvoice.request_invoice_preview(',
      );
      expect(previewFn.isNotEmpty, isTrue);

      expect(
        previewFn,
        isNot(contains("'canonical_invoice', '{}'::jsonb")),
        reason: 'request_invoice_preview must not enqueue empty payload {}',
      );
      expect(
        previewFn,
        contains('einvoice.build_canonical_invoice('),
        reason: 'request_invoice_preview must call build_canonical_invoice helper',
      );
    });

    test('issue_invoice invokes build_canonical_invoice and does not construct partial payload', () {
      final issueFn = _extractFunction(
        draft007Sql,
        'create or replace function einvoice.issue_invoice(',
      );
      expect(issueFn.isNotEmpty, isTrue);

      expect(
        issueFn,
        contains('einvoice.build_canonical_invoice('),
        reason: 'issue_invoice must call build_canonical_invoice helper',
      );
      expect(
        issueFn,
        isNot(contains("'modelVersion', '1.0.0'")),
        reason: 'issue_invoice must not construct independent partial JSON',
      );
    });
  });
}
