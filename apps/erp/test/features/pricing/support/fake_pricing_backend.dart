import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/pricing/data/models.dart';
import 'package:erp/features/pricing/data/pricing_errors.dart';
import 'package:erp/features/pricing/logic/price_rule_list_filters.dart';

enum FakePricingScenario {
  createRuleOk,
  createRuleDuplicate,
  createRuleFloorWarning,
  createRuleFloorBlocked,
  createRuleReferenceInvalid,
  createRuleIdempotentRetry,
  createRuleIdempotencyConflict,
  searchRulesDefault,
  searchRulesEmpty,
  searchRulesNoResult,
  searchRulesError,
  ruleDetailActive,
  ruleDetailDisabled,
  ruleDetailNotFound,
  ruleDetailReferenceStale,
  updateRuleOk,
  updateRuleNoop,
  updateRuleStateChanged,
  updateRuleDuplicate,
  updateRuleFloorWarning,
  updateRuleFloorBlocked,
  updateRuleReferenceInvalid,
  updateRuleDisabled,
  disableRuleOk,
  disableRuleAlreadyDisabled,
  disableRuleStateChanged,
  disableRuleDenied,
  disableRuleNotFound,
  disableRuleInvalidStatus,
  resolveApplicableOk,
  resolveApplicableNone,
  resolveApplicableDenied,
  reenablePrecheckValid,
  reenablePrecheckWarning,
  reenablePrecheckBlockedDuplicate,
  reenablePrecheckBlockedExpired,
  reenablePrecheckBlockedReference,
  reenablePrecheckDenied,
  reenablePrecheckNotFound,
  reenablePrecheckInvalidStatus,
  reenableOk,
  reenableFloorOverrideOk,
  reenableStateChanged,
  reenableDuplicate,
  reenableFloorBlocked,
  reenableReferenceInvalid,
  reenableExpired,
  reenableInvalidStatus,
  historyMixedSources,
  historySecondPage,
  historyEmptyLegacy,
  historySystemActor,
  historyNotFound,
  historyMalformedCursor,
  historyDenied,
  historySystemError,
}

const _reenableToken =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

final class FakePricingBackend {
  const FakePricingBackend({this.scenario = FakePricingScenario.createRuleOk});

  final FakePricingScenario scenario;

  CustomerPriceRuleSearchResultDto search({
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
  }) {
    switch (scenario) {
      case FakePricingScenario.searchRulesError:
        throw const AppException(PricingErrorCodes.systemError);
      case FakePricingScenario.searchRulesEmpty:
      case FakePricingScenario.searchRulesNoResult:
        return const CustomerPriceRuleSearchResultDto(
          page: CursorPageDto(items: [], hasMore: false),
          availableActions: [
            PricingAvailableActions.createManual,
            PricingAvailableActions.import,
          ],
          totalCount: 0,
        );
      case FakePricingScenario.searchRulesDefault:
        return _searchResult(businessDate);
      default:
        throw UnsupportedError(
          'FakePricingBackend: ${scenario.name} does not support search.',
        );
    }
  }

  CustomerPriceRuleDetailDto getDetail({
    required String ruleId,
    required DateTime businessDate,
  }) {
    switch (scenario) {
      case FakePricingScenario.ruleDetailNotFound:
        throw const AppException(PricingErrorCodes.notFound);
      case FakePricingScenario.ruleDetailActive:
        return _detail(
          ruleId: ruleId,
          businessDate: businessDate,
          persistedStatus: CustomerPriceRuleStatus.active,
          derivedStatus: CustomerPriceRuleDerivedStatus.applying,
          availableActions: const [
            CustomerPriceRuleAvailableActions.edit,
            CustomerPriceRuleAvailableActions.disable,
            CustomerPriceRuleAvailableActions.history,
          ],
        );
      case FakePricingScenario.ruleDetailDisabled:
        return _detail(
          ruleId: ruleId,
          businessDate: businessDate,
          persistedStatus: CustomerPriceRuleStatus.disabled,
          derivedStatus: CustomerPriceRuleDerivedStatus.disabled,
          availableActions: const [
            CustomerPriceRuleAvailableActions.edit,
            CustomerPriceRuleAvailableActions.reenable,
            CustomerPriceRuleAvailableActions.history,
          ],
          disabledAt: DateTime.utc(2026, 7, 16),
          disabledBy: 'fake-user-1',
        );
      case FakePricingScenario.ruleDetailReferenceStale:
        return _detail(
          ruleId: ruleId,
          businessDate: businessDate,
          persistedStatus: CustomerPriceRuleStatus.active,
          derivedStatus: CustomerPriceRuleDerivedStatus.applying,
          customerDisplayName: 'Phòng khám đã lưu',
          productName: 'Vaccine đã lưu',
          unitName: 'Lọ',
          referenceHealth: const CustomerPriceRuleReferenceHealthDto(
            customerState: CustomerPriceRuleReferenceState.inactive,
            productUnitState: CustomerPriceRuleReferenceState.missing,
            priceBandState: CustomerPriceRulePriceBandState.unavailable,
            issueCodes: [
              'customer_reference_inactive',
              'product_unit_reference_missing',
            ],
            usedStoredPriceBandSnapshot: true,
          ),
          validationOutcome: const RuleValidationOutcomeDto(
            outcome: 'warning',
            warningCodes: ['below_floor_price'],
            blockingCodes: [],
            floorPriceHidden: true,
          ),
          availableActions: const [
            CustomerPriceRuleAvailableActions.edit,
            CustomerPriceRuleAvailableActions.disable,
            CustomerPriceRuleAvailableActions.history,
          ],
        );
      case FakePricingScenario.historyMixedSources:
      case FakePricingScenario.historySecondPage:
      case FakePricingScenario.historyEmptyLegacy:
      case FakePricingScenario.historySystemActor:
      case FakePricingScenario.historyDenied:
      case FakePricingScenario.historySystemError:
      case FakePricingScenario.historyMalformedCursor:
        return _detail(
          ruleId: ruleId,
          businessDate: businessDate,
          persistedStatus: CustomerPriceRuleStatus.active,
          derivedStatus: CustomerPriceRuleDerivedStatus.applying,
          availableActions: const [
            CustomerPriceRuleAvailableActions.history,
          ],
        );
      case FakePricingScenario.historyNotFound:
        throw const AppException(PricingErrorCodes.notFound);
      default:
        throw UnsupportedError(
          'FakePricingBackend: ${scenario.name} does not support detail.',
        );
    }
  }

