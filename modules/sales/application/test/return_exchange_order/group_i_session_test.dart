import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_application/testing.dart';
import 'package:vet45_shared_application/application.dart';

final class _AllowAllPermissionChecker implements IPermissionChecker {
  @override
  Future<void> require(String permissionCode) async {}
}

final class _DenyPermissionChecker implements IPermissionChecker {
  @override
  Future<void> require(String permissionCode) async {
    throw const SalesContractException(
      'PERMISSION_DENIED',
      message: 'Denied in test.',
    );
  }
}

ReturnExchangeLineInput _returnedLine({
  String productId = 'product-1',
  String originalLineId = 'source-line-1',
  int quantityMicros = 1000000,
  String reasonCode = 'DAMAGED',
  String conditionCode = 'OPENED',
}) => ReturnExchangeLineInput(
  kind: ReturnExchangeLineKind.returnLine,
  productId: productId,
  productUnitId: 'unit-1',
  quantity: QuantityDto(quantityMicros: quantityMicros),
  originalSalesOrderLineId: originalLineId,
  reasonCode: reasonCode,
  conditionCode: conditionCode,
);

ReturnExchangeLineInput _exchangeLine({
  String productId = 'product-2',
  String? originalSalesOrderLineId,
  int quantityMicros = 1000000,
}) => ReturnExchangeLineInput(
  kind: ReturnExchangeLineKind.exchangeLine,
  productId: productId,
  productUnitId: 'unit-2',
  quantity: QuantityDto(quantityMicros: quantityMicros),
  originalSalesOrderLineId: originalSalesOrderLineId,
);

StartReturnExchangeCommand _startCommand({
  List<ReturnExchangeLineInput>? lines,
  int expectedVersion = 1,
  String salesOrderId = 'order-1',
}) => StartReturnExchangeCommand(
  tenantId: 'tenant-1',
  actorId: 'actor-1',
  salesOrderId: salesOrderId,
  entrySource: ReturnExchangeEntrySource.standard,
  lines: lines ?? <ReturnExchangeLineInput>[_returnedLine()],
  idempotencyKey: 'idem-start-1',
  payloadHash: 'hash-start-1',
  correlationId: 'corr-start-1',
  expectedVersion: expectedVersion,
);

UpdateReturnExchangeCommand _updateCommand({
  List<ReturnExchangeLineInput>? lines,
  int expectedVersion = 1,
  String returnExchangeId = 'return-1',
}) => UpdateReturnExchangeCommand(
  tenantId: 'tenant-1',
  actorId: 'actor-1',
  returnExchangeId: returnExchangeId,
  lines: lines ?? <ReturnExchangeLineInput>[_returnedLine()],
  idempotencyKey: 'idem-update-1',
  payloadHash: 'hash-update-1',
  correlationId: 'corr-update-1',
  expectedVersion: expectedVersion,
);

CancelReturnExchangeCommand _cancelCommand({
  int? expectedVersion,
  String returnExchangeId = 'return-1',
  String tenantId = 'tenant-1',
  String actorId = 'actor-1',
  String idempotencyKey = 'idem-cancel-1',
}) => CancelReturnExchangeCommand(
  tenantId: tenantId,
  actorId: actorId,
  returnExchangeId: returnExchangeId,
  idempotencyKey: idempotencyKey,
  expectedVersion: expectedVersion,
);

ReturnExchangeContext _context({
  List<String> reservationIds = const <String>['res-1'],
  String salesOrderId = 'order-1',
}) => ReturnExchangeContext(
  draft: ReturnExchangeDraftDto(
    returnExchangeId: 'return-1',
    salesOrderId: salesOrderId,
    version: 2,
    status: ReturnExchangeStatus.draft,
    lines: <ReturnExchangeLineInput>[_returnedLine()],
  ),
  currencyCode: 'VND',
  sourceOrderVersion: 7,
  sourceSettlementVersion: 3,
  reservationIds: reservationIds,
);

