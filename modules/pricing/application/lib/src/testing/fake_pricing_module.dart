import 'dart:typed_data';

import 'package:vet45_pricing_domain/domain.dart'
    hide
        CustomerPriceRuleImportMode,
        CustomerPriceRuleImportStatus,
        CustomerPriceRuleImportRowStatus;
import 'package:vet45_shared_application/application.dart';

import '../contracts/i_pricing_module.dart';
import '../customer_price_rule/commands/create_customer_price_rule/create_customer_price_rule_command.dart';
import '../customer_price_rule/commands/create_customer_price_rule/create_customer_price_rule_result.dart';
import '../customer_price_rule/commands/disable_customer_price_rule/disable_customer_price_rule_command.dart';
import '../customer_price_rule/commands/delete_customer_price_rule/delete_customer_price_rule_command.dart';
import '../customer_price_rule/import/commands/cancel_customer_price_rule_import/cancel_customer_price_rule_import_command.dart';
import '../customer_price_rule/import/commands/confirm_customer_price_rule_import/confirm_customer_price_rule_import_command.dart';
import '../customer_price_rule/import/commands/start_customer_price_rule_import/start_customer_price_rule_import_command.dart';
import '../customer_price_rule/import/queries/get_customer_price_rule_import/get_customer_price_rule_import_query.dart';
import '../customer_price_rule/import/queries/get_customer_price_rule_import_template/get_customer_price_rule_import_template_query.dart';
import '../customer_price_rule/import/shared/customer_price_rule_import_detail_dto.dart';
import '../customer_price_rule/import/shared/customer_price_rule_import_dto.dart';
import '../customer_price_rule/queries/resolve_applicable_customer_price_rule/resolve_applicable_customer_price_rule_query.dart';
import '../customer_price_rule/queries/resolve_applicable_customer_price_rule/resolve_applicable_customer_price_rule_result_dto.dart';
import '../customer_price_rule/import/shared/customer_price_rule_import_result_dto.dart';
import '../customer_price_rule/import/shared/customer_price_rule_import_row_preview_dto.dart';
import '../customer_price_rule/import/shared/customer_price_rule_import_template_dto.dart';
import '../customer_price_rule/import/shared/customer_price_rule_import_enums.dart';
import '../customer_price_rule/commands/reenable_customer_price_rule/reenable_customer_price_rule_command.dart';
import '../customer_price_rule/commands/save_remembered_price_from_order/remembered_price_outcome_dto.dart';
import '../customer_price_rule/commands/save_remembered_price_from_order/save_remembered_price_from_order_command.dart';
import '../customer_price_rule/commands/update_customer_price_rule/update_customer_price_rule_command.dart';
import '../customer_price_rule/queries/get_customer_price_rule_detail/get_customer_price_rule_detail_query.dart';
import '../customer_price_rule/queries/get_customer_price_rule_history/customer_price_rule_activity_actor_dto.dart';
import '../customer_price_rule/queries/get_customer_price_rule_history/customer_price_rule_activity_dto.dart';
import '../customer_price_rule/queries/get_customer_price_rule_history/customer_price_rule_activity_source_trace_dto.dart';
import '../customer_price_rule/queries/get_customer_price_rule_history/customer_price_rule_activity_type.dart';
import '../customer_price_rule/queries/get_customer_price_rule_history/get_customer_price_rule_history_query.dart';
import '../customer_price_rule/queries/precheck_customer_price_rule_reenable/customer_price_rule_reenable_precheck_dto.dart';
import '../customer_price_rule/queries/precheck_customer_price_rule_reenable/precheck_customer_price_rule_reenable_query.dart';
import '../customer_price_rule/queries/search_customer_price_rules/customer_price_rule_list_item_dto.dart';
import '../customer_price_rule/queries/search_customer_price_rules/customer_price_rule_search_enums.dart';
import '../customer_price_rule/queries/search_customer_price_rules/customer_price_rule_search_result_dto.dart';
import '../customer_price_rule/queries/search_customer_price_rules/search_customer_price_rules_query.dart';
import '../customer_price_rule/shared/customer_price_rule_available_actions.dart';
import '../customer_price_rule/shared/customer_price_rule_detail_dto.dart';
import '../customer_price_rule/shared/customer_price_rule_derived_status.dart';
import '../customer_price_rule/shared/customer_price_rule_reference_health_dto.dart';
import '../customer_price_rule/shared/customer_price_rule_source_trace_dto.dart';
import '../customer_price_rule/shared/customer_ref_dto.dart';
import '../customer_price_rule/shared/cursor_page_dto.dart';
import '../customer_price_rule/shared/effective_period_dto.dart';
import '../customer_price_rule/shared/money_dto.dart';
import '../customer_price_rule/shared/product_unit_ref_dto.dart';
import '../customer_price_rule/shared/rule_issue_dto.dart';
import '../customer_price_rule/shared/rule_validation_outcome_dto.dart';
import '../shared/pricing_blocked_codes.dart';
import '../shared/pricing_blocked_exception.dart';

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
  deleteRuleOk,
  deleteRuleAlreadyDeleted,
  deleteRuleStateChanged,
  deleteRuleDenied,
  deleteRuleNotFound,
  deleteRuleInvalidStatus,
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
  importTemplateV1,
  importReadyMixed,
  importFailedBadFile,
  importAmbiguousUnit,
  importModeMismatch,
  importGetNotFound,
  importConfirmNeedsAcknowledgement,
  importConfirmPartial,
  importConfirmRetry,
  importConfirmStateChanged,
  importConfirmDenied,
  importCancelOk,
  importCancelStateChanged,
  importCancelInvalidStatus,
  memoryCreateOk,
  memoryUpdateOk,
  memoryManualConflict,
  memoryRetrySamePayload,
  memoryKeyConflict,
  memoryAnonymousCustomer,
  memoryReferenceInvalid,
  memoryBelowFloorBlocked,
  memoryStaleSaleSkipped,
  memoryDisabledRememberedSkipped,
  memorySystemError,
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