  CursorPageDto<CustomerPriceRuleActivityDto> getHistory({
    required String ruleId,
    String? cursor,
    int limit = 50,
  }) {
    switch (scenario) {
      case FakePricingScenario.historyNotFound:
        throw const AppException(PricingErrorCodes.notFound);
      case FakePricingScenario.historyMalformedCursor:
        throw const AppException(
          PricingErrorCodes.validationError,
          details: {
            'fieldErrors': {'cursor': 'invalid'},
          },
        );
      case FakePricingScenario.historyDenied:
        throw const AppException(PricingErrorCodes.noPermission);
      case FakePricingScenario.historySystemError:
        throw const AppException(PricingErrorCodes.systemError);
      case FakePricingScenario.historyEmptyLegacy:
        return const CursorPageDto<CustomerPriceRuleActivityDto>(
          items: [],
          hasMore: false,
        );
      case FakePricingScenario.historySystemActor:
        return CursorPageDto<CustomerPriceRuleActivityDto>(
          items: List.unmodifiable([_historySystemActorItem()]),
          hasMore: false,
        );
      case FakePricingScenario.historySecondPage:
        return CursorPageDto<CustomerPriceRuleActivityDto>(
          items: List.unmodifiable([_historyOlderItem()]),
          hasMore: false,
        );
      case FakePricingScenario.historyMixedSources:
        final items = _historyMixedItems();
        return CursorPageDto<CustomerPriceRuleActivityDto>(
          items: List.unmodifiable(items),
          nextCursor: 'page-1-cursor',
          hasMore: true,
        );
      case FakePricingScenario.ruleDetailActive:
      case FakePricingScenario.ruleDetailDisabled:
      case FakePricingScenario.ruleDetailReferenceStale:
      case FakePricingScenario.updateRuleOk:
      case FakePricingScenario.disableRuleOk:
      case FakePricingScenario.reenableOk:
        return const CursorPageDto<CustomerPriceRuleActivityDto>(
          items: [],
          hasMore: false,
        );
      default:
        throw UnsupportedError(
          'FakePricingBackend: ${scenario.name} does not support history.',
        );
    }
  }

  CreateCustomerPriceRuleResult create({
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
  }) {
    switch (scenario) {
      case FakePricingScenario.createRuleDuplicate:
        throw const AppException(PricingErrorCodes.duplicateActiveRule);
      case FakePricingScenario.createRuleFloorBlocked:
        throw const AppException(
          PricingErrorCodes.belowFloorBlocked,
          details: {'reason': 'override_permission_required'},
        );
      case FakePricingScenario.createRuleReferenceInvalid:
        throw const AppException(PricingErrorCodes.referenceInvalid);
      case FakePricingScenario.createRuleIdempotencyConflict:
        throw const AppException(PricingErrorCodes.idempotencyConflict);
      case FakePricingScenario.createRuleFloorWarning:
        return _result(
          customerId: customerId,
          productId: productId,
          productUnitId: productUnitId,
          rulePriceMinor: rulePriceMinor,
          currencyCode: currencyCode,
          effectiveFrom: effectiveFrom,
          effectiveTo: effectiveTo,
          note: note,
          warning: true,
        );
      case FakePricingScenario.createRuleOk:
      case FakePricingScenario.createRuleIdempotentRetry:
        return _result(
          customerId: customerId,
          productId: productId,
          productUnitId: productUnitId,
          rulePriceMinor: rulePriceMinor,
          currencyCode: currencyCode,
          effectiveFrom: effectiveFrom,
          effectiveTo: effectiveTo,
          note: note,
        );
      default:
        throw UnsupportedError(
          'FakePricingBackend: ${scenario.name} does not support create.',
        );
    }
  }

