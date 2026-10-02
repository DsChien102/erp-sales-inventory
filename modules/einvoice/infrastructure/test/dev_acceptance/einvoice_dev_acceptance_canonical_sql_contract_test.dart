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
  late String draft008Sql;

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
    final draft008 = File(
      '${root.path}/supabase/migrations/_drafts/'
      '008_einvoice_auto_issuance_and_retry_rpcs.sql',
    );
    draft006Sql = draft006.existsSync() ? draft006.readAsStringSync() : '';
    draft007Sql = draft007.existsSync() ? draft007.readAsStringSync() : '';
    draft008Sql = draft008.existsSync() ? draft008.readAsStringSync() : '';
  });

  group('Canonical invoice SQL contract parity', () {
    test('defines einvoice.build_canonical_invoice helper', () {
      final combined = '$draft006Sql\n$draft007Sql';
      expect(
        combined,
        contains(
          'create or replace function einvoice.build_canonical_invoice(',
        ),
        reason:
            'Must define unified einvoice.build_canonical_invoice helper in drafts',
      );
    });

    test(
      'build_canonical_invoice produces all MISA-required canonical fields',
      () {
        final combined = '$draft006Sql\n$draft007Sql';
        final helperFn = _extractFunction(
          combined,
          'create or replace function einvoice.build_canonical_invoice(',
        );
        expect(
          helperFn.isNotEmpty,
          isTrue,
          reason: 'Helper function must exist',
        );

        final requiredFields = <String>[
          'invSeries',
          'signType',
          'invoiceWithCode',
          'isInvoiceSummary',
          'invDate',
          'currencyCode',
          'exchangeRate',
          'paymentMethodName',
          'buyerLegalName',
          'buyerAddress',
          'totalSaleAmount',
          'totalDiscountAmount',
          'totalAmountWithoutVat',
          'totalVatAmount',
          'totalAmount',
          'originalInvoiceDetail',
        ];

        for (final field in requiredFields) {
          expect(
            helperFn,
            contains("'$field'"),
            reason:
                'build_canonical_invoice must produce required field: $field',
          );
        }
      },
    );

    test('build_canonical_invoice translates Sales vocabulary and declares KCT', () {
      // ADR-TH08-KCT: hardcode '10%' cũ bịa ra thuế suất và mâu thuẫn với
      // vatAmount = 0. MISA bắt buộc TaxRateInfo, nên thay bằng KCT tường minh.
      expect(draft006Sql, isNot(contains("'10%'")));
      expect(draft006Sql, contains("'vatRateName', 'KCT'"));
      expect(draft006Sql, contains("'taxRateInfo', v_tax_rates"));
      expect(
        draft006Sql,
        contains('ADR-TH08-KCT'),
        reason: 'quyết định phải có dấu vết ngay tại chỗ nó được thực thi',
      );
      expect(
        draft006Sql,
        contains('UNSUPPORTED_TAX_DATA'),
        reason: 'KCT-only invariant phải fail closed trước khi áp KCT',
      );
      expect(
        draft006Sql,
        contains(
          "'amount',           trim_scale((ln ->> 'grossAmountMinor')::numeric)",
        ),
      );
      expect(
        draft006Sql,
        contains(
          "'amountWithoutVat', trim_scale((ln ->> 'lineTotalMinor')::numeric)",
        ),
      );
      expect(
        draft006Sql,
        contains(
          "'quantity',         trim_scale((ln ->> 'quantityMicros')::numeric / 1000000.0)",
        ),
      );
      expect(draft006Sql, contains('totals identity violated'));
      expect(
        draft006Sql,
        contains("'discountAmount',   trim_scale((ln ->> 'discountMinor')::numeric),"),
      );
      expect(
        draft006Sql,
        contains("'totalDiscountAmount', trim_scale((v_totals ->> 'discountMinor')::numeric),"),
      );
    });

    test('buyer classification follows BR-06 and BR-07', () {
      final readinessSql = _extractFunction(
        draft006Sql,
        'create or replace function einvoice.get_issuance_readiness(',
      );
      expect(readinessSql, isNot(contains("v_buyer_type text := 'retail'")));
      expect(readinessSql, isNot(contains("'Người mua hàng'")));
      expect(draft006Sql, isNot(contains("'Khách hàng cá nhân'")));
      expect(readinessSql, contains("'Bán cho người tiêu dùng'"));
      expect(readinessSql, contains("'organization'"));
      expect(readinessSql, contains("'individual'"));
    });

    // Preview và issue gọi thẳng build_canonical_invoice với buyer_snapshot gốc
    // từ Sales, không đi qua get_issuance_readiness. Nếu BR-06 chỉ tồn tại trong
    // readiness thì đơn khách lẻ sẽ raise 'buyerLegalName is required'.
    test('BR-06 is applied inside build_canonical_invoice, not only readiness', () {
      final canonicalSql = _extractFunction(
        draft006Sql,
        'create or replace function einvoice.build_canonical_invoice(',
      );
      expect(
        canonicalSql,
        contains("'Bán cho người tiêu dùng'"),
        reason: 'retail buyer must be resolvable on the payload path',
      );
      expect(
        canonicalSql,
        contains("p_buyer_snapshot ->> 'buyerType'"),
        reason:
            'classification must branch on buyerType carried by the snapshot',
      );
      expect(
        canonicalSql,
        contains('buyer name is required for an identified buyer'),
        reason: 'BR-07 still blocks identified buyers with no name',
      );
      // MISA: BuyerFullName = "Họ tên người mua hàng", BuyerLegalName = "Tên đơn vị".
      // Định tuyến theo buyerType, nếu không tên cá nhân sẽ nằm ở ô tên đơn vị.
      expect(canonicalSql, contains("'buyerFullName', v_buyer_full_name"));
      expect(canonicalSql, contains("'buyerLegalName', v_buyer_legal_name"));
      // Kiểm phép gán, không kiểm chuỗi trần — chuỗi còn xuất hiện trong chú
      // thích giải thích vì sao đã bỏ nó.
      expect(
        canonicalSql,
        isNot(contains(", 'Việt Nam')")),
        reason: 'không coalesce địa chỉ người mua về một địa chỉ bịa',
      );
      expect(
        canonicalSql,
        contains("v_buyer_address := nullif(btrim(coalesce("),
        reason: 'thiếu địa chỉ thì để trống, không thay bằng hằng số',
      );
    });

    // Hash toàn vẹn băm sha256(canonical::text) ở 008, rồi canonical đi vòng
    // PostgREST → Dart → quay lại và bị băm lại. Postgres chia numeric ra 16 chữ
    // số thập phân, Dart ghi lại thành "2.0" → hash khác → STATE_CHANGED.
    test('every canonical number is scale-trimmed for hash stability', () {
      final canonicalSql = _extractFunction(
        draft006Sql,
        'create or replace function einvoice.build_canonical_invoice(',
      );

      // Phép chia là nguồn lệch thật; các trường còn lại bọc theo cho đồng nhất.
      expect(
        canonicalSql,
        contains("trim_scale((ln ->> 'quantityMicros')::numeric / 1000000.0)"),
        reason:
            'division produces 16 decimals that do not survive the round trip',
      );

      final bareNumeric = RegExp(
        r"'\w+',\s+\((?:ln|v_totals) ->> '\w+'\)::numeric",
      );
      expect(
        bareNumeric.hasMatch(canonicalSql),
        isFalse,
        reason: 'mọi số phải bọc trim_scale; thêm trường mới cũng vậy',
      );
    });

    // `NULL <> x` cho ra NULL và `if NULL` không kích hoạt, nên assert sẽ tự
    // tắt đúng lúc totals hỏng. Phải kiểm NULL tường minh.
    test('totals invariant cannot be silently skipped on missing keys', () {
      final canonicalSql = _extractFunction(
        draft006Sql,
        'create or replace function einvoice.build_canonical_invoice(',
      );
      expect(canonicalSql, contains("(v_totals ->> 'subtotalMinor') is null"));
      expect(canonicalSql, contains("(v_totals ->> 'discountMinor') is null"));
      expect(canonicalSql, contains("(v_totals ->> 'payableMinor') is null"));
      expect(
        canonicalSql,
        contains('is distinct from'),
        reason: 'comparison must never evaluate to NULL',
      );
    });

    test('issuance lineage keeps pre-merge Theme-05 base', () {
      final issuanceSql = _extractFunction(
        draft008Sql,
        'create or replace function einvoice._start_issuance_attempt(',
      );
      expect(issuanceSql, contains('v_base_buyer_snapshot'));
      expect(
        issuanceSql,
        contains("'buyerInvoiceSnapshot', v_base_buyer_snapshot"),
        reason:
            'S5 freeze: lineage must be the source-owned base before completion merge',
      );
      expect(
        issuanceSql,
        contains('einvoice._effective_buyer_snapshot('),
        reason: 'completion must merge into effective buyer for payload',
      );
    });

    test(
      'request_invoice_preview invokes build_canonical_invoice and does not enqueue empty payload',
      () {
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
          reason:
              'request_invoice_preview must call build_canonical_invoice helper',
        );
      },
    );

    test(
      'issue_invoice invokes build_canonical_invoice and does not construct partial payload',
      () {
        final helper = _extractFunction(
          draft008Sql,
          'create or replace function einvoice._start_issuance_attempt(',
        );
        final issueFn = _extractFunction(
          draft008Sql,
          'create or replace function einvoice.issue_invoice(',
        );
        expect(helper.isNotEmpty, isTrue);
        expect(issueFn.isNotEmpty, isTrue);

        expect(
          helper,
          contains('einvoice.build_canonical_invoice('),
          reason: 'the start helper must call build_canonical_invoice',
        );
        expect(
          issueFn,
          contains('einvoice._start_issuance_attempt'),
          reason: 'issue_invoice delegates canonical build to the start helper',
        );
        expect(
          helper,
          isNot(contains("'modelVersion', '1.0.0'")),
          reason: 'the start helper must not construct independent partial JSON',
        );
      },
    );
  });
}
