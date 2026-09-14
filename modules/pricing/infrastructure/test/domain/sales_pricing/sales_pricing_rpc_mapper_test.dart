import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_infrastructure/src/domain/sales_pricing/sales_pricing_rpc_mapper.dart';
import 'package:vet45_pricing_infrastructure/src/domain/sales_pricing/supabase_sales_pricing_read_gateway.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../support/fake_pricing_rpc_supabase.dart';

void main() {
  test(
    'preview params preserve stable line ids and nullable manual intents',
    () {
      expect(SalesPricingRpcMapper.previewParams(_input), {
        'p_tenant_id': 'tenant-1',
        'p_store_id': 'store-1',
        'p_customer_id': 'customer-1',
        'p_currency_code': 'VND',
        'p_context_version': 3,
        'p_effective_at': '2026-08-10T08:00:00.000Z',
        'p_lines': [
          {
            'local_line_id': 'line-1',
            'product_id': 'product-1',
            'product_unit_id': 'unit-1',
            'quantity_micros': 1000000,
            'manual_unit_price_minor': null,
            'manual_discount_minor': null,
            'manual_discount_basis_points': null,
          },
        ],
      });
    },
  );

  test('preview mapper accepts one complete response per requested line', () {
    final result = SalesPricingRpcMapper.previewFromPayload(
      _previewPayload(),
      expectedContextVersion: 3,
      expectedCurrencyCode: 'VND',
      expectedLocalLineIds: const ['line-1'],
    );

    expect(result.contextVersion, 3);
    expect(result.previewToken, 'preview-token');
    expect(result.lines.single.localLineId, 'line-1');
    expect(result.lines.single.appliedUnitPriceMinor, 100000);
  });

  test(
    'preview mapper rejects missing/duplicate lines, currency, money, and version',
    () {
      final missing = _previewPayload()..['lines'] = <Object?>[];
      final duplicate = _previewPayload()
        ..['lines'] = [_previewLine(), _previewLine()];
      final wrongCurrency = _previewPayload()..['currency_code'] = 'USD';
      final negative = _previewPayload();
      (negative['lines'] as List).first['line_total_minor'] = -1;
      final wrongVersion = _previewPayload()..['context_version'] = 4;

      for (final payload in [
        missing,
        duplicate,
        wrongCurrency,
        negative,
        wrongVersion,
      ]) {
        expect(
          () => SalesPricingRpcMapper.previewFromPayload(
            payload,
            expectedContextVersion: 3,
            expectedCurrencyCode: 'VND',
            expectedLocalLineIds: const ['line-1'],
          ),
          throwsA(isA<PricingBlockedException>()),
        );
      }
    },
  );

  test(
    'manual mapper distinguishes allowed, acknowledgement, and blocked results',
    () {
      final allowed = SalesPricingRpcMapper.manualEvaluationFromPayload(
        _manualPayload(),
      );
      final acknowledgement = SalesPricingRpcMapper.manualEvaluationFromPayload(
        _manualPayload()
          ..['requires_acknowledgement'] = true
          ..['floor_price_minor'] = 90000
          ..['can_view_floor'] = true
          ..['warning_codes'] = ['BELOW_FLOOR'],
      );
      final blocked = SalesPricingRpcMapper.manualEvaluationFromPayload(
        _manualPayload()
          ..['allowed'] = false
          ..['normalized_unit_price_minor'] = 80000
          ..['blocking_code'] = 'FLOOR_OVERRIDE_REQUIRED',
      );

      expect(allowed.allowed, isTrue);
      expect(acknowledgement.requiresAcknowledgement, isTrue);
      expect(acknowledgement.floorPriceMinor, 90000);
      expect(blocked.allowed, isFalse);
      expect(blocked.blockingCode, 'FLOOR_OVERRIDE_REQUIRED');
    },
  );

  test(
    'gateway calls exact preview and manual RPCs without fallback',
    () async {
      final supabase = FakePricingRpcSupabase()
        ..registerHandler(
          'preview_sales_working_state_pricing',
          (_) async => _previewPayload(),
        )
        ..registerHandler(
          'evaluate_sales_manual_price',
          (_) async => _manualPayload(),
        );
      final gateway = SupabaseSalesPricingReadGateway(
        rpcClient: SupabaseSchemaRpcClient(
          supabase: supabase,
          schema: 'pricing',
          mapError: (error, [stackTrace]) => RpcException(error.toString()),
        ),
      );

      await gateway.previewWorkingState(_input);
      await gateway.evaluateManualPrice(_manualQuery());

      expect(
        supabase.calls.first.functionName,
        'preview_sales_working_state_pricing',
      );
      expect(supabase.calls.first.params?['p_lines'], isA<List<dynamic>>());
      expect(supabase.calls.last.functionName, 'evaluate_sales_manual_price');
      expect(supabase.calls.last.params, {
        'p_tenant_id': 'tenant-1',
        'p_store_id': 'store-1',
        'p_customer_id': 'customer-1',
        'p_product_id': 'product-1',
        'p_product_unit_id': 'unit-1',
        'p_quantity_micros': 1000000,
        'p_currency_code': 'VND',
        'p_context_version': 3,
        'p_manual_unit_price_minor': 90000,
        'p_manual_discount_minor': null,
        'p_manual_discount_basis_points': null,
        'p_acknowledge_below_floor': false,
      });
    },
  );
}

final _input = SalesWorkingStatePricingInput(
  tenantId: 'tenant-1',
  storeId: 'store-1',
  customerId: 'customer-1',
  currencyCode: 'VND',
  contextVersion: 3,
  effectiveAt: DateTime.parse('2026-08-10T15:00:00+07:00').toUtc(),
  lines: const [
    SalesPricingLineInput(
      localLineId: 'line-1',
      productId: 'product-1',
      productUnitId: 'unit-1',
      quantityMicros: 1000000,
    ),
  ],
);

EvaluateSalesManualPriceQuery _manualQuery() => EvaluateSalesManualPriceQuery(
  tenantId: 'tenant-1',
  storeId: 'store-1',
  customerId: 'customer-1',
  productId: 'product-1',
  productUnitId: 'unit-1',
  quantityMicros: 1000000,
  currencyCode: 'VND',
  contextVersion: 3,
  manualUnitPriceMinor: 90000,
  acknowledgeBelowFloor: false,
);

Map<String, dynamic> _previewPayload() => {
  'context_version': 3,
  'preview_token': 'preview-token',
  'currency_code': 'VND',
  'lines': [_previewLine()],
};

Map<String, dynamic> _previewLine() => {
  'local_line_id': 'line-1',
  'applied_unit_price_minor': 100000,
  'discount_minor': 0,
  'line_total_minor': 100000,
  'source_code': 'LIST_PRICE',
  'list_price_minor': 100000,
  'floor_price_minor': 90000,
  'warning_codes': <String>[],
  'blocking_codes': <String>[],
};

Map<String, dynamic> _manualPayload() => {
  'allowed': true,
  'requires_acknowledgement': false,
  'normalized_unit_price_minor': 90000,
  'floor_price_minor': null,
  'can_view_floor': false,
  'warning_codes': <String>[],
  'blocking_code': null,
  'message': null,
};
