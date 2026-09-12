import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_application/testing.dart';
import 'package:vet45_shared_application/application.dart';

final class _AllowAllPermissionChecker implements IPermissionChecker {
  @override
  Future<void> require(String permissionCode) async {}
}

final class _DenyPermissionChecker implements IPermissionChecker {
  _DenyPermissionChecker();

  String? lastRequiredPermission;

  @override
  Future<void> require(String permissionCode) async {
    lastRequiredPermission = permissionCode;
    throw const SalesContractException('PERMISSION_DENIED', message: 'Denied in test.');
  }
}

void main() {
  group('TH-05 Group H S23 cancellation application boundary', () {
    test('S23 precheck uses the cancellation owner gateway', () async {
      final gateway = FakeSalesOrderCancellationGateway(
        precheckResult: CancellationPrecheckDto(
          allowed: false,
          sourceVersion: 7,
          sourceSettlementVersion: 3,
          blockers: const <SalesBlockerDto>[
            SalesBlockerDto(
              code: 'PAYMENT_ALREADY_COLLECTED',
              message: 'Use return/exchange.',
            ),
          ],
        ),
      );
      final handler = PrecheckSalesOrderCancellationQueryHandler(
        permissionChecker: _AllowAllPermissionChecker(),
        cancellationGateway: gateway,
      );

      final result = await handler.handle(
        PrecheckSalesOrderCancellationQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
          expectedSourceVersion: 7,
        ),
      );

      expect(result.allowed, isFalse);
      expect(gateway.precheckCalls, 1);
      expect(gateway.lastPrecheckQuery?.salesOrderId, 'order-1');
    });

    test('S23 precheck enforces sales.order.cancel before the gateway', () async {
      final gateway = FakeSalesOrderCancellationGateway();
      final permissionChecker = _DenyPermissionChecker();
      final handler = PrecheckSalesOrderCancellationQueryHandler(
        permissionChecker: permissionChecker,
        cancellationGateway: gateway,
      );

      await expectLater(
        () => handler.handle(
          PrecheckSalesOrderCancellationQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
            expectedSourceVersion: 7,
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
      expect(permissionChecker.lastRequiredPermission, 'sales.order.cancel');
      expect(gateway.precheckCalls, 0);
    });

    test(
      'S23 return/exchange conflict query adapts to inquiry return summary',
      () async {
        final inquiry = FakeSalesOrderInquiryGateway(
          returnSummary: SalesOrderReturnSummaryDto(
            salesOrderId: 'order-1',
            returns: const [],
          ),
        );
        final handler = GetReturnExchangeOrdersBySalesOrderQueryHandler(
          permissionChecker: _AllowAllPermissionChecker(),
          inquiryGateway: inquiry,
        );

        final result = await handler.handle(
          GetReturnExchangeOrdersBySalesOrderQuery(
            id: 'query-1',
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
            expectedSourceVersion: 7,
          ),
        );

        expect(result.salesOrderId, 'order-1');
        expect(inquiry.returnSummaryCalls, 1);
        expect(inquiry.lastReturnSummaryQuery, isA<GetSalesOrderReturnSummaryQuery>());
        expect(inquiry.lastReturnSummaryQuery?.id, 'query-1');
        expect(inquiry.lastReturnSummaryQuery?.tenantId, 'tenant-1');
        expect(inquiry.lastReturnSummaryQuery?.actorId, 'actor-1');
        expect(inquiry.lastReturnSummaryQuery?.salesOrderId, 'order-1');
        expect(inquiry.lastReturnSummaryQuery?.expectedSourceVersion, 7);
      },
    );

    test(
      'S23 return/exchange conflict query enforces sales.return_exchange.view before gateway',
      () async {
        final inquiry = FakeSalesOrderInquiryGateway();
        final permissionChecker = _DenyPermissionChecker();
        final handler = GetReturnExchangeOrdersBySalesOrderQueryHandler(
          permissionChecker: permissionChecker,
          inquiryGateway: inquiry,
        );

        await expectLater(
          () => handler.handle(
            GetReturnExchangeOrdersBySalesOrderQuery(
              tenantId: 'tenant-1',
              actorId: 'actor-1',
              salesOrderId: 'order-1',
            ),
          ),
          throwsA(isA<SalesContractException>()),
        );
        expect(
          permissionChecker.lastRequiredPermission,
          'sales.return_exchange.view',
        );
        expect(inquiry.returnSummaryCalls, 0);
        expect(inquiry.lastReturnSummaryQuery, isNull);
      },
    );
  });

  group('TH-05 Group H S24–S25 confirmation and S27 detail', () {
    test('S24 reject blank tenant actor and order ids', () async {
      final validator = ConfirmSalesOrderCancellationCommandValidator();

      await expectLater(
        () => validator.validate(_confirmCommand(tenantId: '   ')),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'CONTEXT_INVALID',
          ),
        ),
      );
      await expectLater(
        () => validator.validate(_confirmCommand(actorId: '')),
        throwsA(isA<SalesContractException>()),
      );
      await expectLater(
        () => validator.validate(_confirmCommand(salesOrderId: ' ')),
        throwsA(isA<SalesContractException>()),
      );
    });

    test('S24 reject missing idempotency payload and correlation', () async {
      final validator = ConfirmSalesOrderCancellationCommandValidator();

      await expectLater(
        () => validator.validate(_confirmCommand(idempotencyKey: '')),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'CONTEXT_INVALID',
          ),
        ),
      );
      await expectLater(
        () => validator.validate(_confirmCommand(payloadHash: '  ')),
        throwsA(isA<SalesContractException>()),
      );
      await expectLater(
        () => validator.validate(_confirmCommand(correlationId: '')),
        throwsA(isA<SalesContractException>()),
      );
    });

    test('S24 reject non-positive order and settlement versions', () async {
      final validator = ConfirmSalesOrderCancellationCommandValidator();

      await expectLater(
        () => validator.validate(_confirmCommand(expectedVersion: 0)),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'CONTEXT_INVALID',
          ),
        ),
      );
      await expectLater(
        () => validator.validate(_confirmCommand(expectedSettlementVersion: -1)),
        throwsA(isA<SalesContractException>()),
      );
    });

    test('S24 accepts optional cancellation reason', () async {
      final validator = ConfirmSalesOrderCancellationCommandValidator();
      for (final reason in ['', '   ', 'Khách đổi ý']) {
        await expectLater(
          validator.validate(
            _confirmCommand(
              reason: CancellationReasonDto(reasonText: reason),
            ),
          ),
          completes,
        );
      }
    });

    test('S25 confirm delegates once and returns the committed result', () async {
      const committed = SalesOrderCancellationResultDto(
        cancellationId: 'cancel-1',
        salesOrderId: 'order-1',
        salesOrderVersion: 8,
        status: SalesOrderCancellationStatus.completed,
      );
      final gateway = FakeSalesOrderCancellationGateway(
        confirmResult: committed,
      );
      final result = await ConfirmSalesOrderCancellationCommandHandler(
        cancellationGateway: gateway,
      ).handle(_confirmCommand());
      expect(result, same(committed));
      expect(gateway.confirmCalls, 1);
    });

    test('S25 confirm passes gateway exceptions through unchanged', () async {
      final gateway = FakeSalesOrderCancellationGateway(
        error: const SalesContractException('STALE_VERSION'),
      );
      final handler = ConfirmSalesOrderCancellationCommandHandler(
        cancellationGateway: gateway,
      );

      await expectLater(
        () => handler.handle(_confirmCommand()),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'STALE_VERSION',
          ),
        ),
      );
      expect(gateway.confirmCalls, 1);
    });

    test('S27 detail enforces sales.order.view before the gateway', () async {
      final gateway = FakeSalesOrderCancellationGateway();
      final permissionChecker = _DenyPermissionChecker();
      final handler = GetSalesOrderCancellationQueryHandler(
        permissionChecker: permissionChecker,
        cancellationGateway: gateway,
      );

      await expectLater(
        () => handler.handle(
          GetSalesOrderCancellationQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
      expect(permissionChecker.lastRequiredPermission, 'sales.order.view');
      expect(gateway.detailCalls, 0);
    });

    test('S27 detail delegates once after permission', () async {
      final detail = SalesOrderCancellationDetailDto(
        result: const SalesOrderCancellationResultDto(
          cancellationId: 'cancel-1',
          salesOrderId: 'order-1',
          salesOrderVersion: 8,
          status: SalesOrderCancellationStatus.completed,
        ),
        reason: const CancellationReasonDto(
          reasonText: 'Changed mind',
        ),
        cancelledAt: DateTime.utc(2026, 8, 10),
        cancelledByActorId: 'actor-99',
        netConfirmedCollectionMinor: 0,
      );
      final gateway = FakeSalesOrderCancellationGateway(detailResult: detail);
      final handler = GetSalesOrderCancellationQueryHandler(
        permissionChecker: _AllowAllPermissionChecker(),
        cancellationGateway: gateway,
      );

      final result = await handler.handle(
        GetSalesOrderCancellationQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
          expectedSourceVersion: 8,
        ),
      );

      expect(result, same(detail));
      expect(gateway.detailCalls, 1);
      expect(gateway.lastDetailQuery?.salesOrderId, 'order-1');
    });

    test('S27 detail passes gateway exceptions through unchanged', () async {
      final gateway = FakeSalesOrderCancellationGateway(
        error: const SalesContractException('CANCELLATION_BLOCKED'),
      );
      final handler = GetSalesOrderCancellationQueryHandler(
        permissionChecker: _AllowAllPermissionChecker(),
        cancellationGateway: gateway,
      );

      await expectLater(
        () => handler.handle(
          GetSalesOrderCancellationQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
          ),
        ),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'CANCELLATION_BLOCKED',
          ),
        ),
      );
      expect(gateway.detailCalls, 1);
    });

    test('S27 detail carries cancelledByActorId and netConfirmedCollectionMinor', () async {
      final detail = SalesOrderCancellationDetailDto(
        result: const SalesOrderCancellationResultDto(
          cancellationId: 'cancel-1',
          salesOrderId: 'order-1',
          salesOrderVersion: 8,
          status: SalesOrderCancellationStatus.completed,
        ),
        reason: const CancellationReasonDto(
          reasonText: 'Changed mind',
        ),
        cancelledAt: DateTime.utc(2026, 8, 10),
        cancelledByActorId: 'actor-99',
        netConfirmedCollectionMinor: 0,
      );
      final gateway = FakeSalesOrderCancellationGateway(detailResult: detail);
      final handler = GetSalesOrderCancellationQueryHandler(
        permissionChecker: _AllowAllPermissionChecker(),
        cancellationGateway: gateway,
      );

      final result = await handler.handle(
        GetSalesOrderCancellationQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
          expectedSourceVersion: 8,
        ),
      );

      expect(result.cancelledByActorId, 'actor-99');
      expect(result.netConfirmedCollectionMinor, 0);
    });
  });

  group('TH-05 Group H S24 cancellation reason policy application boundary', () {
    test('S24 list reasons enforces sales.order.cancel before the gateway', () async {
      final gateway = FakeSalesOrderCancellationGateway();
      final permissionChecker = _DenyPermissionChecker();
      final handler = ListSalesOrderCancellationReasonsQueryHandler(
        permissionChecker: permissionChecker,
        cancellationGateway: gateway,
      );

      await expectLater(
        () => handler.handle(
          ListSalesOrderCancellationReasonsQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
      expect(permissionChecker.lastRequiredPermission, 'sales.order.cancel');
      expect(gateway.listReasonsCalls, 0);
    });

    test('S24 authorized list delegates once and returns ordered policies unchanged', () async {
      final policies = <CancellationReasonPolicyDto>[
        const CancellationReasonPolicyDto(
          reasonCode: 'DUPLICATE',
          displayName: 'Nhập trùng đơn',
          requiresNote: false,
          sortOrder: 100,
        ),
        const CancellationReasonPolicyDto(
          reasonCode: 'OTHER',
          displayName: 'Khác',
          requiresNote: true,
          sortOrder: 900,
        ),
      ];
      final gateway = FakeSalesOrderCancellationGateway(reasonPolicies: policies);
      final handler = ListSalesOrderCancellationReasonsQueryHandler(
        permissionChecker: _AllowAllPermissionChecker(),
        cancellationGateway: gateway,
      );

      final result = await handler.handle(
        ListSalesOrderCancellationReasonsQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
        ),
      );

      expect(result, hasLength(2));
      expect(result.first.reasonCode, 'DUPLICATE');
      expect(result.last.reasonCode, 'OTHER');
      expect(result.last.displayName, 'Khác');
      expect(result.last.requiresNote, isTrue);
      expect(gateway.listReasonsCalls, 1);
      expect(gateway.lastListReasonsQuery?.tenantId, 'tenant-1');
    });

    test('S24 list reasons passes gateway exceptions through unchanged', () async {
      final gateway = FakeSalesOrderCancellationGateway(
        error: const SalesContractException('DEPENDENCY_UNAVAILABLE'),
      );
      final handler = ListSalesOrderCancellationReasonsQueryHandler(
        permissionChecker: _AllowAllPermissionChecker(),
        cancellationGateway: gateway,
      );

      await expectLater(
        () => handler.handle(
          ListSalesOrderCancellationReasonsQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
          ),
        ),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'DEPENDENCY_UNAVAILABLE',
          ),
        ),
      );
      expect(gateway.listReasonsCalls, 1);
    });
  });
}

ConfirmSalesOrderCancellationCommand _confirmCommand({
  String tenantId = 'tenant-1',
  String actorId = 'actor-1',
  String salesOrderId = 'order-1',
  CancellationReasonDto reason = const CancellationReasonDto(
    reasonText: 'Customer request',
  ),
  String idempotencyKey = 'idempotency-1',
  String payloadHash = 'payload-hash-1',
  String correlationId = 'correlation-1',
  int expectedVersion = 7,
  int expectedSettlementVersion = 3,
}) => ConfirmSalesOrderCancellationCommand(
  tenantId: tenantId,
  actorId: actorId,
  salesOrderId: salesOrderId,
  reason: reason,
  idempotencyKey: idempotencyKey,
  payloadHash: payloadHash,
  correlationId: correlationId,
  expectedVersion: expectedVersion,
  expectedSettlementVersion: expectedSettlementVersion,
);