  CustomerPriceRuleDetailDto update({
    required String ruleId,
    required int expectedVersion,
    required int rulePriceMinor,
    required DateTime effectiveFrom,
    DateTime? effectiveTo,
    String? note,
    required bool acknowledgeFloorWarning,
    bool acknowledgeOverwrite = false,
    String? changeReason,
  }) {
    switch (scenario) {
      case FakePricingScenario.updateRuleStateChanged:
        throw const AppException(PricingErrorCodes.stateChanged);
      case FakePricingScenario.updateRuleDuplicate:
        return _updateDetail(
          ruleId: ruleId,
          expectedVersion: expectedVersion,
          rulePriceMinor: rulePriceMinor,
          effectiveFrom: effectiveFrom,
          effectiveTo: effectiveTo,
          note: note,
        );
      case FakePricingScenario.updateRuleFloorBlocked:
        throw const AppException(
          PricingErrorCodes.belowFloorBlocked,
          details: {'reason': 'overridePermissionRequired'},
        );
      case FakePricingScenario.updateRuleReferenceInvalid:
        throw const AppException(PricingErrorCodes.referenceInvalid);
      case FakePricingScenario.updateRuleNoop:
        return _updateDetail(
          ruleId: ruleId,
          expectedVersion: expectedVersion,
          rulePriceMinor: rulePriceMinor,
          effectiveFrom: effectiveFrom,
          effectiveTo: effectiveTo,
          note: note,
          version: expectedVersion,
        );
      case FakePricingScenario.updateRuleFloorWarning:
        return _updateDetail(
          ruleId: ruleId,
          expectedVersion: expectedVersion,
          rulePriceMinor: rulePriceMinor,
          effectiveFrom: effectiveFrom,
          effectiveTo: effectiveTo,
          note: note,
          warning: true,
        );
      case FakePricingScenario.updateRuleDisabled:
        return _updateDetail(
          ruleId: ruleId,
          expectedVersion: expectedVersion,
          rulePriceMinor: rulePriceMinor,
          effectiveFrom: effectiveFrom,
          effectiveTo: effectiveTo,
          note: note,
          disabled: true,
        );
      case FakePricingScenario.updateRuleOk:
        return _updateDetail(
          ruleId: ruleId,
          expectedVersion: expectedVersion,
          rulePriceMinor: rulePriceMinor,
          effectiveFrom: effectiveFrom,
          effectiveTo: effectiveTo,
          note: note,
        );
      default:
        throw UnsupportedError(
          'FakePricingBackend: ${scenario.name} does not support update.',
        );
    }
  }

  CustomerPriceRuleDetailDto disable({
    required String ruleId,
    required int expectedVersion,
    String? reason,
  }) {
    switch (scenario) {
      case FakePricingScenario.disableRuleStateChanged:
        throw const AppException(PricingErrorCodes.stateChanged);
      case FakePricingScenario.disableRuleDenied:
        throw const AppException(PricingErrorCodes.noPermission);
      case FakePricingScenario.disableRuleNotFound:
        throw const AppException(PricingErrorCodes.notFound);
      case FakePricingScenario.disableRuleInvalidStatus:
        throw const AppException(PricingErrorCodes.invalidStatus);
      case FakePricingScenario.disableRuleAlreadyDisabled:
        return _disableDetail(
          ruleId: ruleId,
          expectedVersion: expectedVersion,
          reason: 'Lý do ban đầu',
        );
      case FakePricingScenario.disableRuleOk:
        return _disableDetail(
          ruleId: ruleId,
          expectedVersion: expectedVersion,
          reason: _normalizeOptional(reason),
        );
      default:
        throw UnsupportedError(
          'FakePricingBackend: ${scenario.name} does not support disable.',
        );
    }
  }

