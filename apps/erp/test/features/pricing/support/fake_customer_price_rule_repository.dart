import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/pricing/data/customer_price_rule_repository.dart';
import 'package:erp/features/pricing/data/models.dart';
import 'package:erp/features/pricing/logic/price_rule_list_filters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

import 'fake_pricing_backend.dart';

class _UnusedClient extends Fake implements SupabaseClient {}

final _unusedRpc = SupabaseRpc(_UnusedClient());

final class FakePricingCall {
  const FakePricingCall(this.method, this.args);

  final String method;
  final Map<String, Object?> args;
}

class FakeCustomerPriceRuleRepository extends CustomerPriceRuleRepository {
  FakeCustomerPriceRuleRepository({
    this.searchScenario = FakePricingScenario.searchRulesDefault,
    this.searchAvailableActions,
    this.detailScenario = FakePricingScenario.ruleDetailActive,
    this.historyScenario = FakePricingScenario.historyMixedSources,
    this.createScenario = FakePricingScenario.createRuleOk,
    this.updateScenario = FakePricingScenario.updateRuleOk,
    this.disableScenario = FakePricingScenario.disableRuleOk,
    this.reenableScenario = FakePricingScenario.reenableOk,
    this.reenablePrecheckScenario = FakePricingScenario.reenablePrecheckValid,
    this.resolveScenario = FakePricingScenario.resolveApplicableOk,
  }) : super(rpc: _unusedRpc, tenantId: () async => 'tenant-test');

  FakePricingScenario searchScenario;
  List<String>? searchAvailableActions;
  FakePricingScenario detailScenario;
  FakePricingScenario historyScenario;
  FakePricingScenario createScenario;
  FakePricingScenario updateScenario;
  FakePricingScenario disableScenario;
  FakePricingScenario reenableScenario;
  FakePricingScenario reenablePrecheckScenario;
  FakePricingScenario resolveScenario;

  final List<FakePricingCall> calls = [];

  int get searchCalls => calls.where((c) => c.method == 'search').length;

  @override
  Future<CustomerPriceRuleSearchResultDto> search({
    required DateTime businessDate,
    String? q,
    CustomerPriceRuleQuickFilter quickFilter = CustomerPriceRuleQuickFilter.all,
    List<CustomerPriceRuleDerivedStatus> statuses = const [],
    List<CustomerPriceRuleSourceType> sources = const [],
    String? customerId,
    String? productId,
    String? cursor,
    int limit = 20,
    PriceRuleSortOption sort = PriceRuleSortOption.updatedAtDesc,
    PriceRuleUpdatedWithin? updatedWithin,
  }) async {
    calls.add(
      FakePricingCall('search', {
        'businessDate': businessDate,
        'q': q,
        'quickFilter': quickFilter,
        'statuses': statuses,
        'sources': sources,
        'customerId': customerId,
        'productId': productId,
        'cursor': cursor,
        'limit': limit,
        'sort': sort,
        'updatedWithin': updatedWithin,
      }),
    );
    final result = FakePricingBackend(scenario: searchScenario).search(
      businessDate: businessDate,
      q: q,
      quickFilter: quickFilter,
      statuses: statuses,
      sources: sources,
      customerId: customerId,
      productId: productId,
      cursor: cursor,
      limit: limit,
      sort: sort,
      updatedWithin: updatedWithin,
    );
    final overrideActions = searchAvailableActions;
    if (overrideActions == null) return result;
    return CustomerPriceRuleSearchResultDto(
      page: result.page,
      availableActions: overrideActions,
      totalCount: result.totalCount,
    );
  }

  @override
  Future<CustomerPriceRuleDetailDto> getDetail({
    required String ruleId,
    required DateTime businessDate,
  }) async {
    calls.add(
      FakePricingCall('getDetail', {
        'ruleId': ruleId,
        'businessDate': businessDate,
      }),
    );
    return FakePricingBackend(
      scenario: detailScenario,
    ).getDetail(ruleId: ruleId, businessDate: businessDate);
  }

  @override
  Future<CursorPageDto<CustomerPriceRuleActivityDto>> getHistory({
    required String ruleId,
    String? cursor,
    int limit = 50,
  }) async {
    calls.add(
      FakePricingCall('getHistory', {
        'ruleId': ruleId,
        'cursor': cursor,
        'limit': limit,
      }),
    );
    return FakePricingBackend(
      scenario: historyScenario,
    ).getHistory(ruleId: ruleId, cursor: cursor, limit: limit);
  }

