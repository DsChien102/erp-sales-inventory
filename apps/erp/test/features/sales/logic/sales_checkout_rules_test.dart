// ignore_for_file: depend_on_referenced_packages

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/logic/sales_checkout_rules.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart';

typedef _Case = ({
  String name,
  String storeId,
  String currency,
  String key,
  String hash,
  String corr,
  List<CheckoutLineInput> lines,
  List<PaymentIntentInput> intents,
  String message,
});

CheckoutLineInput _line({String p = 'p', String u = 'u', int q = 1000000}) => CheckoutLineInput(
  productId: p,
  productUnitId: u,
  quantity: QuantityDto(quantityMicros: q),
);

PaymentIntentInput _intent({int amount = 100, String cur = 'VND'}) => PaymentIntentInput(
  method: SalesPaymentMethod.cash,
  amount: MoneyDto(amountMinor: amount, currencyCode: cur),
);

_Case _c(
  String name,
  String message, {
  String storeId = 's',
  String currency = 'VND',
  String key = 'k',
  String hash = 'h',
  String corr = 'c',
  List<CheckoutLineInput>? lines,
  List<PaymentIntentInput>? intents,
}) => (
  name: name,
  storeId: storeId,
  currency: currency,
  key: key,
  hash: hash,
  corr: corr,
  lines: lines ?? [_line()],
  intents: intents ?? const [],
  message: message,
);

final _cases = <_Case>[
  _c('storeId', 'storeId is required.', storeId: ' '),
  _c('currencyCode', 'currencyCode is required.', currency: ''),
  _c('idempotencyKey', 'idempotencyKey is required.', key: ''),
  _c('payloadHash', 'payloadHash is required.', hash: ' '),
  _c('correlationId', 'correlationId is required.', corr: ''),
  _c('no lines', 'Finalize checkout requires at least one line.', lines: const []),
  _c('productId', 'productId is required.', lines: [_line(p: '')]),
  _c('productUnitId', 'productUnitId is required.', lines: [_line(u: ' ')]),
  _c('quantity 0', 'Checkout line quantity must be positive.', lines: [_line(q: 0)]),
  _c('amount 0', 'Payment intent amount must be greater than zero.', intents: [_intent(amount: 0)]),
  _c('payment currency', 'paymentCurrencyCode is required.', intents: [_intent(cur: ' ')]),
  // thứ tự: storeId đứng trước idempotencyKey
  _c('order storeId first', 'storeId is required.', storeId: '', key: ''),
];

void main() {
  void run(_Case c) => checkFinalize(
    storeId: c.storeId,
    currencyCode: c.currency,
    idempotencyKey: c.key,
    payloadHash: c.hash,
    correlationId: c.corr,
    lines: c.lines,
    paymentIntents: c.intents,
  );

  group('new', () {
    test('valid passes', () {
      checkFinalize(
        storeId: 's',
        currencyCode: 'VND',
        idempotencyKey: 'k',
        payloadHash: 'h',
        correlationId: 'c',
        lines: [_line()],
        paymentIntents: [_intent()],
      );
    });
    for (final c in _cases) {
      test(c.name, () {
        expect(
          () => run(c),
          throwsA(
            isA<AppException>()
                .having((e) => e.code, 'code', 'CONTEXT_INVALID')
                .having((e) => e.serverMessage, 'msg', c.message),
          ),
        );
      });
    }
  });
}
