import 'package:test/test.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_pricing_infrastructure/infrastructure.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  final request = RememberedPriceRequest.receive(
    id: '00000000-0000-4000-8000-000000000201',
    tenantId: '00000000-0000-4000-8000-000000000100',
    actorId: '00000000-0000-4000-8000-000000000099',
    sourceOrderId: '00000000-0000-4000-8000-000000000101',
    sourceOrderLineId: '00000000-0000-4000-8000-000000000102',
    customerId: '00000000-0000-4000-8000-000000000103',
    productId: '00000000-0000-4000-8000-000000000104',
    productUnitId: '00000000-0000-4000-8000-000000000105',
    soldPrice: Money(amountMinor: 90000, currencyCode: 'VND'),
    soldAt: DateTime.utc(2026, 7, 16, 1, 30),
    idempotencyKey: 'order-line-102',
  );

  test('params use exact RPC keys and normalized request fields', () {
    final params = RememberedPriceRpcMapper.params(request);

    expect(params, {
      'p_tenant_id': request.tenantId,
      'p_request_id': request.id,
      'p_source_order_id': request.sourceOrderId,
      'p_source_order_line_id': request.sourceOrderLineId,
      'p_customer_id': request.customerId,
      'p_product_id': request.productId,
      'p_product_unit_id': request.productUnitId,
      'p_sold_price_minor': request.soldPrice.amountMinor,
      'p_currency_code': request.soldPrice.currencyCode,
      'p_sold_at': request.soldAt.toIso8601String(),
      'p_idempotency_key': request.idempotencyKey,
    });
  });

  test('outcomeFromJson maps created outcome strictly', () {
    final outcome = RememberedPriceRpcMapper.outcomeFromJson({
      'request_id': '00000000-0000-4000-8000-000000000201',
      'result_type': 'created',
      'rule_id': '00000000-0000-4000-8000-000000000301',
      'rule_version': 1,
      'reason_code': null,
      'warnings': ['note'],
      'is_replay': false,
    });

    expect(outcome.resultType, RememberedPriceResultType.created);
    expect(outcome.warnings, ['note']);
    expect(outcome.isReplay, isFalse);
  });

  test('outcomeFromJson rejects malformed payloads', () {
    expect(
      () => RememberedPriceRpcMapper.outcomeFromJson({
        'request_id': 'request-1',
        'result_type': 'unknown',
        'warnings': [],
        'is_replay': false,
      }),
      throwsFormatException,
    );
    expect(
      () => RememberedPriceRpcMapper.outcomeFromJson({
        'result_type': 'created',
        'warnings': [],
        'is_replay': false,
      }),
      throwsFormatException,
    );
    expect(
      () => RememberedPriceRpcMapper.outcomeFromJson({
        'request_id': 'request-1',
        'result_type': 'created',
        'rule_version': 0,
        'warnings': [],
        'is_replay': false,
      }),
      throwsFormatException,
    );
    expect(
      () => RememberedPriceRpcMapper.outcomeFromJson({
        'request_id': 'request-1',
        'result_type': 'created',
        'warnings': [],
        'is_replay': false,
      }),
      throwsFormatException,
    );
    expect(
      () => RememberedPriceRpcMapper.outcomeFromJson({
        'request_id': 'request-1',
        'result_type': 'skipped',
        'warnings': [],
        'is_replay': false,
      }),
      throwsFormatException,
    );
    expect(
      () => RememberedPriceRpcMapper.outcomeFromJson({
        'request_id': 'request-1',
        'result_type': 'created',
        'rule_id': 'rule-1',
        'rule_version': 1,
        'warnings': [1],
        'is_replay': false,
      }),
      throwsFormatException,
    );
  });
}