final class FakePricingModule implements IPricingModule {
  FakePricingModule({this.scenario = FakePricingScenario.createRuleOk});

  final FakePricingScenario scenario;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    return switch (command) {
      CreateCustomerPriceRuleCommand value => _handleCreate<TResult>(value),
      UpdateCustomerPriceRuleCommand value => _handleUpdate<TResult>(value),
      DisableCustomerPriceRuleCommand value => _handleDisable<TResult>(value),
      DeleteCustomerPriceRuleCommand value => _handleDelete<TResult>(value),
      ReenableCustomerPriceRuleCommand value => _handleReenable<TResult>(value),
      StartCustomerPriceRuleImportCommand value => _handleImportStart<TResult>(
        value,
      ),
      ConfirmCustomerPriceRuleImportCommand value =>
        _handleImportConfirm<TResult>(value),
      CancelCustomerPriceRuleImportCommand value =>
        _handleImportCancel<TResult>(value),
      SaveRememberedPriceFromOrderCommand value =>
        _handleRememberedPrice<TResult>(value),
      _ => throw UnsupportedError(
        'FakePricingModule: unsupported command ${command.runtimeType}',
      ),
    };
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    return switch (query) {
      SearchCustomerPriceRulesQuery value => _handleSearch<TResult>(value),
      GetCustomerPriceRuleDetailQuery value => _handleDetail<TResult>(value),
      ResolveApplicableCustomerPriceRuleQuery value =>
          _handleResolveApplicable<TResult>(value),
      PrecheckCustomerPriceRuleReenableQuery value =>
        _handleReenablePrecheck<TResult>(value),
      GetCustomerPriceRuleImportTemplateQuery value =>
        _handleImportTemplate<TResult>(value),
      GetCustomerPriceRuleImportQuery value => _handleImportGet<TResult>(value),
      GetCustomerPriceRuleHistoryQuery value => _handleHistory<TResult>(value),
      _ => throw UnsupportedError(
        'FakePricingModule: unsupported query ${query.runtimeType}',
      ),
    };
  }

  Future<TResult> _handleHistory<TResult>(
    GetCustomerPriceRuleHistoryQuery query,
  ) async {
    switch (scenario) {
      case FakePricingScenario.historyNotFound:
        throw const PricingBlockedException(PricingBlockedCodes.notFound);
      case FakePricingScenario.historyMalformedCursor:
        throw const PricingBlockedException(
          PricingBlockedCodes.validationError,
          details: {
            'fieldErrors': {'cursor': 'invalid'},
          },
        );
      case FakePricingScenario.historyDenied:
        throw const PricingBlockedException(PricingBlockedCodes.noPermission);
      case FakePricingScenario.historySystemError:
        throw const PricingBlockedException(PricingBlockedCodes.systemError);
      case FakePricingScenario.historyEmptyLegacy:
        return const CursorPageDto<CustomerPriceRuleActivityDto>(
              items: [],
              hasMore: false,
            )
            as TResult;
      case FakePricingScenario.historySystemActor:
        return CursorPageDto<CustomerPriceRuleActivityDto>(
              items: List.unmodifiable([_historySystemActorItem()]),
              hasMore: false,
            )
            as TResult;
      case FakePricingScenario.historySecondPage:
        return CursorPageDto<CustomerPriceRuleActivityDto>(
              items: List.unmodifiable([_historyOlderItem()]),
              hasMore: false,
            )
            as TResult;
      case FakePricingScenario.historyMixedSources:
        final items = _historyMixedItems();
        return CursorPageDto<CustomerPriceRuleActivityDto>(
              items: List.unmodifiable(items),
              nextCursor: 'page-1-cursor',
              hasMore: true,
            )
            as TResult;
      // FE detail page may prefetch recent history (S3 → S10 preview).
      case FakePricingScenario.ruleDetailActive:
      case FakePricingScenario.ruleDetailDisabled:
      case FakePricingScenario.ruleDetailReferenceStale:
      case FakePricingScenario.updateRuleOk:
      case FakePricingScenario.disableRuleOk:
      case FakePricingScenario.reenableOk:
        return const CursorPageDto<CustomerPriceRuleActivityDto>(
              items: [],
              hasMore: false,
            )
            as TResult;
      default:
        throw UnsupportedError(
          'FakePricingModule: ${scenario.name} does not support history.',
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

  Future<TResult> _handleCreate<TResult>(
    CreateCustomerPriceRuleCommand command,
  ) async {
    switch (scenario) {
      case FakePricingScenario.createRuleDuplicate:
        return _result(command) as TResult;
      case FakePricingScenario.createRuleFloorBlocked:
        throw const PricingBlockedException(
          PricingBlockedCodes.belowFloorBlocked,
          details: {'reason': 'override_permission_required'},
        );
      case FakePricingScenario.createRuleReferenceInvalid:
        throw const PricingBlockedException(
          PricingBlockedCodes.referenceInvalid,
        );
      case FakePricingScenario.createRuleIdempotencyConflict:
        throw const PricingBlockedException(
          PricingBlockedCodes.idempotencyConflict,
        );
      case FakePricingScenario.createRuleFloorWarning:
        return _result(command, warning: true) as TResult;
      case FakePricingScenario.createRuleOk:
      case FakePricingScenario.createRuleIdempotentRetry:
        return _result(command) as TResult;
      default:
        throw UnsupportedError(
          'FakePricingModule: ${scenario.name} does not support create.',
        );
    }
  }

  Future<TResult> _handleSearch<TResult>(
    SearchCustomerPriceRulesQuery query,
  ) async {
    switch (scenario) {
      case FakePricingScenario.searchRulesError:
        throw const PricingBlockedException(PricingBlockedCodes.systemError);
      case FakePricingScenario.searchRulesEmpty:
      case FakePricingScenario.searchRulesNoResult:
        return const CustomerPriceRuleSearchResultDto(
              page: CursorPageDto(items: [], hasMore: false),
              availableActions: [
                PricingAvailableActions.createManual,
                PricingAvailableActions.import,
              ],
            )
            as TResult;
      case FakePricingScenario.searchRulesDefault:
        return _searchResult(query) as TResult;
      default:
        throw UnsupportedError(
          'FakePricingModule: ${scenario.name} does not support search.',
        );
    }
  }

  Future<TResult> _handleDetail<TResult>(
    GetCustomerPriceRuleDetailQuery query,
  ) async {
    switch (scenario) {
      case FakePricingScenario.ruleDetailNotFound:
        throw const PricingBlockedException(PricingBlockedCodes.notFound);
      case FakePricingScenario.ruleDetailActive:
        return _detail(
              query,
              persistedStatus: CustomerPriceRuleStatus.active,
              derivedStatus: CustomerPriceRuleDerivedStatus.applying,
              availableActions: const [
                CustomerPriceRuleAvailableActions.edit,
                CustomerPriceRuleAvailableActions.disable,
                CustomerPriceRuleAvailableActions.history,
              ],
            )
            as TResult;
      case FakePricingScenario.ruleDetailDisabled:
        return _detail(
              query,
              persistedStatus: CustomerPriceRuleStatus.disabled,
              derivedStatus: CustomerPriceRuleDerivedStatus.disabled,
              availableActions: const [
                CustomerPriceRuleAvailableActions.edit,
                CustomerPriceRuleAvailableActions.reenable,
                CustomerPriceRuleAvailableActions.history,
              ],
              disabledAt: DateTime.utc(2026, 7, 16),
              disabledBy: 'fake-user-1',
            )
            as TResult;
      case FakePricingScenario.ruleDetailReferenceStale:
        return _detail(
              query,
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
            )
            as TResult;
      // FE history page loads detail context before timeline (S10).
      case FakePricingScenario.historyMixedSources:
      case FakePricingScenario.historySecondPage:
      case FakePricingScenario.historyEmptyLegacy:
      case FakePricingScenario.historySystemActor:
      case FakePricingScenario.historyDenied:
      case FakePricingScenario.historySystemError:
      case FakePricingScenario.historyMalformedCursor:
        return _detail(
              query,
              persistedStatus: CustomerPriceRuleStatus.active,
              derivedStatus: CustomerPriceRuleDerivedStatus.applying,
              availableActions: const [
                CustomerPriceRuleAvailableActions.history,
              ],
            )
            as TResult;
      case FakePricingScenario.historyNotFound:
        throw const PricingBlockedException(PricingBlockedCodes.notFound);
      default:
        throw UnsupportedError(
          'FakePricingModule: ${scenario.name} does not support detail.',
        );
    }
  }

  Future<TResult> _handleUpdate<TResult>(
    UpdateCustomerPriceRuleCommand command,
  ) async {
    switch (scenario) {
      case FakePricingScenario.updateRuleStateChanged:
        throw const PricingBlockedException(PricingBlockedCodes.stateChanged);
      case FakePricingScenario.updateRuleDuplicate:
        return _updateDetail(command) as TResult;
      case FakePricingScenario.updateRuleFloorBlocked:
        throw const PricingBlockedException(
          PricingBlockedCodes.belowFloorBlocked,
          details: {'reason': 'overridePermissionRequired'},
        );
      case FakePricingScenario.updateRuleReferenceInvalid:
        throw const PricingBlockedException(
          PricingBlockedCodes.referenceInvalid,
        );
      case FakePricingScenario.updateRuleNoop:
        return _updateDetail(command, version: command.expectedVersion)
            as TResult;
      case FakePricingScenario.updateRuleFloorWarning:
        return _updateDetail(command, warning: true) as TResult;
      case FakePricingScenario.updateRuleDisabled:
        return _updateDetail(command, disabled: true) as TResult;
      case FakePricingScenario.updateRuleOk:
        return _updateDetail(command) as TResult;
      default:
        throw UnsupportedError(
          'FakePricingModule: ${scenario.name} does not support update.',
        );
    }
  }

  Future<TResult> _handleDisable<TResult>(
    DisableCustomerPriceRuleCommand command,
  ) async {
    switch (scenario) {
      case FakePricingScenario.disableRuleStateChanged:
        throw const PricingBlockedException(PricingBlockedCodes.stateChanged);
      case FakePricingScenario.disableRuleDenied:
        throw const PricingBlockedException(PricingBlockedCodes.noPermission);
      case FakePricingScenario.disableRuleNotFound:
        throw const PricingBlockedException(PricingBlockedCodes.notFound);
      case FakePricingScenario.disableRuleInvalidStatus:
        throw const PricingBlockedException(PricingBlockedCodes.invalidStatus);
      case FakePricingScenario.disableRuleAlreadyDisabled:
        return _disableDetail(command, reason: 'Lý do ban đầu') as TResult;
      case FakePricingScenario.disableRuleOk:
        return _disableDetail(
              command,
              reason: _normalizeOptional(command.reason),
            )
            as TResult;
      default:
        throw UnsupportedError(
          'FakePricingModule: ${scenario.name} does not support disable.',
        );
    }
  }

  Future<TResult> _handleDelete<TResult>(
    DeleteCustomerPriceRuleCommand command,
  ) async {
    switch (scenario) {
      case FakePricingScenario.deleteRuleStateChanged:
        throw const PricingBlockedException(PricingBlockedCodes.stateChanged);
      case FakePricingScenario.deleteRuleDenied:
        throw const PricingBlockedException(PricingBlockedCodes.noPermission);
      case FakePricingScenario.deleteRuleNotFound:
        throw const PricingBlockedException(PricingBlockedCodes.notFound);
      case FakePricingScenario.deleteRuleInvalidStatus:
        throw const PricingBlockedException(PricingBlockedCodes.invalidStatus);
      case FakePricingScenario.deleteRuleAlreadyDeleted:
        return _deleteDetail(command, version: 4) as TResult;
      case FakePricingScenario.deleteRuleOk:
        return _deleteDetail(command, version: command.expectedVersion + 1)
            as TResult;
      default:
        throw UnsupportedError(
          'FakePricingModule: ${scenario.name} does not support delete.',
        );
    }
  }

  Future<TResult> _handleResolveApplicable<TResult>(
    ResolveApplicableCustomerPriceRuleQuery query,
  ) async {
    switch (scenario) {
      case FakePricingScenario.resolveApplicableDenied:
        throw const PricingBlockedException(PricingBlockedCodes.noPermission);
      case FakePricingScenario.resolveApplicableNone:
        return const ResolveApplicableCustomerPriceRuleResultDto() as TResult;
      case FakePricingScenario.resolveApplicableOk:
        return ResolveApplicableCustomerPriceRuleResultDto(
              rule: ApplicableCustomerPriceRuleDto(
                ruleId: '11111111-1111-4111-8111-111111111111',
                price: const MoneyDto(amountMinor: 125000, currencyCode: 'VND'),
                effectivePeriod: EffectivePeriodDto(
                  effectiveFrom: query.businessDate,
                ),
                sourceType: CustomerPriceRuleSourceType.manual,
                version: 2,
              ),
            )
            as TResult;
      default:
        throw UnsupportedError(
          'FakePricingModule: ${scenario.name} does not support resolve.',
        );
    }
  }

  Future<TResult> _handleReenablePrecheck<TResult>(
    PrecheckCustomerPriceRuleReenableQuery query,
  ) async {
    switch (scenario) {
      case FakePricingScenario.reenablePrecheckValid:
        return _reenablePrecheck(query, outcome: 'valid') as TResult;
      case FakePricingScenario.reenablePrecheckWarning:
        return _reenablePrecheck(
              query,
              outcome: 'warning',
              warningCodes: const ['below_floor_price'],
            )
            as TResult;
      case FakePricingScenario.reenablePrecheckBlockedDuplicate:
        return _reenablePrecheck(
              query,
              outcome: 'valid',
            )
            as TResult;
      case FakePricingScenario.reenablePrecheckBlockedExpired:
        return _reenablePrecheck(
              query,
              outcome: 'blocked',
              blockingCodes: const ['effective_period_expired'],
            )
            as TResult;
      case FakePricingScenario.reenablePrecheckBlockedReference:
        return _reenablePrecheck(
              query,
              outcome: 'blocked',
              blockingCodes: const ['customer_reference_invalid'],
            )
            as TResult;
      case FakePricingScenario.reenablePrecheckDenied:
        throw const PricingBlockedException(PricingBlockedCodes.noPermission);
      case FakePricingScenario.reenablePrecheckNotFound:
        throw const PricingBlockedException(PricingBlockedCodes.notFound);
      case FakePricingScenario.reenablePrecheckInvalidStatus:
        throw const PricingBlockedException(PricingBlockedCodes.invalidStatus);
      case FakePricingScenario.reenableOk:
      case FakePricingScenario.reenableFloorOverrideOk:
      case FakePricingScenario.ruleDetailDisabled:
        return _reenablePrecheck(query, outcome: 'valid') as TResult;
      default:
        throw UnsupportedError(
          'FakePricingModule: ${scenario.name} does not support reenable precheck.',
        );
    }
  }

  Future<TResult> _handleReenable<TResult>(
    ReenableCustomerPriceRuleCommand command,
  ) async {
    switch (scenario) {
      case FakePricingScenario.reenableStateChanged:
        throw const PricingBlockedException(PricingBlockedCodes.stateChanged);
      case FakePricingScenario.reenableDuplicate:
        return _reenableDetail(command) as TResult;
      case FakePricingScenario.reenableFloorBlocked:
        throw const PricingBlockedException(
          PricingBlockedCodes.belowFloorBlocked,
          details: {'reason': 'override_permission_required'},
        );
      case FakePricingScenario.reenableReferenceInvalid:
        throw const PricingBlockedException(
          PricingBlockedCodes.referenceInvalid,
        );
      case FakePricingScenario.reenableExpired:
        throw const PricingBlockedException(
          PricingBlockedCodes.invalidStatus,
          details: {'reason': 'effectivePeriodExpired'},
        );
      case FakePricingScenario.reenableInvalidStatus:
        throw const PricingBlockedException(PricingBlockedCodes.invalidStatus);
      case FakePricingScenario.reenableOk:
        return _reenableDetail(command) as TResult;
      case FakePricingScenario.reenableFloorOverrideOk:
        return _reenableDetail(command, warning: true) as TResult;
      default:
        throw UnsupportedError(
          'FakePricingModule: ${scenario.name} does not support reenable.',
        );
    }
  }

  Future<TResult> _handleImportTemplate<TResult>(
    GetCustomerPriceRuleImportTemplateQuery query,
  ) async {
    switch (scenario) {
      case FakePricingScenario.importTemplateV1:
        return CustomerPriceRuleImportTemplateDto(
              templateVersion: CustomerPriceRuleImportTemplateDto.versionV1,
              fileName: CustomerPriceRuleImportTemplateDto.fileNameV1,
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
              bytes: Uint8List.fromList(const [0x50, 0x4B, 0x03, 0x04]),
            )
            as TResult;
      default:
        throw UnsupportedError(
          'FakePricingModule: ${scenario.name} does not support import template.',
        );
    }
  }

  Future<TResult> _handleImportGet<TResult>(
    GetCustomerPriceRuleImportQuery query,
  ) async {
    switch (scenario) {
      case FakePricingScenario.importGetNotFound:
        throw const PricingBlockedException(PricingBlockedCodes.notFound);
      case FakePricingScenario.importReadyMixed:
      case FakePricingScenario.importFailedBadFile:
      case FakePricingScenario.importAmbiguousUnit:
      case FakePricingScenario.importModeMismatch:
      case FakePricingScenario.importConfirmPartial:
      case FakePricingScenario.importConfirmRetry:
      case FakePricingScenario.importCancelOk:
        return _importDetail(query) as TResult;
      default:
        throw UnsupportedError(
          'FakePricingModule: ${scenario.name} does not support import get.',
        );
    }
  }

  Future<TResult> _handleImportStart<TResult>(
    StartCustomerPriceRuleImportCommand command,
  ) async {
    switch (scenario) {
      case FakePricingScenario.importFailedBadFile:
        return _importDetail(
              null,
              status: CustomerPriceRuleImportStatus.failed,
              fileErrorCodes: const ['TEMPLATE_HEADER_INVALID'],
            )
            as TResult;
      case FakePricingScenario.importAmbiguousUnit:
        return _importDetail(
              null,
              rowErrorCodes: const ['AMBIGUOUS_PRODUCT_UNIT'],
            )
            as TResult;
      case FakePricingScenario.importModeMismatch:
        return _importDetail(
              null,
              rowErrorCodes: const ['IMPORT_MODE_MISMATCH'],
            )
            as TResult;
      case FakePricingScenario.importReadyMixed:
        return _importDetail(null) as TResult;
      default:
        throw UnsupportedError(
          'FakePricingModule: ${scenario.name} does not support import start.',
        );
    }
  }

  Future<TResult> _handleImportConfirm<TResult>(
    ConfirmCustomerPriceRuleImportCommand command,
  ) async {
    switch (scenario) {
      case FakePricingScenario.importConfirmNeedsAcknowledgement:
        throw const PricingBlockedException(
          PricingBlockedCodes.validationError,
          details: {'reason': 'acknowledgementRequired'},
        );
      case FakePricingScenario.importConfirmStateChanged:
        throw const PricingBlockedException(PricingBlockedCodes.stateChanged);
      case FakePricingScenario.importConfirmDenied:
        throw const PricingBlockedException(PricingBlockedCodes.noPermission);
      case FakePricingScenario.importConfirmRetry:
        return _importResult(isReplay: true) as TResult;
      case FakePricingScenario.importConfirmPartial:
        return _importResult(
              status: CustomerPriceRuleImportStatus.completedWithErrors,
            )
            as TResult;
      default:
        throw UnsupportedError(
          'FakePricingModule: ${scenario.name} does not support import confirm.',
        );
    }
  }

  Future<TResult> _handleImportCancel<TResult>(
    CancelCustomerPriceRuleImportCommand command,
  ) async {
    switch (scenario) {
      case FakePricingScenario.importCancelStateChanged:
        throw const PricingBlockedException(PricingBlockedCodes.stateChanged);
      case FakePricingScenario.importCancelInvalidStatus:
        throw const PricingBlockedException(PricingBlockedCodes.invalidStatus);
      case FakePricingScenario.importCancelOk:
        return _importBatch(status: CustomerPriceRuleImportStatus.canceled)
            as TResult;
      default:
        throw UnsupportedError(
          'FakePricingModule: ${scenario.name} does not support import cancel.',
        );
    }
  }

  CustomerPriceRuleImportResultDto _importResult({
    bool isReplay = false,
    CustomerPriceRuleImportStatus status =
        CustomerPriceRuleImportStatus.completed,
  }) => CustomerPriceRuleImportResultDto(
    batch: _importBatch(status: status),
    processedAt: DateTime.utc(2026, 7, 16, 8),
    isReplay: isReplay,
  );

  CustomerPriceRuleImportDetailDto _importDetail(
    GetCustomerPriceRuleImportQuery? query, {
    CustomerPriceRuleImportStatus status =
        CustomerPriceRuleImportStatus.readyToImport,
    List<String> fileErrorCodes = const [],
    List<String> rowErrorCodes = const [],
  }) => CustomerPriceRuleImportDetailDto(
    batch: _importBatch(status: status, fileErrorCodes: fileErrorCodes),
    rows: CursorPageDto(
      items: [
        CustomerPriceRuleImportRowPreviewDto(
          id: 'import-row-1',
          rowNumber: 2,
          ruleId: null,
          customerId: '00000000-0000-4000-8000-000000000011',
          productReferenceId: 'PROD-001',
          price: '120000',
          effectiveFrom: null,
          effectiveTo: null,
          note: 'ưu tiên',
          status: rowErrorCodes.isEmpty
              ? CustomerPriceRuleImportRowStatus.warning
              : CustomerPriceRuleImportRowStatus.error,
          action: CustomerPriceRuleImportAction.create,
          errorCodes: rowErrorCodes,
          warningCodes: rowErrorCodes.isEmpty
              ? const ['EFFECTIVE_FROM_DEFAULTED']
              : const [],
        ),
      ],
      hasMore: false,
      nextCursor: query?.cursor,
    ),
  );

  CustomerPriceRuleImportDto _importBatch({
    CustomerPriceRuleImportStatus status =
        CustomerPriceRuleImportStatus.readyToImport,
    List<String> fileErrorCodes = const [],
  }) => CustomerPriceRuleImportDto(
    id: 'import-1',
    templateVersion: CustomerPriceRuleImportTemplateDto.versionV1,
    originalFileName: CustomerPriceRuleImportTemplateDto.fileNameV1,
    importMode: CustomerPriceRuleImportMode.upsert,
    status: status,
    version: 1,
    totalRows: 1,
    validRows: 0,
    warningRows: 1,
    errorRows: 0,
    importedRows: status == CustomerPriceRuleImportStatus.completed ? 1 : 0,
    skippedRows: 0,
    failedRows: status == CustomerPriceRuleImportStatus.completedWithErrors
        ? 1
        : 0,
    fileErrorCodes: fileErrorCodes,
    createdAt: DateTime.utc(2026, 7, 16, 8),
    confirmedAt:
        status == CustomerPriceRuleImportStatus.completed ||
            status == CustomerPriceRuleImportStatus.completedWithErrors
        ? DateTime.utc(2026, 7, 16, 9)
        : null,
    canceledAt: status == CustomerPriceRuleImportStatus.canceled
        ? DateTime.utc(2026, 7, 16, 9)
        : null,
  );

  CustomerPriceRuleReenablePrecheckDto _reenablePrecheck(
    PrecheckCustomerPriceRuleReenableQuery query, {
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
      ruleVersion: query.expectedVersion,
      businessDate: query.businessDate,
    );
  }

  CustomerPriceRuleDetailDto _reenableDetail(
    ReenableCustomerPriceRuleCommand command, {
    bool warning = false,
  }) {
    final at = DateTime.utc(2026, 7, 16);
    return CustomerPriceRuleDetailDto(
      id: command.ruleId,
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
      version: command.expectedVersion + 1,
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

  CustomerPriceRuleDetailDto _disableDetail(
    DisableCustomerPriceRuleCommand command, {
    required String? reason,
  }) {
    final at = DateTime.utc(2026, 7, 16);
    return CustomerPriceRuleDetailDto(
      id: command.ruleId,
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
      version: command.expectedVersion + 1,
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

  CustomerPriceRuleDetailDto _deleteDetail(
    DeleteCustomerPriceRuleCommand command, {
    required int version,
  }) {
    final at = DateTime.utc(2026, 7, 16);
    return CustomerPriceRuleDetailDto(
      id: command.ruleId,
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
      persistedStatus: CustomerPriceRuleStatus.deleted,
      derivedStatus: CustomerPriceRuleDerivedStatus.deleted,
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
      version: version,
      availableActions: const [],
      deletedAt: at,
    );
  }

  CustomerPriceRuleDetailDto _updateDetail(
    UpdateCustomerPriceRuleCommand command, {
    int? version,
    bool warning = false,
    bool disabled = false,
  }) {
    final at = DateTime.utc(2026, 7, 16);
    return CustomerPriceRuleDetailDto(
      id: command.ruleId,
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
      price: MoneyDto(amountMinor: command.rulePriceMinor, currencyCode: 'VND'),
      effectivePeriod: EffectivePeriodDto(
        effectiveFrom: _calendarDate(command.effectiveFrom),
        effectiveTo: command.effectiveTo == null
            ? null
            : _calendarDate(command.effectiveTo!),
      ),
      ruleType: CustomerPriceRuleType.specialPrice,
      sourceType: CustomerPriceRuleSourceType.manual,
      persistedStatus: disabled
          ? CustomerPriceRuleStatus.disabled
          : CustomerPriceRuleStatus.active,
      derivedStatus: disabled
          ? CustomerPriceRuleDerivedStatus.disabled
          : CustomerPriceRuleDerivedStatus.applying,
      note: command.note?.trim(),
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
      version: version ?? command.expectedVersion + 1,
      availableActions: const [],
    );
  }

  CustomerPriceRuleDetailDto _detail(
    GetCustomerPriceRuleDetailQuery query, {
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
      id: query.ruleId,
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
      effectivePeriod: EffectivePeriodDto(effectiveFrom: query.businessDate),
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

  CustomerPriceRuleSearchResultDto _searchResult(
    SearchCustomerPriceRulesQuery query,
  ) {
    final businessDate = _calendarDate(query.businessDate);
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
    );
  }

  CreateCustomerPriceRuleResult _result(
    CreateCustomerPriceRuleCommand command, {
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
          customerId: command.customerId,
          displayName: 'Khách hàng mẫu',
          status: 'active',
        ),
        productUnit: ProductUnitRefDto(
          productId: command.productId,
          productName: 'Sản phẩm mẫu',
          productUnitId: command.productUnitId,
          unitName: 'Đơn vị mẫu',
          sellableStatus: 'active',
        ),
        price: MoneyDto(
          amountMinor: command.rulePriceMinor,
          currencyCode: command.currencyCode,
        ),
        effectivePeriod: EffectivePeriodDto(
          effectiveFrom: _calendarDate(command.effectiveFrom),
          effectiveTo: command.effectiveTo == null
              ? null
              : _calendarDate(command.effectiveTo!),
        ),
        ruleType: CustomerPriceRuleType.specialPrice,
        sourceType: CustomerPriceRuleSourceType.manual,
        persistedStatus: CustomerPriceRuleStatus.active,
        derivedStatus: CustomerPriceRuleDerivedStatus.applying,
        note: command.note,
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

  DateTime _calendarDate(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);

  Future<TResult> _handleRememberedPrice<TResult>(
    SaveRememberedPriceFromOrderCommand command,
  ) async {
    const requestId = '00000000-0000-4000-8000-000000000201';
    const ruleId = '00000000-0000-4000-8000-000000000301';

    switch (scenario) {
      case FakePricingScenario.memoryCreateOk:
        return const RememberedPriceOutcomeDto(
              requestId: requestId,
              resultType: RememberedPriceResultType.created,
              ruleId: ruleId,
              ruleVersion: 1,
              warnings: [],
              isReplay: false,
            )
            as TResult;
      case FakePricingScenario.memoryUpdateOk:
        return const RememberedPriceOutcomeDto(
              requestId: requestId,
              resultType: RememberedPriceResultType.updated,
              ruleId: ruleId,
              ruleVersion: 2,
              warnings: [],
              isReplay: false,
            )
            as TResult;
      case FakePricingScenario.memoryManualConflict:
        return const RememberedPriceOutcomeDto(
              requestId: requestId,
              resultType: RememberedPriceResultType.skipped,
              reasonCode: 'MANUAL_RULE_PROTECTED',
              warnings: [],
              isReplay: false,
            )
            as TResult;
      case FakePricingScenario.memoryRetrySamePayload:
        return const RememberedPriceOutcomeDto(
              requestId: requestId,
              resultType: RememberedPriceResultType.created,
              ruleId: ruleId,
              ruleVersion: 1,
              warnings: [],
              isReplay: true,
            )
            as TResult;
      case FakePricingScenario.memoryKeyConflict:
        throw const PricingBlockedException(
          PricingBlockedCodes.idempotencyConflict,
        );
      case FakePricingScenario.memoryAnonymousCustomer:
        return const RememberedPriceOutcomeDto(
              requestId: requestId,
              resultType: RememberedPriceResultType.skipped,
              reasonCode: 'ANONYMOUS_CUSTOMER',
              warnings: [],
              isReplay: false,
            )
            as TResult;
      case FakePricingScenario.memoryReferenceInvalid:
        return const RememberedPriceOutcomeDto(
              requestId: requestId,
              resultType: RememberedPriceResultType.blocked,
              reasonCode: 'REFERENCE_INVALID',
              warnings: [],
              isReplay: false,
            )
            as TResult;
      case FakePricingScenario.memoryBelowFloorBlocked:
        return const RememberedPriceOutcomeDto(
              requestId: requestId,
              resultType: RememberedPriceResultType.blocked,
              reasonCode: 'BELOW_FLOOR_BLOCKED',
              warnings: [],
              isReplay: false,
            )
            as TResult;
      case FakePricingScenario.memoryStaleSaleSkipped:
        return const RememberedPriceOutcomeDto(
              requestId: requestId,
              resultType: RememberedPriceResultType.skipped,
              reasonCode: 'STALE_SALE_EVENT',
              warnings: [],
              isReplay: false,
            )
            as TResult;
      case FakePricingScenario.memoryDisabledRememberedSkipped:
        return const RememberedPriceOutcomeDto(
              requestId: requestId,
              resultType: RememberedPriceResultType.skipped,
              reasonCode: 'REMEMBERED_RULE_DISABLED',
              warnings: [],
              isReplay: false,
            )
            as TResult;
      case FakePricingScenario.memorySystemError:
        throw const PricingBlockedException(PricingBlockedCodes.systemError);
      default:
        throw UnsupportedError(
          'FakePricingModule: ${scenario.name} does not support remembered price.',
        );
    }
  }
}

String? _normalizeOptional(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