  CustomerPriceRuleReenablePrecheckDto precheckReenable({
    required String ruleId,
    required int expectedVersion,
    required DateTime businessDate,
  }) {
    switch (scenario) {
      case FakePricingScenario.reenablePrecheckValid:
        return _reenablePrecheck(
          expectedVersion: expectedVersion,
          businessDate: businessDate,
          outcome: 'valid',
        );
      case FakePricingScenario.reenablePrecheckWarning:
        return _reenablePrecheck(
          expectedVersion: expectedVersion,
          businessDate: businessDate,
          outcome: 'warning',
          warningCodes: const ['below_floor_price'],
        );
      case FakePricingScenario.reenablePrecheckBlockedDuplicate:
        return _reenablePrecheck(
          expectedVersion: expectedVersion,
          businessDate: businessDate,
          outcome: 'valid',
        );
      case FakePricingScenario.reenablePrecheckBlockedExpired:
        return _reenablePrecheck(
          expectedVersion: expectedVersion,
          businessDate: businessDate,
          outcome: 'blocked',
          blockingCodes: const ['effective_period_expired'],
        );
      case FakePricingScenario.reenablePrecheckBlockedReference:
        return _reenablePrecheck(
          expectedVersion: expectedVersion,
          businessDate: businessDate,
          outcome: 'blocked',
          blockingCodes: const ['customer_reference_invalid'],
        );
      case FakePricingScenario.reenablePrecheckDenied:
        throw const AppException(PricingErrorCodes.noPermission);
      case FakePricingScenario.reenablePrecheckNotFound:
        throw const AppException(PricingErrorCodes.notFound);
      case FakePricingScenario.reenablePrecheckInvalidStatus:
        throw const AppException(PricingErrorCodes.invalidStatus);
      case FakePricingScenario.reenableOk:
      case FakePricingScenario.reenableFloorOverrideOk:
      case FakePricingScenario.ruleDetailDisabled:
        return _reenablePrecheck(
          expectedVersion: expectedVersion,
          businessDate: businessDate,
          outcome: 'valid',
        );
      default:
        throw UnsupportedError(
          'FakePricingBackend: ${scenario.name} does not support reenable precheck.',
        );
    }
  }

  CustomerPriceRuleDetailDto reenable({
    required String ruleId,
    required int expectedVersion,
    required DateTime businessDate,
    String? precheckToken,
    required bool acknowledgeFloorWarning,
    bool acknowledgeOverwrite = false,
  }) {
    switch (scenario) {
      case FakePricingScenario.reenableStateChanged:
        throw const AppException(PricingErrorCodes.stateChanged);
      case FakePricingScenario.reenableDuplicate:
        return _reenableDetail(
          ruleId: ruleId,
          expectedVersion: expectedVersion,
        );
      case FakePricingScenario.reenableFloorBlocked:
        throw const AppException(
          PricingErrorCodes.belowFloorBlocked,
          details: {'reason': 'override_permission_required'},
        );
      case FakePricingScenario.reenableReferenceInvalid:
        throw const AppException(PricingErrorCodes.referenceInvalid);
      case FakePricingScenario.reenableExpired:
        throw const AppException(
          PricingErrorCodes.invalidStatus,
          details: {'reason': 'effectivePeriodExpired'},
        );
      case FakePricingScenario.reenableInvalidStatus:
        throw const AppException(PricingErrorCodes.invalidStatus);
      case FakePricingScenario.reenableOk:
        return _reenableDetail(
          ruleId: ruleId,
          expectedVersion: expectedVersion,
        );
      case FakePricingScenario.reenableFloorOverrideOk:
        return _reenableDetail(
          ruleId: ruleId,
          expectedVersion: expectedVersion,
          warning: true,
        );
      default:
        throw UnsupportedError(
          'FakePricingBackend: ${scenario.name} does not support reenable.',
        );
    }
  }

  ResolveApplicableCustomerPriceRuleResultDto resolveApplicable({
    required String customerId,
    required String productId,
    required String productUnitId,
    required DateTime businessDate,
  }) {
    switch (scenario) {
      case FakePricingScenario.resolveApplicableDenied:
        throw const AppException(PricingErrorCodes.noPermission);
      case FakePricingScenario.resolveApplicableNone:
        return const ResolveApplicableCustomerPriceRuleResultDto();
      case FakePricingScenario.resolveApplicableOk:
        return ResolveApplicableCustomerPriceRuleResultDto(
          rule: ApplicableCustomerPriceRuleDto(
            ruleId: '11111111-1111-4111-8111-111111111111',
            price: const MoneyDto(amountMinor: 125000, currencyCode: 'VND'),
            effectivePeriod: EffectivePeriodDto(effectiveFrom: businessDate),
            sourceType: CustomerPriceRuleSourceType.manual,
            version: 2,
          ),
        );
      default:
        throw UnsupportedError(
          'FakePricingBackend: ${scenario.name} does not support resolve.',
        );
    }
  }