void main() {
  group('TH-05 Group I S28–S31 session application boundary', () {
    test('S28 authoritative precheck checks permission before read gateway', () async {
      final gateway = FakeReturnExchangeReadGateway();
      final permission = _DenyPermissionChecker();
      final handler = PrecheckReturnExchangeQueryHandler(
        permissionChecker: permission,
        returnExchangeReadGateway: gateway,
      );

      await expectLater(
        () => handler.handle(
          PrecheckReturnExchangeQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
      expect(gateway.precheckCalls, 0);
    });

    test('S28 authoritative precheck delegates to read gateway after permission', () async {
      final gateway = FakeReturnExchangeReadGateway(
        precheckResult: ReturnExchangePrecheckDto(
          allowed: true,
          sourceVersion: 9,
          blockers: const <SalesBlockerDto>[],
        ),
      );
      final handler = PrecheckReturnExchangeQueryHandler(
        permissionChecker: _AllowAllPermissionChecker(),
        returnExchangeReadGateway: gateway,
      );

      final dto = await handler.handle(
        PrecheckReturnExchangeQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
        ),
      );

      expect(dto.allowed, isTrue);
      expect(dto.sourceVersion, 9);
      expect(gateway.precheckCalls, 1);
    });

    test('S28 get-returnable checks view permission before read gateway', () async {
      final gateway = FakeReturnExchangeReadGateway();
      final handler = GetReturnableOrderLinesQueryHandler(
        permissionChecker: _DenyPermissionChecker(),
        returnExchangeReadGateway: gateway,
      );

      await expectLater(
        () => handler.handle(
          GetReturnableOrderLinesQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
      expect(gateway.getReturnableCalls, 0);
    });

    test('S28 get-returnable delegates to read gateway after permission', () async {
      final gateway = FakeReturnExchangeReadGateway(
        returnableResult: ReturnableOrderLinesDto(
          salesOrderId: 'order-1',
          sourceVersion: 4,
          lines: const <ReturnableOrderLineDto>[],
        ),
      );
      final handler = GetReturnableOrderLinesQueryHandler(
        permissionChecker: _AllowAllPermissionChecker(),
        returnExchangeReadGateway: gateway,
      );

      final dto = await handler.handle(
        GetReturnableOrderLinesQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
        ),
      );

      expect(dto.sourceVersion, 4);
      expect(gateway.getReturnableCalls, 1);
    });

    test('S29 update rejects non-positive expected version before providers', () async {
      final validator = UpdateReturnExchangeCommandValidator();
      await expectLater(
        () => validator.validate(_updateCommand(expectedVersion: 0)),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'CONTEXT_INVALID',
          ),
        ),
      );
    });

    test('S29 start rejects blank sales order and non-positive line quantity', () async {
      final validator = StartReturnExchangeCommandValidator();
      await expectLater(
        () => validator.validate(_startCommand(salesOrderId: ' ')),
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
          _startCommand(
            lines: <ReturnExchangeLineInput>[
              _returnedLine(quantityMicros: 0),
            ],
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
    });

    test(
      'S29 returned product may appear only with a valid original line id',
      () async {
        final validator = StartReturnExchangeCommandValidator();
        await expectLater(
          () => validator.validate(
            _startCommand(
              lines: <ReturnExchangeLineInput>[
                ReturnExchangeLineInput(
                  kind: ReturnExchangeLineKind.returnLine,
                  productId: 'product-1',
                  productUnitId: 'unit-1',
                  quantity: const QuantityDto(quantityMicros: 1000000),
                  reasonCode: 'DAMAGED',
                  conditionCode: 'OPENED',
                ),
              ],
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
          validator.validate(
            _startCommand(
              lines: <ReturnExchangeLineInput>[
                _returnedLine(originalLineId: 'line-a'),
                _returnedLine(originalLineId: 'line-b'),
              ],
            ),
          ),
          completes,
        );
      },
    );

    test('S29 exchange lines require null originalSalesOrderLineId', () async {
      final validator = UpdateReturnExchangeCommandValidator();
      await expectLater(
        () => validator.validate(
          _updateCommand(
            lines: <ReturnExchangeLineInput>[
              _returnedLine(),
              _exchangeLine(originalSalesOrderLineId: 'source-line-1'),
            ],
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
    });

    test('S29 returned line permits omitted temporary reason and condition', () async {
      const lines = [
        ReturnExchangeLineInput(
          kind: ReturnExchangeLineKind.returnLine,
          productId: 'product-1',
          productUnitId: 'unit-1',
          quantity: QuantityDto(quantityMicros: QuantityDto.scale),
          originalSalesOrderLineId: 'line-1',
        ),
      ];

      await expectLater(
        StartReturnExchangeCommandValidator().validate(
          _startCommand(lines: lines),
        ),
        completes,
      );
      await expectLater(
        UpdateReturnExchangeCommandValidator().validate(
          _updateCommand(lines: lines),
        ),
        completes,
      );
    });

    test('S29 exchange line rejects non-null reason or condition', () async {
      final validator = UpdateReturnExchangeCommandValidator();
      await expectLater(
        () => validator.validate(
          _updateCommand(
            lines: <ReturnExchangeLineInput>[
              ReturnExchangeLineInput(
                kind: ReturnExchangeLineKind.exchangeLine,
                productId: 'product-2',
                productUnitId: 'unit-2',
                quantity: const QuantityDto(quantityMicros: QuantityDto.scale),
                reasonCode: 'DAMAGED',
              ),
            ],
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
    });

    test('S29 start carries typed entrySource', () async {
      expect(
        _startCommand().entrySource,
        ReturnExchangeEntrySource.standard,
      );
      expect(
        StartReturnExchangeCommand(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
          entrySource: ReturnExchangeEntrySource.fullReturnFromCancelAttempt,
          lines: <ReturnExchangeLineInput>[_returnedLine()],
          idempotencyKey: 'idem-start-1',
          payloadHash: 'hash-start-1',
          correlationId: 'corr-start-1',
          expectedVersion: 1,
        ).entrySource,
        ReturnExchangeEntrySource.fullReturnFromCancelAttempt,
      );
    });

    test('S29 form-policy query checks create permission before gateway', () async {
      final gateway = FakeReturnExchangeReadGateway(
        formPolicyResult: ReturnExchangeFormPolicyDto(
          reasons: const <ReturnExchangePolicyOptionDto>[],
          conditions: const <ReturnExchangePolicyOptionDto>[],
        ),
      );
      final handler = GetReturnExchangeFormPolicyQueryHandler(
        permissionChecker: _DenyPermissionChecker(),
        returnExchangeReadGateway: gateway,
      );

      await expectLater(
        () => handler.handle(
          GetReturnExchangeFormPolicyQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
      expect(gateway.getFormPolicyCalls, 0);
    });

    test('S29 form-policy fake never invents fallback DTOs', () async {
      final gateway = FakeReturnExchangeReadGateway();
      await expectLater(
        () => gateway.getFormPolicy(
          GetReturnExchangeFormPolicyQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
          ),
        ),
        throwsA(isA<StateError>()),
      );
      expect(gateway.getFormPolicyCalls, 1);
    });

    test('S29 start delegates ready reference decision to command gateway', () async {
      final reads = FakeReturnExchangeReadGateway();
      final commands = FakeReturnExchangeCommandGateway();
      final references = FakeReturnExchangeReferencePort.ready(
        reservationIds: const <String>['res-start'],
      );
      final handler = StartReturnExchangeCommandHandler(
        commandGateway: commands,
        referencePort: references,
      );

      final draft = await handler.handle(_startCommand());

      expect(references.evaluateCalls, 1);
      expect(references.lastReserveExchangeStock, isFalse);
      expect(commands.startCalls, 1);
      expect(commands.lastStartDecision?.allowed, isTrue);
      expect(commands.lastStartDecision?.reservationIds, <String>['res-start']);
      expect(draft.returnExchangeId, isNotEmpty);
      expect(reads.getContextCalls, 0);
    });

    test('S29 update loads context then delegates ready decision', () async {
      final reads = FakeReturnExchangeReadGateway(contextResult: _context());
      final commands = FakeReturnExchangeCommandGateway();
      final references = FakeReturnExchangeReferencePort.ready();
      final handler = UpdateReturnExchangeCommandHandler(
        readGateway: reads,
        commandGateway: commands,
        referencePort: references,
      );

      await handler.handle(_updateCommand());

      expect(reads.getContextCalls, 1);
      expect(references.evaluateCalls, 1);
      expect(references.lastSalesOrderId, 'order-1');
      expect(references.lastReserveExchangeStock, isFalse);
      expect(commands.updateCalls, 1);
      expect(commands.lastUpdateDecision?.allowed, isTrue);
    });

    test('S29 reference blocker prevents command gateway calls', () async {
      final reads = FakeReturnExchangeReadGateway(contextResult: _context());
      final commands = FakeReturnExchangeCommandGateway();
      final references = FakeReturnExchangeReferencePort.blocked(
        code: 'DEPENDENCY_UNAVAILABLE',
      );
      final startHandler = StartReturnExchangeCommandHandler(
        commandGateway: commands,
        referencePort: references,
      );
      final updateHandler = UpdateReturnExchangeCommandHandler(
        readGateway: reads,
        commandGateway: commands,
        referencePort: references,
      );

      await expectLater(
        () => startHandler.handle(_startCommand()),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'RETURN_EXCHANGE_BLOCKED',
          ),
        ),
      );
      await expectLater(
        () => updateHandler.handle(_updateCommand()),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'RETURN_EXCHANGE_BLOCKED',
          ),
        ),
      );
      expect(commands.startCalls, 0);
      expect(commands.updateCalls, 0);
    });

    test(
      'S30 inventory/catalog unavailable maps to RETURN_EXCHANGE_BLOCKED before update gateway',
      () async {
        final reads = FakeReturnExchangeReadGateway(contextResult: _context());
        final commands = FakeReturnExchangeCommandGateway();
        final references = FakeReturnExchangeReferencePort.blocked(
          code: 'INVENTORY_UNAVAILABLE',
        );
        final handler = UpdateReturnExchangeCommandHandler(
          readGateway: reads,
          commandGateway: commands,
          referencePort: references,
        );

        await expectLater(
          () => handler.handle(_updateCommand()),
          throwsA(
            isA<SalesContractException>().having(
              (error) => error.code,
              'code',
              'RETURN_EXCHANGE_BLOCKED',
            ),
          ),
        );
        expect(references.evaluateCalls, 1);
        expect(references.lastReserveExchangeStock, isFalse);
        expect(commands.updateCalls, 0);
      },
    );

    test(
      'S31 cancel allows nullable expectedVersion but requires tenant/actor/id/key',
      () async {
        final validator = CancelReturnExchangeCommandValidator();
        await expectLater(
          validator.validate(_cancelCommand(expectedVersion: null)),
          completes,
        );
        await expectLater(
          () => validator.validate(_cancelCommand(expectedVersion: 0)),
          throwsA(
            isA<SalesContractException>().having(
              (error) => error.code,
              'code',
              'CONTEXT_INVALID',
            ),
          ),
        );
        await expectLater(
          () => validator.validate(_cancelCommand(tenantId: ' ')),
          throwsA(
            isA<SalesContractException>().having(
              (error) => error.code,
              'code',
              'CONTEXT_INVALID',
            ),
          ),
        );
        await expectLater(
          () => validator.validate(_cancelCommand(actorId: '')),
          throwsA(
            isA<SalesContractException>().having(
              (error) => error.code,
              'code',
              'CONTEXT_INVALID',
            ),
          ),
        );
        await expectLater(
          () => validator.validate(_cancelCommand(returnExchangeId: ' ')),
          throwsA(
            isA<SalesContractException>().having(
              (error) => error.code,
              'code',
              'CONTEXT_INVALID',
            ),
          ),
        );
        await expectLater(
          () => validator.validate(_cancelCommand(idempotencyKey: '')),
          throwsA(
            isA<SalesContractException>().having(
              (error) => error.code,
              'code',
              'CONTEXT_INVALID',
            ),
          ),
        );
      },
    );

    test('S31 cancel delegates without reservation dependency', () async {
      final commands = FakeReturnExchangeCommandGateway();
      final handler = CancelReturnExchangeCommandHandler(commandGateway: commands);
      final result = await handler.handle(_cancelCommand());
      expect(commands.cancelCalls, 1);
      expect(result.status, ReturnExchangeStatus.cancelled);
    });
  });
}
