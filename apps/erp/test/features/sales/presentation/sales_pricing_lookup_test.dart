import '../../iam/support/iam_test_session.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_sales_application/application.dart' as sales;
import 'package:erp/features/sales/presentation.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:erp/features/sales/presentation/lookups/sales_pricing_lookup.dart';

void main() {
  late GetIt di;
  late _RecordingPricingModule pricing;

  setUp(() {
    di = GetIt.asNewInstance();
    pricing = _RecordingPricingModule();
    di
      ..registerSingleton<IPricingModule>(pricing)
      ..registerSingleton<IExecutionContext>(const _ExecutionContext())
      ..registerSingleton<SessionController>(
        testSessionController(tenantId: 'tenant-1', userId: 'user-1', activeStoreId: 'store-1'),
      );
  });

  test('manual evaluation maps owner result without mutation', () async {
    pricing.manualResult = const SalesManualPriceEvaluationDto(
      allowed: true,
      requiresAcknowledgement: false,
      normalizedUnitPriceMinor: 90000,
      floorPriceMinor: null,
      canViewFloor: false,
      warningCodes: [],
      blockingCode: null,
      message: null,
    );

    final result = await SalesPricingLookup.bindEvaluate(di)(_manualRequest);

    expect(result.allowed, isTrue);
    expect(result.normalizedUnitPrice.amountMinor, 90000);
    expect(pricing.commands, isEmpty);
    final query = pricing.queries.single as EvaluateSalesManualPriceQuery;
    expect(query.tenantId, 'tenant-1');
    expect(query.storeId, 'store-1');
  });

  test('missing rule creates immediately with stable idempotency key', () async {
    pricing.resolveResults.addAll([
      const ResolveApplicableCustomerPriceRuleResultDto(),
    ]);
    pricing.createdRule = _rule(ruleId: 'rule-created', version: 1);

    final result = await SalesPricingLookup.bindSavePrivate(di)(_saveRequest);

    expect(result.created, isTrue);
    final command = pricing.commands.single as CreateCustomerPriceRuleCommand;
    expect(
      command.idempotencyKey,
      'sales-private-price-v1:tenant-1:store-1:compose-1:line-1:3:'
      'customer-1:product-1:unit-1:VND:90000:2026-08-11',
    );
  });

  test('existing rule requires overwrite confirmation before update', () async {
    final existingResult = ResolveApplicableCustomerPriceRuleResultDto(
      rule: ApplicableCustomerPriceRuleDto(
        ruleId: 'rule-1',
        price: const MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
        effectivePeriod: EffectivePeriodDto(
          effectiveFrom: DateTime.utc(2026, 8, 1),
          effectiveTo: null,
        ),
        sourceType: CustomerPriceRuleSourceType.manual,
        version: 4,
      ),
    );
    pricing.resolveResults.add(existingResult);

    final pending = await SalesPricingLookup.bindSavePrivate(di)(_saveRequest);
    expect(pending.overwriteConfirmationRequired, isTrue);
    expect(pricing.commands, isEmpty);

    pricing.resolveResults.add(existingResult);
    pricing.updatedRule = _rule(ruleId: 'rule-1', version: 5);
    final updated = await SalesPricingLookup.bindSavePrivate(di)(
      _saveRequest.copyWith(confirmOverwrite: true),
    );
    expect(updated.created, isFalse);
    final command = pricing.commands.single as UpdateCustomerPriceRuleCommand;
    expect(command.ruleId, 'rule-1');
    expect(command.expectedVersion, 4);
  });

  test('missing customer fails before any Pricing call', () async {
    await expectLater(
      SalesPricingLookup.bindSavePrivate(di)(
        _saveRequest.copyWith(clearCustomerId: true),
      ),
      throwsA(isA<SalesExternalOperationException>()),
    );
    expect(pricing.queries, isEmpty);
    expect(pricing.commands, isEmpty);
  });

  test('uncertain create reads back then retries same key only when absent', () async {
    pricing.resolveResults.addAll([
      const ResolveApplicableCustomerPriceRuleResultDto(),
      const ResolveApplicableCustomerPriceRuleResultDto(),
    ]);
    pricing.commandFailures.addAll([true, false]);
    pricing.createdRule = _rule(ruleId: 'rule-created', version: 1);

    final result = await SalesPricingLookup.bindSavePrivate(di)(_saveRequest);

    expect(result.ruleId, 'rule-created');
    expect(pricing.commands, hasLength(2));
    final first = pricing.commands.first as CreateCustomerPriceRuleCommand;
    final second = pricing.commands.last as CreateCustomerPriceRuleCommand;
    expect(second.idempotencyKey, first.idempotencyKey);
  });

  test('uncertain create accepts matching read-back without replay', () async {
    pricing.resolveResults.addAll([
      const ResolveApplicableCustomerPriceRuleResultDto(),
      _applicableResult(ruleId: 'rule-recovered', version: 1, price: 90000),
    ]);
    pricing.commandFailures.add(true);

    final result = await SalesPricingLookup.bindSavePrivate(di)(_saveRequest);

    expect(result.ruleId, 'rule-recovered');
    expect(pricing.commands, hasLength(1));
  });

  test('uncertain update reads back newer accepted state and never replays', () async {
    pricing.resolveResults.addAll([
      _applicableResult(ruleId: 'rule-1', version: 4, price: 100000),
      _applicableResult(ruleId: 'rule-1', version: 5, price: 90000),
    ]);
    pricing.commandFailures.add(true);

    final result = await SalesPricingLookup.bindSavePrivate(di)(
      _saveRequest.copyWith(confirmOverwrite: true),
    );

    expect(result.version, 5);
    expect(pricing.commands, hasLength(1));
    expect(pricing.commands.single, isA<UpdateCustomerPriceRuleCommand>());
  });
}

