import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_application/testing.dart';
import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

final class _AllowAllPermissionChecker implements IPermissionChecker {
  @override
  Future<void> require(String permissionCode) async {}
}

final class _DenyPermissionChecker implements IPermissionChecker {
  String? lastPermissionCode;

  @override
  Future<void> require(String permissionCode) async {
    lastPermissionCode = permissionCode;
    throw const SalesContractException(
      'PERMISSION_DENIED',
      message: 'Denied in test.',
    );
  }
}

final class _RecordingPermissionChecker implements IPermissionChecker {
  final List<String> codes = <String>[];

  @override
  Future<void> require(String permissionCode) async {
    codes.add(permissionCode);
  }
}

ReturnExchangeLineInput _returnedLine() => ReturnExchangeLineInput(
  kind: ReturnExchangeLineKind.returnLine,
  productId: 'product-1',
  productUnitId: 'unit-1',
  quantity: const QuantityDto(quantityMicros: 1000000),
  originalSalesOrderLineId: 'source-line-1',
  reasonCode: 'DAMAGED',
  conditionCode: 'OPENED',
);

const ReturnExchangeSettlementPlanDto _plan = ReturnExchangeSettlementPlanDto(
  currencyCode: 'VND',
  netDifferenceMinor: -60000,
  collectAmountMinor: 0,
  refundAmountMinor: 60000,
  receivableCreateAmountMinor: 0,
  receivableReverseAmountMinor: 0,
  processedCollectMinor: 0,
  processedRefundMinor: 0,
  pendingReceivableCreateMinor: 0,
  pendingReceivableReverseMinor: 0,
  remainderCollectMinor: 0,
  remainderRefundMinor: 60000,
  sourceOrderVersion: 7,
  sourceSettlementVersion: 3,
  pricingSourceVersion: 11,
);

ReturnExchangeDetailDto _detail({
  bool completionReady = false,
  DateTime? confirmedAt,
  DateTime? completedAt,
  String? confirmedByActorId,
}) => ReturnExchangeDetailDto(
  result: const ReturnExchangeResultDto(
    returnExchangeId: 'return-1',
    salesOrderId: 'order-1',
    version: 3,
    status: ReturnExchangeStatus.draft,
  ),
  referenceNumber: 'RE-return-1',
  entrySource: ReturnExchangeEntrySource.standard,
  createdAt: DateTime.utc(2026, 8, 13),
  confirmedByActorId: confirmedByActorId,
  confirmedAt: confirmedAt,
  completedAt: completedAt,
  lines: const <ReturnExchangeDetailLineDto>[],
  valuation: ReturnExchangeValuationDto(
    returnValue: const MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
    exchangeValue: const MoneyDto(amountMinor: 40000, currencyCode: 'VND'),
    settlementDifference: const MoneyDto(amountMinor: -60000, currencyCode: 'VND'),
    settlementPlan: _plan,
    sourceOrderVersion: 7,
    pricingSourceVersion: 11,
  ),
  settlementPlan: _plan,
  completionReady: completionReady,
);

ReturnExchangeContext _context({
  String salesOrderId = 'order-1',
  List<ReturnExchangeLineInput>? lines,
}) => ReturnExchangeContext(
  draft: ReturnExchangeDraftDto(
    returnExchangeId: 'return-1',
    salesOrderId: salesOrderId,
    version: 3,
    status: ReturnExchangeStatus.draft,
    lines: lines ?? <ReturnExchangeLineInput>[_returnedLine()],
  ),
  currencyCode: 'VND',
  sourceOrderVersion: 7,
  sourceSettlementVersion: 3,
  reservationIds: const <String>['res-1'],
);

EvaluateReturnPricingImpactQuery _evaluateQuery({
  String returnExchangeId = 'return-1',
  int? expectedSourceVersion = 3,
}) => EvaluateReturnPricingImpactQuery(
  tenantId: 'tenant-1',
  actorId: 'actor-1',
  returnExchangeId: returnExchangeId,
  expectedSourceVersion: expectedSourceVersion,
);

