import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/pricing/data/models.dart';
import 'package:erp/features/pricing/data/pricing_errors.dart';
import 'package:erp/features/pricing/data/sales_pricing_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pricing_parity_expectations.dart';

void main() {
  group('SalesPricingRepository', () {
    late _RecordingRpc rpc;
    late SalesPricingRepository repo;

    setUp(() {
      rpc = _RecordingRpc();
      repo = SalesPricingRepository(
        rpc: rpc,
        tenantId: () async => parityTenantId,
      );
    });

    test('preview_rejects_mismatched_context', () async {
      rpc.nextCallResult = sampleSalesPreviewJson()..['context_version'] = 99;

      await expectLater(
        () => repo.preview(
          storeId: parityStoreId,
          customerId: parityCustomerId,
          currencyCode: 'VND',
          contextVersion: 3,
          effectiveAt: parityEffectiveAt,
          lines: const [
            SalesPricingLineInput(
              localLineId: 'line-1',
              productId: parityProductId,
              productUnitId: parityProductUnitId,
              quantityMicros: 1000000,
            ),
            SalesPricingLineInput(
              localLineId: 'line-2',
              productId: '55555555-5555-4555-8555-555555555555',
              productUnitId: '66666666-6666-4666-8666-666666666666',
              quantityMicros: 2000000,
              manualUnitPriceMinor: 85000,
            ),
          ],
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            PricingErrorCodes.systemError,
          ),
        ),
      );
      expect(rpc.calls, hasLength(1));
    });

    test('preview_empty_lines_blocked', () async {
      await expectLater(
        () => repo.preview(
          storeId: parityStoreId,
          customerId: parityCustomerId,
          currencyCode: 'VND',
          contextVersion: 3,
          effectiveAt: parityEffectiveAt,
          lines: const [],
        ),
        throwsA(
          isA<AppException>()
              .having((e) => e.code, 'code', PricingErrorCodes.validationError)
              .having(
                (e) => e.serverMessage,
                'serverMessage',
                'At least one pricing line is required.',
              ),
        ),
      );
      expect(rpc.calls, isEmpty);
    });

    test('evaluate_returns_result_when_ack_required', () async {
      rpc.nextCallResult = sampleSalesManualEvaluationJson()
        ..['requires_acknowledgement'] = true;

      final dto = await repo.evaluateManualPrice(
        storeId: parityStoreId,
        customerId: parityCustomerId,
        productId: parityProductId,
        productUnitId: parityProductUnitId,
        quantityMicros: 1000000,
        currencyCode: 'VND',
        contextVersion: 3,
        manualUnitPriceMinor: 90000,
        acknowledgeBelowFloor: false,
      );

      expect(rpc.calls, hasLength(1));
      expect(dto.requiresAcknowledgement, isTrue);
      expect(dto.allowed, isTrue);
    });

    test('preview_accepts_lowercase_currency', () async {
      rpc.nextCallResult = sampleSalesPreviewJson();

      final dto = await repo.preview(
        storeId: parityStoreId,
        customerId: parityCustomerId,
        currencyCode: ' vnd ',
        contextVersion: 3,
        effectiveAt: parityEffectiveAt,
        lines: const [
          SalesPricingLineInput(
            localLineId: 'line-1',
            productId: parityProductId,
            productUnitId: parityProductUnitId,
            quantityMicros: 1000000,
          ),
          SalesPricingLineInput(
            localLineId: 'line-2',
            productId: '55555555-5555-4555-8555-555555555555',
            productUnitId: '66666666-6666-4666-8666-666666666666',
            quantityMicros: 2000000,
            manualUnitPriceMinor: 85000,
          ),
        ],
      );

      expect(rpc.calls, hasLength(1));
      expect(rpc.calls.single.params!['p_currency_code'], 'VND');
      expectSalesPreview(dto);
    });
  });
}

class _RpcCall {
  _RpcCall(this.schema, this.rpc, this.params);
  final String schema;
  final String rpc;
  final Map<String, dynamic>? params;
}

class _RecordingRpc implements SupabaseRpc {
  final calls = <_RpcCall>[];
  Object? nextCallResult;
  Object? errorToThrow;

  @override
  Future<dynamic> call(
    String schema,
    String rpc, {
    Map<String, dynamic>? params,
  }) async {
    calls.add(_RpcCall(schema, rpc, params));
    if (errorToThrow != null) {
      if (errorToThrow is AppException) {
        throw errorToThrow!;
      }
      throw AppException.from(errorToThrow!);
    }
    return nextCallResult;
  }

  @override
  Future<List<Map<String, dynamic>>> rows(
    String schema,
    String rpc, {
    Map<String, dynamic>? params,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> firstRow(
    String schema,
    String rpc, {
    Map<String, dynamic>? params,
  }) => throw UnimplementedError();
}