final _manualRequest = SalesManualPriceRequest(
  customerId: 'customer-1',
  productId: 'product-1',
  productUnitId: 'unit-1',
  quantityMicros: 1000000,
  currencyCode: 'VND',
  contextVersion: 2,
  manualUnitPriceMinor: 90000,
  manualDiscountMinor: null,
  manualDiscountBasisPoints: null,
  acknowledgeBelowFloor: false,
);

final _saveRequest = SalesPrivatePriceSaveRequest(
  composeSessionId: 'compose-1',
  sourceLineId: 'line-1',
  manualIntentRevision: 3,
  customerId: 'customer-1',
  productId: 'product-1',
  productUnitId: 'unit-1',
  acceptedUnitPrice: const sales.MoneyDto(
    amountMinor: 90000,
    currencyCode: 'VND',
  ),
  currencyCode: 'VND',
  effectiveFrom: DateTime.utc(2026, 8, 11),
  contextVersion: 2,
  acknowledgeFloorWarning: false,
  confirmOverwrite: false,
);

final class _RecordingPricingModule implements IPricingModule {
  final queries = <IQuery<dynamic>>[];
  final commands = <ICommand<dynamic>>[];
  final resolveResults = <ResolveApplicableCustomerPriceRuleResultDto>[];
  SalesManualPriceEvaluationDto? manualResult;
  CustomerPriceRuleDetailDto? createdRule;
  CustomerPriceRuleDetailDto? updatedRule;
  final commandFailures = <bool>[];

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    queries.add(query);
    if (query is EvaluateSalesManualPriceQuery) return manualResult as TResult;
    if (query is ResolveApplicableCustomerPriceRuleQuery) {
      return resolveResults.removeAt(0) as TResult;
    }
    throw UnimplementedError('$query');
  }

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    commands.add(command);
    if (commandFailures.isNotEmpty && commandFailures.removeAt(0)) {
      throw StateError('transport uncertain');
    }
    if (command is CreateCustomerPriceRuleCommand) {
      return CreateCustomerPriceRuleResult(
            rule: createdRule!,
            warnings: const [],
          )
          as TResult;
    }
    if (command is UpdateCustomerPriceRuleCommand) return updatedRule as TResult;
    throw UnimplementedError('$command');
  }
}

CustomerPriceRuleDetailDto _rule({required String ruleId, required int version}) =>
    CustomerPriceRuleDetailDto(
      id: ruleId,
      customer: const CustomerRefDto(
        customerId: 'customer-1',
        displayName: 'Khach A',
        status: 'active',
      ),
      productUnit: const ProductUnitRefDto(
        productId: 'product-1',
        productName: 'San pham A',
        productUnitId: 'unit-1',
        unitName: 'Hop',
        sellableStatus: 'active',
      ),
      price: const MoneyDto(amountMinor: 90000, currencyCode: 'VND'),
      effectivePeriod: EffectivePeriodDto(
        effectiveFrom: DateTime.utc(2026, 8, 11),
      ),
      ruleType: CustomerPriceRuleType.specialPrice,
      sourceType: CustomerPriceRuleSourceType.manual,
      persistedStatus: CustomerPriceRuleStatus.active,
      derivedStatus: CustomerPriceRuleDerivedStatus.applying,
      validationOutcome: const RuleValidationOutcomeDto(
        outcome: 'clear',
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
      createdBy: 'user-1',
      createdAt: DateTime.utc(2026, 8, 11),
      updatedBy: 'user-1',
      updatedAt: DateTime.utc(2026, 8, 11),
      version: version,
      availableActions: const [],
    );

ResolveApplicableCustomerPriceRuleResultDto _applicableResult({
  required String ruleId,
  required int version,
  required int price,
}) => ResolveApplicableCustomerPriceRuleResultDto(
  rule: ApplicableCustomerPriceRuleDto(
    ruleId: ruleId,
    price: MoneyDto(amountMinor: price, currencyCode: 'VND'),
    effectivePeriod: EffectivePeriodDto(
      effectiveFrom: DateTime.utc(2026, 8, 11),
    ),
    sourceType: CustomerPriceRuleSourceType.manual,
    version: version,
  ),
);

final class _ExecutionContext implements IExecutionContext {
  const _ExecutionContext();
  @override
  String get correlationId => 'corr-1';
  @override
  Future<String> requireTenantId() async => 'tenant-1';
  @override
  Future<String> requireUserId() async => 'user-1';
}