  List<CustomerPriceRuleActivityDto> _historyMixedItems() {
    final memory = CustomerPriceRuleActivityDto(
      id: '00000000-0000-4000-8000-000000000033',
      activityType: CustomerPriceRuleActivityType.memoryUpdated,
      actor: const CustomerPriceRuleActivityActorDto(
        actorId: '00000000-0000-4000-8000-000000000099',
        displayName: '5ef27a1c',
        isSystemActor: false,
      ),
      sourceType: CustomerPriceRuleSourceType.salesOrder,
      oldValue: Map.unmodifiable(const {
        'version': 3,
        'rule_price_minor': 120000,
      }),
      newValue: Map.unmodifiable(const {
        'version': 4,
        'rule_price_minor': 125000,
      }),
      reason: null,
      sourceTrace: CustomerPriceRuleActivitySourceTraceDto(
        orderId: '00000000-0000-4000-8000-000000000201',
        orderLineId: '00000000-0000-4000-8000-000000000202',
        memoryRequestId: '00000000-0000-4000-8000-000000000203',
        soldAt: DateTime.utc(2026, 7, 16, 9),
      ),
      sensitiveValuesHidden: true,
      createdAt: DateTime.utc(2026, 7, 16, 9, 30, 0, 123),
    );
    final import = CustomerPriceRuleActivityDto(
      id: '00000000-0000-4000-8000-000000000032',
      activityType: CustomerPriceRuleActivityType.importCreated,
      actor: const CustomerPriceRuleActivityActorDto(
        actorId: '00000000-0000-4000-8000-000000000098',
        displayName: 'aaaaaaaa',
        isSystemActor: false,
      ),
      sourceType: CustomerPriceRuleSourceType.excelImport,
      oldValue: null,
      newValue: Map.unmodifiable(const {
        'version': 1,
        'rule_price_minor': 110000,
      }),
      reason: null,
      sourceTrace: const CustomerPriceRuleActivitySourceTraceDto(
        importId: '00000000-0000-4000-8000-000000000301',
        importRowId: '00000000-0000-4000-8000-000000000302',
      ),
      sensitiveValuesHidden: false,
      createdAt: DateTime.utc(2026, 7, 16, 9, 20),
    );
    final manual = CustomerPriceRuleActivityDto(
      id: '00000000-0000-4000-8000-000000000031',
      activityType: CustomerPriceRuleActivityType.created,
      actor: const CustomerPriceRuleActivityActorDto(
        actorId: '00000000-0000-4000-8000-000000000097',
        displayName: 'bbbbbbbb',
        isSystemActor: false,
      ),
      sourceType: CustomerPriceRuleSourceType.manual,
      oldValue: null,
      newValue: Map.unmodifiable(const {
        'version': 1,
        'rule_price_minor': 100000,
      }),
      reason: null,
      sourceTrace: const CustomerPriceRuleActivitySourceTraceDto(),
      sensitiveValuesHidden: false,
      createdAt: DateTime.utc(2026, 7, 16, 9, 10),
    );
    return [memory, import, manual];
  }

  CustomerPriceRuleActivityDto _historyOlderItem() =>
      CustomerPriceRuleActivityDto(
        id: '00000000-0000-4000-8000-000000000021',
        activityType: CustomerPriceRuleActivityType.updated,
        actor: const CustomerPriceRuleActivityActorDto(
          actorId: '00000000-0000-4000-8000-000000000096',
          displayName: 'cccccccc',
          isSystemActor: false,
        ),
        sourceType: CustomerPriceRuleSourceType.manual,
        oldValue: Map.unmodifiable(const {'version': 1}),
        newValue: Map.unmodifiable(const {'version': 2}),
        reason: null,
        sourceTrace: const CustomerPriceRuleActivitySourceTraceDto(),
        sensitiveValuesHidden: false,
        createdAt: DateTime.utc(2026, 7, 15, 8),
      );

  CustomerPriceRuleActivityDto _historySystemActorItem() =>
      CustomerPriceRuleActivityDto(
        id: '00000000-0000-4000-8000-000000000022',
        activityType: CustomerPriceRuleActivityType.created,
        actor: const CustomerPriceRuleActivityActorDto(
          displayName: 'System/Migration',
          isSystemActor: true,
        ),
        sourceType: CustomerPriceRuleSourceType.migration,
        oldValue: null,
        newValue: Map.unmodifiable(const {
          'version': 1,
          'rule_price_minor': 80000,
        }),
        reason: null,
        sourceTrace: const CustomerPriceRuleActivitySourceTraceDto(),
        sensitiveValuesHidden: false,
        createdAt: DateTime.utc(2026, 1, 1),
      );

  CustomerPriceRuleReenablePrecheckDto _reenablePrecheck({
    required int expectedVersion,
    required DateTime businessDate,
    required String outcome,
    List<String> warningCodes = const [],
    List<String> blockingCodes = const [],
  }) {
    return CustomerPriceRuleReenablePrecheckDto(
      validationOutcome: RuleValidationOutcomeDto(
        outcome: outcome,
        warningCodes: warningCodes,
        blockingCodes: blockingCodes,
        floorPriceHidden: outcome != 'warning',
      ),
      precheckToken: _reenableToken,
      ruleVersion: expectedVersion,
      businessDate: businessDate,
    );
  }