RecordSalesPaymentCommand _paymentCommand({
  String tenantId = 'tenant-1',
  String actorId = 'actor-1',
  String salesOrderId = 'order-1',
  SalesPaymentMethod method = SalesPaymentMethod.cash,
  MoneyDto? amount,
  String idempotencyKey = 'idem-pay-1',
  String payloadHash = 'hash-pay-1',
  String correlationId = 'corr-pay-1',
  int expectedVersion = 2,
}) => RecordSalesPaymentCommand(
  tenantId: tenantId,
  actorId: actorId,
  salesOrderId: salesOrderId,
  method: method,
  amount: amount ?? const MoneyDto(amountMinor: 10000, currencyCode: 'VND'),
  idempotencyKey: idempotencyKey,
  payloadHash: payloadHash,
  correlationId: correlationId,
  expectedVersion: expectedVersion,
);

RecordSalesRefundCommand _refundCommand({
  String tenantId = 'tenant-1',
  String actorId = 'actor-1',
  String returnExchangeId = 'return-1',
  SalesPaymentMethod method = SalesPaymentMethod.manualBankTransfer,
  MoneyDto? amount,
  String idempotencyKey = 'idem-refund-1',
  String payloadHash = 'hash-refund-1',
  String correlationId = 'corr-refund-1',
  int expectedVersion = 2,
}) => RecordSalesRefundCommand(
  tenantId: tenantId,
  actorId: actorId,
  returnExchangeId: returnExchangeId,
  method: method,
  amount: amount ?? const MoneyDto(amountMinor: 5000, currencyCode: 'VND'),
  idempotencyKey: idempotencyKey,
  payloadHash: payloadHash,
  correlationId: correlationId,
  expectedVersion: expectedVersion,
);

