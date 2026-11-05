import '../../iam/support/iam_test_session.dart';
import '../../pricing/support/fake_customer_price_rule_repository.dart';
import '../support/recording_sales_pricing_repository.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/features/pricing/data/customer_price_rule_repository.dart';
import 'package:erp/features/pricing/data/models.dart';
import 'package:erp/features/pricing/data/pricing_errors.dart';
import 'package:erp/features/pricing/data/sales_pricing_repository.dart';
import 'package:erp/features/sales/presentation.dart';
import 'package:erp/features/sales/presentation/lookups/sales_pricing_lookup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:vet45_sales_application/application.dart' as sales;

void main() {
  late GetIt di;
  late RecordingSalesPricingRepository salesPricing;
  late _ScriptedCustomerPriceRuleRepository rules;

  setUp(() {
    di = GetIt.asNewInstance();
    salesPricing = RecordingSalesPricingRepository();
    rules = _ScriptedCustomerPriceRuleRepository();
    di
      ..registerSingleton<SalesPricingRepository>(salesPricing)
      ..registerSingleton<CustomerPriceRuleRepository>(rules)
      ..registerSingleton<SessionController>(
        testSessionController(
          tenantId: 'tenant-1',
          userId: 'user-1',
          activeStoreId: 'store-1',
        ),
      );
  });

  test('manual evaluation maps owner result without mutation', () async {
    salesPricing.evaluateResponder = ({
      required storeId,
      customerId,
      required productId,
      required productUnitId,
      required quantityMicros,
      required currencyCode,
      required contextVersion,
      manualUnitPriceMinor,
      manualDiscountMinor,
      manualDiscountBasisPoints,
      required acknowledgeBelowFloor,
    }) => const SalesManualPriceEvaluationDto(
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
    expect(rules.calls, isEmpty);
    final call = salesPricing.evaluateCalls.single;
    expect(call.storeId, 'store-1');
  });

  test('missing rule creates immediately with stable idempotency key', () async {
    rules.resolveResults.addAll([
      const ResolveApplicableCustomerPriceRuleResultDto(),
    ]);
    rules.createdRule = _rule(ruleId: 'rule-created', version: 1);

    final result = await SalesPricingLookup.bindSavePrivate(di)(_saveRequest);

    expect(result.created, isTrue);
    final createCalls = rules.calls.where((c) => c.method == 'create').toList();
    expect(createCalls, hasLength(1));
    expect(
      createCalls.single.args['idempotencyKey'],
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
    rules.resolveResults.add(existingResult);

    final pending = await SalesPricingLookup.bindSavePrivate(di)(_saveRequest);
    expect(pending.overwriteConfirmationRequired, isTrue);
    expect(rules.calls.where((c) => c.method != 'resolveApplicable'), isEmpty);

    rules.resolveResults.add(existingResult);
    rules.updatedRule = _rule(ruleId: 'rule-1', version: 5);
    final updated = await SalesPricingLookup.bindSavePrivate(di)(
      _saveRequest.copyWith(confirmOverwrite: true),
    );
    expect(updated.created, isFalse);
    final updateCalls = rules.calls.where((c) => c.method == 'update').toList();
    expect(updateCalls, hasLength(1));
    expect(updateCalls.single.args['ruleId'], 'rule-1');
    expect(updateCalls.single.args['expectedVersion'], 4);
  });

  test('missing customer fails before any Pricing call', () async {
    await expectLater(
      SalesPricingLookup.bindSavePrivate(di)(
        _saveRequest.copyWith(clearCustomerId: true),
      ),
      throwsA(isA<SalesExternalOperationException>()),
    );
    expect(salesPricing.previewCalls, isEmpty);
    expect(salesPricing.evaluateCalls, isEmpty);
    expect(rules.calls, isEmpty);
  });

  test('uncertain create reads back then retries same key only when absent', () async {
    rules.resolveResults.addAll([
      const ResolveApplicableCustomerPriceRuleResultDto(),
      const ResolveApplicableCustomerPriceRuleResultDto(),
    ]);
    rules.commandFailures.addAll([true, false]);
    rules.createdRule = _rule(ruleId: 'rule-created', version: 1);

    final result = await SalesPricingLookup.bindSavePrivate(di)(_saveRequest);

    expect(result.ruleId, 'rule-created');
    final createCalls = rules.calls.where((c) => c.method == 'create').toList();
    expect(createCalls, hasLength(2));
    expect(
      createCalls.last.args['idempotencyKey'],
      createCalls.first.args['idempotencyKey'],
    );
  });

  test('uncertain create accepts matching read-back without replay', () async {
    rules.resolveResults.addAll([
      const ResolveApplicableCustomerPriceRuleResultDto(),
      _applicableResult(ruleId: 'rule-recovered', version: 1, price: 90000),
    ]);
    rules.commandFailures.add(true);

    final result = await SalesPricingLookup.bindSavePrivate(di)(_saveRequest);

    expect(result.ruleId, 'rule-recovered');
    final createCalls = rules.calls.where((c) => c.method == 'create').toList();
    expect(createCalls, hasLength(1));
  });

  test('uncertain update reads back newer accepted state and never replays', () async {
    rules.resolveResults.addAll([
      _applicableResult(ruleId: 'rule-1', version: 4, price: 100000),
      _applicableResult(ruleId: 'rule-1', version: 5, price: 90000),
    ]);
    rules.commandFailures.add(true);

    final result = await SalesPricingLookup.bindSavePrivate(di)(
      _saveRequest.copyWith(confirmOverwrite: true),
    );

    expect(result.version, 5);
    final updateCalls = rules.calls.where((c) => c.method == 'update').toList();
    expect(updateCalls, hasLength(1));
  });

  test('lookup_error_message_uses_server_text', () async {
    salesPricing.evaluateResponder = ({
      required storeId,
      customerId,
      required productId,
      required productUnitId,
      required quantityMicros,
      required currencyCode,
      required contextVersion,
      manualUnitPriceMinor,
      manualDiscountMinor,
      manualDiscountBasisPoints,
      required acknowledgeBelowFloor,
    }) {
      throw const AppException(
        PricingErrorCodes.belowFloorBlocked,
        serverMessage: 'Price is below floor.',
      );
    };

    await expectLater(
      SalesPricingLookup.bindEvaluate(di)(_manualRequest),
      throwsA(
        isA<SalesExternalOperationException>().having(
          (e) => e.message,
          'message',
          'Giá nhập thấp hơn giá sàn quy định.',
        ),
      ),
    );
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

final class _ScriptedCustomerPriceRuleRepository
    extends FakeCustomerPriceRuleRepository {
  final resolveResults = <ResolveApplicableCustomerPriceRuleResultDto>[];
  CustomerPriceRuleDetailDto? createdRule;
  CustomerPriceRuleDetailDto? updatedRule;
  final commandFailures = <bool>[];

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
    return resolveResults.removeAt(0);
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
    if (commandFailures.isNotEmpty && commandFailures.removeAt(0)) {
      throw StateError('transport uncertain');
    }
    return CreateCustomerPriceRuleResult(
      rule: createdRule!,
      warnings: const [],
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
        'changeReason': changeReason,
        'acknowledgeFloorWarning': acknowledgeFloorWarning,
        'acknowledgeOverwrite': acknowledgeOverwrite,
      }),
    );
    if (commandFailures.isNotEmpty && commandFailures.removeAt(0)) {
      throw StateError('transport uncertain');
    }
    return updatedRule!;
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