  CustomerPriceRuleDetailDto _reenableDetail({
    required String ruleId,
    required int expectedVersion,
    bool warning = false,
  }) {
    final at = DateTime.utc(2026, 7, 16);
    return CustomerPriceRuleDetailDto(
      id: ruleId,
      customer: const CustomerRefDto(
        customerId: '00000000-0000-4000-8000-000000000002',
        displayName: 'Phòng khám A',
        status: 'active',
      ),
      productUnit: const ProductUnitRefDto(
        productId: '00000000-0000-4000-8000-000000000003',
        productName: 'Vaccine A',
        productUnitId: '00000000-0000-4000-8000-000000000004',
        unitName: 'Lọ',
        sellableStatus: 'active',
      ),
      price: const MoneyDto(amountMinor: 90000, currencyCode: 'VND'),
      effectivePeriod: EffectivePeriodDto(
        effectiveFrom: DateTime.utc(2026, 7, 1),
      ),
      ruleType: CustomerPriceRuleType.specialPrice,
      sourceType: CustomerPriceRuleSourceType.manual,
      persistedStatus: CustomerPriceRuleStatus.active,
      derivedStatus: CustomerPriceRuleDerivedStatus.applying,
      validationOutcome: RuleValidationOutcomeDto(
        outcome: warning ? 'warning' : 'valid',
        warningCodes: warning ? const ['below_floor_price'] : const [],
        blockingCodes: const [],
        floorPriceHidden: !warning,
      ),
      referenceHealth: const CustomerPriceRuleReferenceHealthDto(
        customerState: CustomerPriceRuleReferenceState.valid,
        productUnitState: CustomerPriceRuleReferenceState.valid,
        priceBandState: CustomerPriceRulePriceBandState.current,
        issueCodes: [],
        usedStoredPriceBandSnapshot: false,
      ),
      sourceTrace: const CustomerPriceRuleSourceTraceDto(hidden: false),
      createdBy: 'fake-user-1',
      createdAt: at,
      updatedBy: 'fake-user-1',
      updatedAt: at,
      version: expectedVersion + 1,
      availableActions: const [
        CustomerPriceRuleAvailableActions.edit,
        CustomerPriceRuleAvailableActions.disable,
        CustomerPriceRuleAvailableActions.history,
      ],
      disabledAt: null,
      disabledBy: null,
      disabledReason: null,
    );
  }

  CustomerPriceRuleDetailDto _disableDetail({
    required String ruleId,
    required int expectedVersion,
    required String? reason,
  }) {
    final at = DateTime.utc(2026, 7, 16);
    return CustomerPriceRuleDetailDto(
      id: ruleId,
      customer: const CustomerRefDto(
        customerId: '00000000-0000-4000-8000-000000000002',
        displayName: 'Phòng khám A',
        status: 'active',
      ),
      productUnit: const ProductUnitRefDto(
        productId: '00000000-0000-4000-8000-000000000003',
        productName: 'Vaccine A',
        productUnitId: '00000000-0000-4000-8000-000000000004',
        unitName: 'Lọ',
        sellableStatus: 'active',
      ),
      price: const MoneyDto(amountMinor: 90000, currencyCode: 'VND'),
      effectivePeriod: EffectivePeriodDto(
        effectiveFrom: DateTime.utc(2026, 7, 1),
      ),
      ruleType: CustomerPriceRuleType.specialPrice,
      sourceType: CustomerPriceRuleSourceType.manual,
      persistedStatus: CustomerPriceRuleStatus.disabled,
      derivedStatus: CustomerPriceRuleDerivedStatus.disabled,
      validationOutcome: const RuleValidationOutcomeDto(
        outcome: 'notChecked',
        warningCodes: [],
        blockingCodes: [],
        floorPriceHidden: true,
      ),
      referenceHealth: const CustomerPriceRuleReferenceHealthDto(
        customerState: CustomerPriceRuleReferenceState.valid,
        productUnitState: CustomerPriceRuleReferenceState.valid,
        priceBandState: CustomerPriceRulePriceBandState.current,
        issueCodes: [],
        usedStoredPriceBandSnapshot: false,
      ),
      sourceTrace: const CustomerPriceRuleSourceTraceDto(hidden: false),
      createdBy: 'fake-user-1',
      createdAt: at,
      updatedBy: 'fake-user-1',
      updatedAt: at,
      version: expectedVersion + 1,
      availableActions: const [
        CustomerPriceRuleAvailableActions.edit,
        CustomerPriceRuleAvailableActions.reenable,
        CustomerPriceRuleAvailableActions.history,
      ],
      disabledAt: at,
      disabledBy: 'fake-user-1',
      disabledReason: reason,
    );
  }