void main() {
  group('TH-05 Group I S32–S33 valuation settlement application boundary', () {
    test('S32 evaluate checks view permission before context or providers', () async {
      final reads = FakeReturnExchangeReadGateway(contextResult: _context());
      final references = FakeReturnExchangeReferencePort.ready();
      final permission = _DenyPermissionChecker();
      final handler = EvaluateReturnPricingImpactQueryHandler(
        permissionChecker: permission,
        readGateway: reads,
        referencePort: references,
      );

      await expectLater(
        () => handler.handle(_evaluateQuery()),
        throwsA(isA<SalesContractException>()),
      );
      expect(permission.lastPermissionCode, SalesPermissions.viewReturnExchange);
      expect(reads.getContextCalls, 0);
      expect(references.evaluateCalls, 0);
      expect(reads.evaluateCalls, 0);
    });

    test('S32 provider blocker prevents valuation RPC', () async {
      final reads = FakeReturnExchangeReadGateway(contextResult: _context());
      final references = FakeReturnExchangeReferencePort.blocked(
        code: 'DEPENDENCY_UNAVAILABLE',
      );
      final handler = EvaluateReturnPricingImpactQueryHandler(
        permissionChecker: _AllowAllPermissionChecker(),
        readGateway: reads,
        referencePort: references,
      );

      await expectLater(
        () => handler.handle(
          EvaluateReturnPricingImpactQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            returnExchangeId: 'return-1',
            expectedSourceVersion: 3,
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
      expect(reads.evaluateCalls, 0);
      expect(reads.getContextCalls, 1);
      expect(references.evaluateCalls, 1);
      expect(references.lastReserveExchangeStock, isFalse);
    });

    test(
      'S32 evaluate loads context, calls reference with reserve=false, delegates once',
      () async {
        final valuation = const ReturnExchangeValuationDto(
          returnValue: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
          exchangeValue: MoneyDto(amountMinor: 40000, currencyCode: 'VND'),
          settlementDifference: MoneyDto(amountMinor: -60000, currencyCode: 'VND'),
          settlementPlan: _plan,
          sourceOrderVersion: 7,
          pricingSourceVersion: 11,
        );
        final reads = FakeReturnExchangeReadGateway(
          contextResult: _context(salesOrderId: 'order-99'),
          evaluateResult: valuation,
        );
        final references = FakeReturnExchangeReferencePort.ready(
          reservationIds: const <String>[],
        );
        final permission = _RecordingPermissionChecker();
        final handler = EvaluateReturnPricingImpactQueryHandler(
          permissionChecker: permission,
          readGateway: reads,
          referencePort: references,
        );

        final dto = await handler.handle(_evaluateQuery());

        expect(permission.codes, <String>[SalesPermissions.viewReturnExchange]);
        expect(reads.getContextCalls, 1);
        expect(reads.lastContextReturnExchangeId, 'return-1');
        expect(references.evaluateCalls, 1);
        expect(references.lastSalesOrderId, 'order-99');
        expect(references.lastReserveExchangeStock, isFalse);
        expect(reads.evaluateCalls, 1);
        expect(reads.lastEvaluateDecision?.allowed, isTrue);
        expect(dto.settlementDifference.amountMinor, -60000);
        expect(dto.pricingSourceVersion, 11);
        expect(dto.settlementPlan.netDifferenceMinor, -60000);
        expect(dto.settlementPlan.refundAmountMinor, 60000);
        expect(dto.settlementPlan.collectAmountMinor, 0);
        expect(dto.settlementPlan.sourceOrderVersion, 7);
        expect(dto.settlementPlan.sourceSettlementVersion, 3);
        expect(dto.settlementPlan.pricingSourceVersion, 11);
      },
    );

    test('S34 detail query checks view permission before gateway', () async {
      final gateway = FakeReturnExchangeReadGateway(
        detailResult: _detail(),
      );
      final permission = _DenyPermissionChecker();
      final handler = GetReturnExchangeDetailQueryHandler(
        permissionChecker: permission,
        returnExchangeReadGateway: gateway,
      );

      await expectLater(
        () => handler.handle(
          GetReturnExchangeDetailQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            returnExchangeId: 'return-1',
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
      expect(permission.lastPermissionCode, SalesPermissions.viewReturnExchange);
      expect(gateway.getDetailCalls, 0);
    });

    test('S34 detail preserves nullable draft timestamps and completionReady', () async {
      final detail = _detail(
        completionReady: false,
        confirmedAt: null,
        completedAt: null,
        confirmedByActorId: null,
      );
      final gateway = FakeReturnExchangeReadGateway(detailResult: detail);
      final handler = GetReturnExchangeDetailQueryHandler(
        permissionChecker: _AllowAllPermissionChecker(),
        returnExchangeReadGateway: gateway,
      );

      final dto = await handler.handle(
        GetReturnExchangeDetailQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          returnExchangeId: 'return-1',
          expectedVersion: 3,
        ),
      );

      expect(gateway.getDetailCalls, 1);
      expect(dto.confirmedAt, isNull);
      expect(dto.completedAt, isNull);
      expect(dto.confirmedByActorId, isNull);
      expect(dto.completionReady, isFalse);
      expect(dto.entrySource, ReturnExchangeEntrySource.standard);
    });

    test('S34 detail fake never invents fallback DTOs', () async {
      final gateway = FakeReturnExchangeReadGateway();
      await expectLater(
        () => gateway.getDetail(
          GetReturnExchangeDetailQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            returnExchangeId: 'return-1',
          ),
        ),
        throwsA(isA<StateError>()),
      );
      expect(gateway.getDetailCalls, 1);
    });

    test('S33 payment validator rejects non-positive amount and blank context', () async {
      final validator = RecordSalesPaymentCommandValidator();

      await expectLater(
        () => validator.validate(
          _paymentCommand(
            amount: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
          ),
        ),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'CONTEXT_INVALID',
          ),
        ),
      );
      await expectLater(
        () => validator.validate(
          _paymentCommand(
            amount: const MoneyDto(amountMinor: 100, currencyCode: ' '),
          ),
        ),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'CONTEXT_INVALID',
          ),
        ),
      );
      await expectLater(
        () => validator.validate(_paymentCommand(salesOrderId: ' ')),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'CONTEXT_INVALID',
          ),
        ),
      );
      await expectLater(
        () => validator.validate(_paymentCommand(tenantId: '')),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'CONTEXT_INVALID',
          ),
        ),
      );
      await expectLater(
        () => validator.validate(_paymentCommand(actorId: ' ')),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'CONTEXT_INVALID',
          ),
        ),
      );
      await expectLater(
        () => validator.validate(_paymentCommand(idempotencyKey: '')),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'CONTEXT_INVALID',
          ),
        ),
      );
      await expectLater(
        () => validator.validate(_paymentCommand(payloadHash: ' ')),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'CONTEXT_INVALID',
          ),
        ),
      );
      await expectLater(
        () => validator.validate(_paymentCommand(correlationId: '')),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'CONTEXT_INVALID',
          ),
        ),
      );
      await expectLater(
        () => validator.validate(_paymentCommand(expectedVersion: 0)),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'CONTEXT_INVALID',
          ),
        ),
      );
      await expectLater(
        validator.validate(
          _paymentCommand(method: SalesPaymentMethod.manualBankTransfer),
        ),
        completes,
      );
    });

    test('S33 refund validator rejects blank returnExchangeId and invalid money', () async {
      final validator = RecordSalesRefundCommandValidator();

      await expectLater(
        () => validator.validate(_refundCommand(returnExchangeId: ' ')),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'CONTEXT_INVALID',
          ),
        ),
      );
      await expectLater(
        () => validator.validate(
          _refundCommand(
            amount: const MoneyDto(amountMinor: -1, currencyCode: 'VND'),
          ),
        ),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'CONTEXT_INVALID',
          ),
        ),
      );
      await expectLater(
        () => validator.validate(_refundCommand(expectedVersion: -3)),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'CONTEXT_INVALID',
          ),
        ),
      );
      await expectLater(validator.validate(_refundCommand()), completes);
    });

    test('S33 payment handler delegates exactly once to settlement gateway', () async {
      final gateway = FakeReturnExchangeSettlementGateway(
        paymentResult: const SalesOrderPaymentSummaryDto(
          status: SalesSettlementStatus.partiallyPaid,
          orderTotal: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
          paidTotal: MoneyDto(amountMinor: 10000, currencyCode: 'VND'),
          outstandingTotal: MoneyDto(amountMinor: 90000, currencyCode: 'VND'),
        ),
      );
      final handler = RecordSalesPaymentCommandHandler(
        settlementGateway: gateway,
      );

      final summary = await handler.handle(_paymentCommand());

      expect(gateway.recordPaymentCalls, 1);
      expect(gateway.recordRefundCalls, 0);
      expect(gateway.lastPaymentCommand?.salesOrderId, 'order-1');
      expect(gateway.lastPaymentCommand?.correlationId, 'corr-pay-1');
      expect(summary.paidTotal.amountMinor, 10000);
    });

    test('S33 refund handler delegates exactly once to settlement gateway', () async {
      final gateway = FakeReturnExchangeSettlementGateway(
        refundResult: const ReturnExchangeSettlementResultDto(
          returnExchangeId: 'return-1',
          difference: MoneyDto(amountMinor: 5000, currencyCode: 'VND'),
          status: SalesSettlementStatus.partiallyRefunded,
        ),
      );
      final handler = RecordSalesRefundCommandHandler(
        settlementGateway: gateway,
      );

      final result = await handler.handle(_refundCommand());

      expect(gateway.recordRefundCalls, 1);
      expect(gateway.recordPaymentCalls, 0);
      expect(gateway.lastRefundCommand?.returnExchangeId, 'return-1');
      expect(result.difference.amountMinor, 5000);
    });
  });
}
