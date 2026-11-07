// ignore_for_file: implementation_imports, depend_on_referenced_packages

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/logic/sales_draft_rules.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart';

SalesOrderDraftLineInput _line({
  String productId = 'p1',
  int qty = QuantityDto.scale,
  int applied = 1000,
  int total = 1000,
  String lineCurrency = 'VND',
  int? manualPrice,
  int? manualDiscount,
  int? manualBp,
  MoneyDto? list,
}) => SalesOrderDraftLineInput(
  productId: productId,
  productSku: 'SKU',
  productName: 'Name',
  productUnitId: 'u1',
  unitCode: 'BOX',
  unitName: 'Hop',
  quantity: QuantityDto(quantityMicros: qty),
  appliedUnitPrice: MoneyDto(amountMinor: applied, currencyCode: lineCurrency),
  lineTotal: MoneyDto(amountMinor: total, currencyCode: lineCurrency),
  listUnitPrice: list,
  manualUnitPriceMinor: manualPrice,
  manualDiscountMinor: manualDiscount,
  manualDiscountBasisPoints: manualBp,
);

const _customer = CustomerSnapshotDto(customerId: 'c1', displayName: 'A');

/// Mỗi ca: (tên, hàm gây lỗi, câu cũ). Dùng chung cho `new` (rule) và `old` (validator).
class _Case {
  _Case(this.name, this.args, this.message);
  final String name;
  final _Args args;
  final String message;
}

class _Args {
  _Args({
    this.storeId = 's1',
    this.customer,
    this.currency = 'VND',
    List<SalesOrderDraftLineInput>? lines,
    this.key = 'k',
    this.draftId = 'd1',
    this.version = 1,
  }) : lines = lines ?? [_line()];
  final String storeId;
  final CustomerSnapshotDto? customer;
  final String currency;
  final List<SalesOrderDraftLineInput> lines;
  final String key;
  final String draftId;
  final int version;
}

final _saveUpdateCases = <_Case>[
  _Case('blank_store', _Args(storeId: ' '), 'storeId is required.'),
  _Case('blank_currency', _Args(currency: ''), 'currencyCode is required.'),
  _Case('blank_key', _Args(key: ' '), 'idempotencyKey is required.'),
  _Case(
    'walk_in',
    _Args(
      customer: const CustomerSnapshotDto(customerId: ' cust-walk-in ', displayName: 'Khach le'),
    ),
    'Walk-in customer must be represented as null customer.',
  ),
  _Case(
    'blank_customer_id',
    _Args(
      customer: const CustomerSnapshotDto(customerId: ' ', displayName: 'A'),
    ),
    'customerId is required.',
  ),
  _Case(
    'blank_customer_name',
    _Args(
      customer: const CustomerSnapshotDto(customerId: 'c1', displayName: ' '),
    ),
    'displayName is required.',
  ),
  _Case('no_lines', _Args(lines: []), 'Sales draft must contain at least one line.'),
  _Case('blank_product', _Args(lines: [_line(productId: ' ')]), 'productId is required.'),
  _Case(
    'qty_zero',
    _Args(lines: [_line(qty: 0, total: 0)]),
    'Draft line quantity must be positive.',
  ),
  _Case(
    'line_currency',
    _Args(lines: [_line(lineCurrency: 'USD')]),
    'Draft line currency must match draft currency.',
  ),
  _Case(
    'list_currency',
    _Args(
      lines: [_line(list: const MoneyDto(amountMinor: 1, currencyCode: 'USD'))],
    ),
    'Draft line currency must match draft currency.',
  ),
  _Case(
    'negative_total',
    _Args(lines: [_line(total: -1, manualDiscount: 1)]),
    'Draft lineTotal must be non-negative.',
  ),
  _Case(
    'two_manual_modes',
    _Args(lines: [_line(manualPrice: 1, manualDiscount: 1)]),
    'At most one manual price or discount mode may be set.',
  ),
  _Case(
    'bp_10001',
    _Args(lines: [_line(manualBp: 10001)]),
    'manualDiscountBasisPoints must be between 0 and 10000.',
  ),
  _Case(
    'total_mismatch',
    _Args(lines: [_line(total: 999)]),
    'Draft lineTotal does not match applied unit price.',
  ),
];

Matcher _contextInvalid(String message) => throwsA(
  isA<AppException>()
      .having((e) => e.code, 'code', 'CONTEXT_INVALID')
      .having((e) => e.serverMessage, 'msg', message)
      .having((e) => e.details, 'details', isNull),
);

void _checkSave(_Args a) => checkSaveDraft(
  storeId: a.storeId,
  customer: a.customer,
  currencyCode: a.currency,
  lines: a.lines,
  idempotencyKey: a.key,
);

void _checkUpdate(_Args a) => checkUpdateDraft(
  draftId: a.draftId,
  expectedVersion: a.version,
  storeId: a.storeId,
  customer: a.customer,
  currencyCode: a.currency,
  lines: a.lines,
  idempotencyKey: a.key,
);

void main() {
  group('new', () {
    test('save_valid', () {
      _checkSave(_Args(customer: _customer));
    });
    test('update_valid', () {
      _checkUpdate(_Args(customer: _customer));
    });
    test('cancel_valid', () {
      checkCancelDraft(draftId: 'd', expectedVersion: 1, idempotencyKey: 'k');
    });

    for (final c in _saveUpdateCases) {
      test('save_${c.name}', () => expect(() => _checkSave(c.args), _contextInvalid(c.message)));
      test(
        'update_${c.name}',
        () => expect(() => _checkUpdate(c.args), _contextInvalid(c.message)),
      );
    }

    test('update_blank_draft_id', () {
      expect(() => _checkUpdate(_Args(draftId: ' ')), _contextInvalid('draftId is required.'));
    });
    test('update_version_zero', () {
      expect(
        () => _checkUpdate(_Args(version: 0)),
        _contextInvalid('expectedVersion must be positive.'),
      );
    });
    test('cancel_blank_draft_id', () {
      expect(
        () => checkCancelDraft(draftId: ' ', expectedVersion: 1, idempotencyKey: 'k'),
        _contextInvalid('draftId is required.'),
      );
    });
    test('cancel_blank_key', () {
      expect(
        () => checkCancelDraft(draftId: 'd', expectedVersion: 1, idempotencyKey: ''),
        _contextInvalid('idempotencyKey is required.'),
      );
    });
    test('cancel_version_zero', () {
      expect(
        () => checkCancelDraft(draftId: 'd', expectedVersion: 0, idempotencyKey: 'k'),
        _contextInvalid('expectedVersion must be positive.'),
      );
    });

    test('boundaries', () {
      _checkSave(_Args(lines: [_line(manualBp: 10000, total: 0)]));
      _checkSave(_Args(lines: [_line(manualBp: 0, total: 5)]));
      _checkSave(_Args(lines: [_line(lineCurrency: 'vnd')]));
      _checkSave(_Args(lines: [_line(manualDiscount: 10, total: 123)]));
      _checkSave(_Args(currency: ' vnd '));
    });
  });
}