  CustomerPriceRuleDetailDto _updateDetail({
    required String ruleId,
    required int expectedVersion,
    required int rulePriceMinor,
    required DateTime effectiveFrom,
    DateTime? effectiveTo,
    String? note,
    int? version,
    bool warning = false,
    bool disabled = false,
  }) {
    final at = DateTime.utc(2026, 7, 16);
    return CustomerPriceRuleDetailDto(
      id: ruleId,
      customer: const CustomerRefDto(
        customerId: '00000000-0000-4000-8000-000000000002',
        displayName: 'Phòng khám A',
        status: 'active',
      ),
      productUnit: const ProductUnitRefDto(
        productId: '00000000-0000-4000-8000-000000000003',
        productName: 'Vaccine A',
        productUnitId: '00000000-0000-4000-8000-000000000004',
        unitName: 'Lọ',
        sellableStatus: 'active',
      ),
      price: MoneyDto(amountMinor: rulePriceMinor, currencyCode: 'VND'),
      effectivePeriod: EffectivePeriodDto(
        effectiveFrom: _calendarDate(effectiveFrom),
        effectiveTo: effectiveTo == null ? null : _calendarDate(effectiveTo),
      ),
      ruleType: CustomerPriceRuleType.specialPrice,
      sourceType: CustomerPriceRuleSourceType.manual,
      persistedStatus: disabled
          ? CustomerPriceRuleStatus.disabled
          : CustomerPriceRuleStatus.active,
      derivedStatus: disabled
          ? CustomerPriceRuleDerivedStatus.disabled
          : CustomerPriceRuleDerivedStatus.applying,
      note: note?.trim(),
      validationOutcome: RuleValidationOutcomeDto(
        outcome: warning ? 'warning' : 'valid',
        warningCodes: warning ? const ['below_floor_price'] : const [],
        blockingCodes: const [],
        floorPriceHidden: !warning,
      ),
      referenceHealth: const CustomerPriceRuleReferenceHealthDto(
        customerState: CustomerPriceRuleReferenceState.valid,
        productUnitState: CustomerPriceRuleReferenceState.valid,
        priceBandState: CustomerPriceRulePriceBandState.current,
        issueCodes: [],
        usedStoredPriceBandSnapshot: false,
      ),
      sourceTrace: const CustomerPriceRuleSourceTraceDto(hidden: false),
      createdBy: 'fake-user-1',
      createdAt: at,
      updatedBy: 'fake-user-1',
      updatedAt: at,
      version: version ?? expectedVersion + 1,
      availableActions: const [],
    );
  }

  CustomerPriceRuleDetailDto _detail({
    required String ruleId,
    required DateTime businessDate,
    required CustomerPriceRuleStatus persistedStatus,
    required CustomerPriceRuleDerivedStatus derivedStatus,
    required List<String> availableActions,
    String customerDisplayName = 'Phòng khám A',
    String productName = 'Vaccine A',
    String unitName = 'Lọ',
    CustomerPriceRuleReferenceHealthDto referenceHealth =
        const CustomerPriceRuleReferenceHealthDto(
          customerState: CustomerPriceRuleReferenceState.valid,
          productUnitState: CustomerPriceRuleReferenceState.valid,
          priceBandState: CustomerPriceRulePriceBandState.current,
          issueCodes: [],
          usedStoredPriceBandSnapshot: false,
        ),
    RuleValidationOutcomeDto validationOutcome = const RuleValidationOutcomeDto(
      outcome: 'notChecked',
      warningCodes: [],
      blockingCodes: [],
      floorPriceHidden: true,
    ),
    DateTime? disabledAt,
    String? disabledBy,
    String? disabledReason,
  }) {
    final at = DateTime.utc(2026, 7, 16);
    return CustomerPriceRuleDetailDto(
      id: ruleId,
      customer: CustomerRefDto(
        customerId: '00000000-0000-4000-8000-000000000002',
        displayName: customerDisplayName,
        status: 'active',
      ),
      productUnit: ProductUnitRefDto(
        productId: '00000000-0000-4000-8000-000000000003',
        productName: productName,
        productUnitId: '00000000-0000-4000-8000-000000000004',
        unitName: unitName,
        sellableStatus: 'active',
      ),
      price: const MoneyDto(amountMinor: 90000, currencyCode: 'VND'),
      effectivePeriod: EffectivePeriodDto(effectiveFrom: businessDate),
      ruleType: CustomerPriceRuleType.specialPrice,
      sourceType: CustomerPriceRuleSourceType.manual,
      persistedStatus: persistedStatus,
      derivedStatus: derivedStatus,
      validationOutcome: validationOutcome,
      referenceHealth: referenceHealth,
      sourceTrace: const CustomerPriceRuleSourceTraceDto(hidden: false),
      createdBy: '00000000-0000-4000-8000-000000000005',
      createdAt: at,
      updatedBy: '00000000-0000-4000-8000-000000000005',
      updatedAt: at,
      version: 1,
      availableActions: availableActions,
      disabledAt: disabledAt,
      disabledBy: disabledBy,
      disabledReason: disabledReason,
    );
  }