  @override
  Future<CreateCustomerPriceRuleResult> create({
    required String customerId,
    required String productId,
    required String productUnitId,
    required int rulePriceMinor,
    required String currencyCode,
    required DateTime effectiveFrom,
    DateTime? effectiveTo,
    String? note,
    required bool acknowledgeFloorWarning,
    bool acknowledgeOverwrite = false,
    required String idempotencyKey,
  }) async {
    calls.add(
      FakePricingCall('create', {
        'customerId': customerId,
        'productId': productId,
        'productUnitId': productUnitId,
        'rulePriceMinor': rulePriceMinor,
        'currencyCode': currencyCode,
        'effectiveFrom': effectiveFrom,
        'effectiveTo': effectiveTo,
        'note': note,
        'acknowledgeFloorWarning': acknowledgeFloorWarning,
        'acknowledgeOverwrite': acknowledgeOverwrite,
        'idempotencyKey': idempotencyKey,
      }),
    );
    return FakePricingBackend(scenario: createScenario).create(
      customerId: customerId,
      productId: productId,
      productUnitId: productUnitId,
      rulePriceMinor: rulePriceMinor,
      currencyCode: currencyCode,
      effectiveFrom: effectiveFrom,
      effectiveTo: effectiveTo,
      note: note,
      acknowledgeFloorWarning: acknowledgeFloorWarning,
      acknowledgeOverwrite: acknowledgeOverwrite,
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<CustomerPriceRuleDetailDto> update({
    required String ruleId,
    required int expectedVersion,
    required int rulePriceMinor,
    required DateTime effectiveFrom,
    DateTime? effectiveTo,
    String? note,
    required bool acknowledgeFloorWarning,
    bool acknowledgeOverwrite = false,
    String? changeReason,
  }) async {
    calls.add(
      FakePricingCall('update', {
        'ruleId': ruleId,
        'expectedVersion': expectedVersion,
        'rulePriceMinor': rulePriceMinor,
        'effectiveFrom': effectiveFrom,
        'effectiveTo': effectiveTo,
        'note': note,
        'acknowledgeFloorWarning': acknowledgeFloorWarning,
        'acknowledgeOverwrite': acknowledgeOverwrite,
        'changeReason': changeReason,
      }),
    );
    return FakePricingBackend(scenario: updateScenario).update(
      ruleId: ruleId,
      expectedVersion: expectedVersion,
      rulePriceMinor: rulePriceMinor,
      effectiveFrom: effectiveFrom,
      effectiveTo: effectiveTo,
      note: note,
      acknowledgeFloorWarning: acknowledgeFloorWarning,
      acknowledgeOverwrite: acknowledgeOverwrite,
      changeReason: changeReason,
    );
  }

  @override
  Future<CustomerPriceRuleDetailDto> disable({
    required String ruleId,
    required int expectedVersion,
    String? reason,
  }) async {
    calls.add(
      FakePricingCall('disable', {
        'ruleId': ruleId,
        'expectedVersion': expectedVersion,
        'reason': reason,
      }),
    );
    return FakePricingBackend(scenario: disableScenario).disable(
      ruleId: ruleId,
      expectedVersion: expectedVersion,
      reason: reason,
    );
  }

  @override
  Future<CustomerPriceRuleReenablePrecheckDto> precheckReenable({
    required String ruleId,
    required int expectedVersion,
    required DateTime businessDate,
  }) async {
    calls.add(
      FakePricingCall('precheckReenable', {
        'ruleId': ruleId,
        'expectedVersion': expectedVersion,
        'businessDate': businessDate,
      }),
    );
    return FakePricingBackend(
      scenario: reenablePrecheckScenario,
    ).precheckReenable(
      ruleId: ruleId,
      expectedVersion: expectedVersion,
      businessDate: businessDate,
    );
  }

  @override
  Future<CustomerPriceRuleDetailDto> reenable({
    required String ruleId,
    required int expectedVersion,
    required DateTime businessDate,
    String? precheckToken,
    required bool acknowledgeFloorWarning,
    bool acknowledgeOverwrite = false,
  }) async {
    calls.add(
      FakePricingCall('reenable', {
        'ruleId': ruleId,
        'expectedVersion': expectedVersion,
        'businessDate': businessDate,
        'precheckToken': precheckToken,
        'acknowledgeFloorWarning': acknowledgeFloorWarning,
        'acknowledgeOverwrite': acknowledgeOverwrite,
      }),
    );
    return FakePricingBackend(scenario: reenableScenario).reenable(
      ruleId: ruleId,
      expectedVersion: expectedVersion,
      businessDate: businessDate,
      precheckToken: precheckToken,
      acknowledgeFloorWarning: acknowledgeFloorWarning,
      acknowledgeOverwrite: acknowledgeOverwrite,
    );
  }

  @override
  Future<ResolveApplicableCustomerPriceRuleResultDto> resolveApplicable({
    required String customerId,
    required String productId,
    required String productUnitId,
    required DateTime businessDate,
  }) async {
    calls.add(
      FakePricingCall('resolveApplicable', {
        'customerId': customerId,
        'productId': productId,
        'productUnitId': productUnitId,
        'businessDate': businessDate,
      }),
    );
    return FakePricingBackend(scenario: resolveScenario).resolveApplicable(
      customerId: customerId,
      productId: productId,
      productUnitId: productUnitId,
      businessDate: businessDate,
    );
  }
}

