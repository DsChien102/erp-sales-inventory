import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/pricing/data/customer_price_rule_repository.dart';
import 'package:erp/features/pricing/data/pricing_errors.dart';
import 'package:erp/features/pricing/logic/price_rule_list_filters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'pricing_parity_expectations.dart';

void main() {
  group('CustomerPriceRuleRepository', () {
    late _RecordingRpc rpc;
    late int tenantReadCount;
    late CustomerPriceRuleRepository repo;

    setUp(() {
      rpc = _RecordingRpc();
      tenantReadCount = 0;
      repo = CustomerPriceRuleRepository(
        rpc: rpc,
        tenantId: () async {
          tenantReadCount++;
          return parityTenantId;
        },
      );
    });

    test('create_calls_only_create_rpc', () async {
      rpc.nextCallResult = sampleCreateResultJson();

      await repo.create(
        customerId: parityCustomerId,
        productId: parityProductId,
        productUnitId: parityProductUnitId,
        rulePriceMinor: 90000,
        currencyCode: 'VND',
        effectiveFrom: parityEffectiveFrom,
        effectiveTo: parityEffectiveTo,
        note: parityRawNote,
        acknowledgeFloorWarning: true,
        acknowledgeOverwrite: true,
        idempotencyKey: parityPaddedIdempotencyKey,
      );

      expect(rpc.calls, hasLength(1));
      final firstCall = rpc.calls.first;
      expect(firstCall.schema, 'pricing');
      expect(firstCall.rpc, 'create_customer_price_rule');
      final firstRuleId = firstCall.params!['p_rule_id'] as String;
      expect(Uuid.isValidUUID(fromString: firstRuleId), isTrue);
      expect(firstCall.params!['p_idempotency_key'], parityIdempotencyKey);

      await repo.create(
        customerId: parityCustomerId,
        productId: parityProductId,
        productUnitId: parityProductUnitId,
        rulePriceMinor: 90000,
        currencyCode: 'VND',
        effectiveFrom: parityEffectiveFrom,
        effectiveTo: parityEffectiveTo,
        note: parityRawNote,
        acknowledgeFloorWarning: true,
        acknowledgeOverwrite: true,
        idempotencyKey: parityPaddedIdempotencyKey,
      );

      expect(rpc.calls, hasLength(2));
      final secondCall = rpc.calls[1];
      final secondRuleId = secondCall.params!['p_rule_id'] as String;
      expect(Uuid.isValidUUID(fromString: secondRuleId), isTrue);
      expect(secondRuleId, isNot(equals(firstRuleId)));
      expect(secondCall.params!['p_idempotency_key'], parityIdempotencyKey);
    });

    test('update_calls_only_update_rpc', () async {
      rpc.nextCallResult = sampleDetailJson();

      await repo.update(
        ruleId: parityRuleId,
        expectedVersion: 3,
        rulePriceMinor: 95000,
        effectiveFrom: parityEffectiveFrom,
        effectiveTo: parityEffectiveTo,
        note: parityRawNote,
        acknowledgeFloorWarning: true,
        acknowledgeOverwrite: true,
      );

      expect(rpc.calls, hasLength(1));
      expect(rpc.calls.single.rpc, 'update_customer_price_rule');
    });

    test('update_propagates_state_changed', () async {
      rpc.errorToThrow = const PostgrestException(
        message: '{"code":"STATE_CHANGED","message":"Rule version changed"}',
      );

      await expectLater(
        () => repo.update(
          ruleId: parityRuleId,
          expectedVersion: 3,
          rulePriceMinor: 95000,
          effectiveFrom: parityEffectiveFrom,
          acknowledgeFloorWarning: false,
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            PricingErrorCodes.stateChanged,
          ),
        ),
      );
      expect(rpc.calls, hasLength(1));
    });

    test('reenable_sends_acknowledge_overwrite', () async {
      rpc.nextCallResult = sampleDetailJson();

      await repo.reenable(
        ruleId: parityRuleId,
        expectedVersion: 4,
        businessDate: parityBusinessDate,
        precheckToken: parityPrecheckToken,
        acknowledgeFloorWarning: true,
        acknowledgeOverwrite: true,
      );
      expect(
        rpc.calls.first.params!['p_acknowledge_overwrite'],
        isTrue,
      );

      await repo.reenable(
        ruleId: parityRuleId,
        expectedVersion: 4,
        businessDate: parityBusinessDate,
        precheckToken: parityPrecheckToken,
        acknowledgeFloorWarning: true,
      );
      expect(
        rpc.calls[1].params!['p_acknowledge_overwrite'],
        isFalse,
      );
    });

    test('rule_blocks_before_rpc', () async {
      await expectLater(
        () => repo.create(
          customerId: parityCustomerId,
          productId: parityProductId,
          productUnitId: parityProductUnitId,
          rulePriceMinor: 0,
          currencyCode: 'VND',
          effectiveFrom: parityEffectiveFrom,
          acknowledgeFloorWarning: false,
          idempotencyKey: parityIdempotencyKey,
        ),
        throwsA(
          isA<AppException>()
              .having((e) => e.code, 'code', PricingErrorCodes.validationError)
              .having(
                (e) => e.details?['fieldErrors'],
                'fieldErrors',
                {'rulePriceMinor': 'must_be_positive'},
              ),
        ),
      );
      expect(rpc.calls, isEmpty);

      await expectLater(
        () => repo.getDetail(
          ruleId: 'x',
          businessDate: parityBusinessDate,
        ),
        throwsA(
          isA<AppException>()
              .having((e) => e.code, 'code', PricingErrorCodes.validationError)
              .having(
                (e) => e.details?['fieldErrors'],
                'fieldErrors',
                {'ruleId': 'invalid'},
              ),
        ),
      );
      expect(rpc.calls, isEmpty);
    });

    test('malformed_json_is_system_error', () async {
      rpc.nextCallResult = {'items': 1};

      await expectLater(
        () => repo.search(businessDate: parityBusinessDate),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            PricingErrorCodes.systemError,
          ),
        ),
      );
    });

    test('tenant_read_each_call', () async {
      rpc.nextCallResult = sampleDetailJson();

      await repo.getDetail(
        ruleId: parityRuleId,
        businessDate: parityBusinessDate,
      );
      await repo.disable(
        ruleId: parityRuleId,
        expectedVersion: 1,
      );

      expect(tenantReadCount, 2);
    });

    test('local_calendar_date_at_00_30_is_not_converted_to_utc', () async {
      rpc.nextCallResult = sampleDetailJson();

      await repo.getDetail(
        ruleId: parityRuleId,
        businessDate: DateTime(2026, 11, 4, 0, 30),
      );

      expect(rpc.calls.single.params!['p_business_date'], '2026-11-04');
    });

    test('h2_search_sends_sort_and_window', () async {
      rpc.nextCallResult = sampleSearchResultJson();

      await repo.search(
        businessDate: parityBusinessDate,
        sort: PriceRuleSortOption.priceDesc,
        updatedWithin: PriceRuleUpdatedWithin.last30Days,
      );

      final params = rpc.calls.single.params!;
      expect(params['p_sort'], 'price_desc');
      expect(params['p_updated_within_days'], 30);
    });

    test('h2_search_defaults', () async {
      rpc.nextCallResult = sampleSearchResultJson();

      await repo.search(businessDate: parityBusinessDate);

      final params = rpc.calls.single.params!;
      expect(params['p_sort'], 'updated_at_desc');
      expect(params['p_updated_within_days'], isNull);
    });

    test('h5_update_sends_reason', () async {
      rpc.nextCallResult = sampleDetailJson();

      await repo.update(
        ruleId: parityRuleId,
        expectedVersion: 1,
        rulePriceMinor: 100000,
        effectiveFrom: parityEffectiveFrom,
        note: parityRawNote,
        acknowledgeFloorWarning: true,
        changeReason: '  Theo hợp đồng Q3 ',
      );

      final params = rpc.calls.single.params!;
      expect(params['p_reason'], 'Theo hợp đồng Q3');
      expect(params['p_note'], parityNormalizedNote);
    });

    test('h5_update_blank_reason_null', () async {
      rpc.nextCallResult = sampleDetailJson();

      await repo.update(
        ruleId: parityRuleId,
        expectedVersion: 1,
        rulePriceMinor: 100000,
        effectiveFrom: parityEffectiveFrom,
        acknowledgeFloorWarning: true,
        changeReason: '   ',
      );

      final params = rpc.calls.single.params!;
      expect(params['p_reason'], isNull);
    });

    test('h4_search_parses_total_count', () async {
      rpc.nextCallResult = sampleSearchResultJson()..['total_count'] = 45;

      final result = await repo.search(businessDate: parityBusinessDate);

      expect(result.totalCount, 45);
    });

    test('h6_detail_parses_names', () async {
      rpc.nextCallResult = sampleDetailJson()
        ..['updated_by_name'] = 'Nguyễn Lan'
        ..['disabled_by_name'] = null;

      final result = await repo.getDetail(
        ruleId: parityRuleId,
        businessDate: parityBusinessDate,
      );

      expect(result.updatedByName, 'Nguyễn Lan');
      expect(result.disabledByName, isNull);
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