  CustomerPriceRuleSearchResultDto _searchResult(DateTime rawBusinessDate) {
    final businessDate = _calendarDate(rawBusinessDate);
    return CustomerPriceRuleSearchResultDto(
      page: CursorPageDto(
        items: [
          CustomerPriceRuleListItemDto(
            id: 'fake-rule-1',
            customer: const CustomerRefDto(
              customerId: 'customer-1',
              displayName: 'Khách hàng mẫu',
              status: 'active',
            ),
            productUnit: const ProductUnitRefDto(
              productId: 'product-1',
              productName: 'Vaccine mẫu',
              productUnitId: 'unit-1',
              unitName: 'Lọ',
              sellableStatus: 'active',
              productReferenceId: 'VAC-001',
              sku: 'SKU-VAC-001',
            ),
            price: const MoneyDto(amountMinor: 90000, currencyCode: 'VND'),
            effectivePeriod: EffectivePeriodDto(effectiveFrom: businessDate),
            ruleType: CustomerPriceRuleType.specialPrice,
            sourceType: CustomerPriceRuleSourceType.manual,
            persistedStatus: CustomerPriceRuleStatus.active,
            derivedStatus: CustomerPriceRuleDerivedStatus.applying,
            validationOutcome: const RuleValidationOutcomeDto(
              outcome: 'warning',
              warningCodes: ['below_floor_price'],
              blockingCodes: [],
              listPrice: MoneyDto(amountMinor: 150000, currencyCode: 'VND'),
              floorPriceHidden: true,
            ),
            updatedAt: DateTime.utc(2026, 7, 20, 8),
          ),
          CustomerPriceRuleListItemDto(
            id: 'fake-rule-2',
            customer: const CustomerRefDto(
              customerId: 'customer-2',
              displayName: 'Khách hàng tương lai',
              status: 'active',
            ),
            productUnit: const ProductUnitRefDto(
              productId: 'product-2',
              productName: 'Thức ăn mẫu',
              productUnitId: 'unit-2',
              unitName: 'Bao',
              sellableStatus: 'active',
              productReferenceId: 'FOOD-002',
              sku: 'SKU-FOOD-002',
            ),
            price: const MoneyDto(amountMinor: 250000, currencyCode: 'VND'),
            effectivePeriod: EffectivePeriodDto(
              effectiveFrom: businessDate.add(const Duration(days: 1)),
            ),
            ruleType: CustomerPriceRuleType.specialPrice,
            sourceType: CustomerPriceRuleSourceType.excelImport,
            persistedStatus: CustomerPriceRuleStatus.active,
            derivedStatus: CustomerPriceRuleDerivedStatus.notYetEffective,
            validationOutcome: const RuleValidationOutcomeDto(
              outcome: 'notChecked',
              warningCodes: [],
              blockingCodes: [],
              listPrice: MoneyDto(amountMinor: 260000, currencyCode: 'VND'),
              floorPriceHidden: true,
            ),
            updatedAt: DateTime.utc(2026, 7, 19, 8),
          ),
        ],
        hasMore: false,
      ),
      availableActions: const [
        PricingAvailableActions.createManual,
        PricingAvailableActions.import,
      ],
      totalCount: 2,
    );
  }

  CreateCustomerPriceRuleResult _result({
    required String customerId,
    required String productId,
    required String productUnitId,
    required int rulePriceMinor,
    required String currencyCode,
    required DateTime effectiveFrom,
    DateTime? effectiveTo,
    String? note,
    bool warning = false,
  }) {
    final warningCodes = warning
        ? const ['below_floor_price']
        : const <String>[];
    final warnings = warning
        ? const [RuleIssueDto(code: 'below_floor_price')]
        : const <RuleIssueDto>[];
    final at = DateTime.utc(2026, 7, 16);
    return CreateCustomerPriceRuleResult(
      rule: CustomerPriceRuleDetailDto(
        id: 'fake-rule-1',
        customer: CustomerRefDto(
          customerId: customerId,
          displayName: 'Khách hàng mẫu',
          status: 'active',
        ),
        productUnit: ProductUnitRefDto(
          productId: productId,
          productName: 'Sản phẩm mẫu',
          productUnitId: productUnitId,
          unitName: 'Đơn vị mẫu',
          sellableStatus: 'active',
        ),
        price: MoneyDto(
          amountMinor: rulePriceMinor,
          currencyCode: currencyCode,
        ),
        effectivePeriod: EffectivePeriodDto(
          effectiveFrom: _calendarDate(effectiveFrom),
          effectiveTo: effectiveTo == null ? null : _calendarDate(effectiveTo),
        ),
        ruleType: CustomerPriceRuleType.specialPrice,
        sourceType: CustomerPriceRuleSourceType.manual,
        persistedStatus: CustomerPriceRuleStatus.active,
        derivedStatus: CustomerPriceRuleDerivedStatus.applying,
        note: note,
        validationOutcome: RuleValidationOutcomeDto(
          outcome: warning ? 'warning' : 'notChecked',
          warningCodes: warningCodes,
          blockingCodes: const [],
          floorPriceHidden: false,
        ),
        referenceHealth: const CustomerPriceRuleReferenceHealthDto(
          customerState: CustomerPriceRuleReferenceState.valid,
          productUnitState: CustomerPriceRuleReferenceState.valid,
          priceBandState: CustomerPriceRulePriceBandState.current,
          issueCodes: [],
          usedStoredPriceBandSnapshot: false,
        ),
        sourceTrace: const CustomerPriceRuleSourceTraceDto(hidden: false),
        createdBy: 'fake-user-1',
        createdAt: at,
        updatedBy: 'fake-user-1',
        updatedAt: at,
        version: 1,
        availableActions: const [],
      ),
      warnings: warnings,
    );
  }

  static DateTime _calendarDate(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);

  static String? _normalizeOptional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}

