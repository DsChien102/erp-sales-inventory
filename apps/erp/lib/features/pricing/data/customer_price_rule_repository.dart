import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/pricing/data/mappers/customer_price_rule_json.dart';
import 'package:erp/features/pricing/data/models.dart';
import 'package:erp/features/pricing/data/pricing_errors.dart';
import 'package:erp/features/pricing/logic/price_rule_list_filters.dart';
import 'package:erp/features/pricing/logic/pricing_rules.dart';
import 'package:uuid/uuid.dart';

class CustomerPriceRuleRepository {
  CustomerPriceRuleRepository({
    required SupabaseRpc rpc,
    required Future<String> Function() tenantId,
  }) : _rpc = rpc,
       _tenantId = tenantId;

  final SupabaseRpc _rpc;
  final Future<String> Function() _tenantId;
  static const Uuid _uuid = Uuid();

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
  }) => _guard(() async {
    checkSearch(
      q: q,
      customerId: customerId,
      productId: productId,
      limit: limit,
    );
    final tenantId = await _tenantId();
    final raw = await _rpc.call(
      'pricing',
      'search_customer_price_rules',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_business_date': _date(businessDate),
        'p_q': _normalizeOptional(q),
        'p_quick_filter': _quickFilterWire(quickFilter),
        'p_statuses': statuses.isEmpty
            ? null
            : statuses.map(_derivedStatusWire).toList(growable: false),
        'p_sources': sources.isEmpty
            ? null
            : sources.map(_sourceWire).toList(growable: false),
        'p_customer_id': customerId,
        'p_product_id': productId,
        'p_cursor': _normalizeOptional(cursor),
        'p_limit': limit,
        'p_sort': _sortWire(sort),
        'p_updated_within_days': switch (updatedWithin) {
          null => null,
          PriceRuleUpdatedWithin.last7Days => 7,
          PriceRuleUpdatedWithin.last30Days => 30,
        },
      },
    );
    return CustomerPriceRuleJson.searchResult(
      _asMap(raw, 'search_customer_price_rules'),
    );
  });

  Future<CustomerPriceRuleDetailDto> getDetail({
    required String ruleId,
    required DateTime businessDate,
  }) => _guard(() async {
    checkRuleId(ruleId);
    final tenantId = await _tenantId();
    final raw = await _rpc.call(
      'pricing',
      'get_customer_price_rule_detail',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_rule_id': ruleId.trim(),
        'p_business_date': _date(businessDate),
      },
    );
    return CustomerPriceRuleJson.detail(
      _asMap(raw, 'get_customer_price_rule_detail'),
    );
  });

  Future<CursorPageDto<CustomerPriceRuleActivityDto>> getHistory({
    required String ruleId,
    String? cursor,
    int limit = 50,
  }) => _guard(() async {
    checkHistoryPage(ruleId: ruleId, cursor: cursor, limit: limit);
    final tenantId = await _tenantId();
    final raw = await _rpc.call(
      'pricing',
      'get_customer_price_rule_history',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_rule_id': ruleId.trim(),
        'p_cursor': _normalizeOptional(cursor),
        'p_limit': limit,
      },
    );
    return CustomerPriceRuleJson.historyPage(
      _asMap(raw, 'get_customer_price_rule_history'),
    );
  });

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
  }) => _guard(() async {
    checkCreateRule(
      customerId: customerId,
      productId: productId,
      productUnitId: productUnitId,
      idempotencyKey: idempotencyKey,
      rulePriceMinor: rulePriceMinor,
      currencyCode: currencyCode,
      effectiveFrom: effectiveFrom,
      effectiveTo: effectiveTo,
    );
    final tenantId = await _tenantId();
    final raw = await _rpc.call(
      'pricing',
      'create_customer_price_rule',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_rule_id': _uuid.v4(),
        'p_customer_id': customerId,
        'p_product_id': productId,
        'p_product_unit_id': productUnitId,
        'p_rule_price_minor': rulePriceMinor,
        'p_currency_code': currencyCode.trim().toUpperCase(),
        'p_effective_from': _date(effectiveFrom),
        'p_effective_to': effectiveTo == null ? null : _date(effectiveTo),
        'p_note': normalizeRuleNote(note),
        'p_acknowledge_floor_warning': acknowledgeFloorWarning,
        'p_acknowledge_overwrite': acknowledgeOverwrite,
        'p_idempotency_key': idempotencyKey.trim(),
      },
    );
    return CustomerPriceRuleJson.createResult(
      _asMap(raw, 'create_customer_price_rule'),
    );
  });

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
  }) => _guard(() async {
    checkUpdateRule(
      ruleId: ruleId,
      expectedVersion: expectedVersion,
      rulePriceMinor: rulePriceMinor,
      effectiveFrom: effectiveFrom,
      effectiveTo: effectiveTo,
      changeReason: changeReason,
    );
    final tenantId = await _tenantId();
    final raw = await _rpc.call(
      'pricing',
      'update_customer_price_rule',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_rule_id': ruleId.trim(),
        'p_expected_version': expectedVersion,
        'p_rule_price_minor': rulePriceMinor,
        'p_effective_from': _date(effectiveFrom),
        'p_effective_to': effectiveTo == null ? null : _date(effectiveTo),
        'p_note': normalizeRuleNote(note),
        'p_acknowledge_floor_warning': acknowledgeFloorWarning,
        'p_acknowledge_overwrite': acknowledgeOverwrite,
        'p_reason': _normalizeOptional(changeReason),
      },
    );
    return CustomerPriceRuleJson.detail(
      _asMap(raw, 'update_customer_price_rule'),
    );
  });

  Future<CustomerPriceRuleDetailDto> disable({
    required String ruleId,
    required int expectedVersion,
    String? reason,
  }) => _guard(() async {
    checkDisableRule(
      ruleId: ruleId,
      expectedVersion: expectedVersion,
      reason: reason,
    );
    final tenantId = await _tenantId();
    final raw = await _rpc.call(
      'pricing',
      'disable_customer_price_rule',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_rule_id': ruleId.trim(),
        'p_expected_version': expectedVersion,
        'p_reason': _normalizeOptional(reason),
      },
    );
    return CustomerPriceRuleJson.detail(
      _asMap(raw, 'disable_customer_price_rule'),
    );
  });

  Future<CustomerPriceRuleReenablePrecheckDto> precheckReenable({
    required String ruleId,
    required int expectedVersion,
    required DateTime businessDate,
  }) => _guard(() async {
    checkPrecheckReenable(ruleId: ruleId, expectedVersion: expectedVersion);
    final tenantId = await _tenantId();
    final raw = await _rpc.call(
      'pricing',
      'precheck_customer_price_rule_reenable',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_rule_id': ruleId.trim(),
        'p_expected_version': expectedVersion,
        'p_business_date': _date(businessDate),
      },
    );
    return CustomerPriceRuleJson.precheck(
      _asMap(raw, 'precheck_customer_price_rule_reenable'),
    );
  });

  Future<CustomerPriceRuleDetailDto> reenable({
    required String ruleId,
    required int expectedVersion,
    required DateTime businessDate,
    String? precheckToken,
    required bool acknowledgeFloorWarning,
    bool acknowledgeOverwrite = false,
  }) => _guard(() async {
    checkReenableRule(
      ruleId: ruleId,
      expectedVersion: expectedVersion,
      precheckToken: precheckToken,
    );
    final tenantId = await _tenantId();
    final raw = await _rpc.call(
      'pricing',
      'reenable_customer_price_rule',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_rule_id': ruleId.trim(),
        'p_expected_version': expectedVersion,
        'p_business_date': _date(businessDate),
        'p_precheck_token': _normalizeOptional(precheckToken),
        'p_acknowledge_floor_warning': acknowledgeFloorWarning,
        'p_acknowledge_overwrite': acknowledgeOverwrite,
      },
    );
    return CustomerPriceRuleJson.detail(
      _asMap(raw, 'reenable_customer_price_rule'),
    );
  });

  Future<ResolveApplicableCustomerPriceRuleResultDto> resolveApplicable({
    required String customerId,
    required String productId,
    required String productUnitId,
    required DateTime businessDate,
  }) => _guard(() async {
    checkResolve(
      customerId: customerId,
      productId: productId,
      productUnitId: productUnitId,
    );
    final tenantId = await _tenantId();
    final raw = await _rpc.call(
      'pricing',
      'resolve_applicable_customer_price_rule',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_customer_id': customerId.trim(),
        'p_product_id': productId.trim(),
        'p_product_unit_id': productUnitId.trim(),
        'p_business_date': _date(businessDate),
      },
    );
    return CustomerPriceRuleJson.resolveResult(
      _asMap(raw, 'resolve_applicable_customer_price_rule'),
    );
  });

  Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (error) {
      throw pricingException(error);
    }
  }

  static Map<String, dynamic> _asMap(Object? payload, String rpcName) {
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    throw FormatException('Expected object payload from $rpcName.');
  }

  static String? _normalizeOptional(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static String _quickFilterWire(CustomerPriceRuleQuickFilter value) =>
      switch (value) {
        CustomerPriceRuleQuickFilter.all => 'all',
        CustomerPriceRuleQuickFilter.applying => 'applying',
        CustomerPriceRuleQuickFilter.belowFloor => 'below_floor',
      };

  static String _derivedStatusWire(CustomerPriceRuleDerivedStatus value) =>
      switch (value) {
        CustomerPriceRuleDerivedStatus.applying => 'applying',
        CustomerPriceRuleDerivedStatus.notYetEffective => 'not_yet_effective',
        CustomerPriceRuleDerivedStatus.disabled => 'disabled',
        CustomerPriceRuleDerivedStatus.expired => 'expired',
        CustomerPriceRuleDerivedStatus.needsReview => 'needs_review',
        CustomerPriceRuleDerivedStatus.deleted => 'deleted',
      };

  static String _sourceWire(CustomerPriceRuleSourceType value) =>
      switch (value) {
        CustomerPriceRuleSourceType.manual => 'manual',
        CustomerPriceRuleSourceType.excelImport => 'excel_import',
        CustomerPriceRuleSourceType.salesOrder => 'sales_order',
        CustomerPriceRuleSourceType.migration => 'migration',
      };

  static String _sortWire(PriceRuleSortOption value) => switch (value) {
    PriceRuleSortOption.updatedAtDesc => 'updated_at_desc',
    PriceRuleSortOption.updatedAtAsc => 'updated_at_asc',
    PriceRuleSortOption.customerNameAsc => 'customer_name_asc',
    PriceRuleSortOption.customerNameDesc => 'customer_name_desc',
    PriceRuleSortOption.priceDesc => 'price_desc',
    PriceRuleSortOption.priceAsc => 'price_asc',
    PriceRuleSortOption.warningsFirst => 'warnings_first',
  };
}
