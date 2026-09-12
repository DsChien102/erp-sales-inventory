import 'dart:io';

import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_application/testing.dart';
import 'package:vet45_sales_domain/domain.dart';

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

ReturnExchangeContext _context({
  String salesOrderId = 'order-1',
  List<ReturnExchangeLineInput>? lines,
  List<String> reservationIds = const <String>['res-1'],
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
  reservationIds: reservationIds,
);

ConfirmReturnExchangeCommand _confirmCommand({
  String tenantId = 'tenant-1',
  String actorId = 'actor-1',
  String returnExchangeId = 'return-1',
  String idempotencyKey = 'idem-confirm-1',
  String payloadHash = 'hash-confirm-1',
  String correlationId = 'corr-confirm-1',
  int expectedVersion = 3,
}) => ConfirmReturnExchangeCommand(
  tenantId: tenantId,
  actorId: actorId,
  returnExchangeId: returnExchangeId,
  idempotencyKey: idempotencyKey,
  payloadHash: payloadHash,
  correlationId: correlationId,
  expectedVersion: expectedVersion,
);

CompleteReturnExchangeCommand _completeCommand({
  String tenantId = 'tenant-1',
  String actorId = 'actor-1',
  String returnExchangeId = 'return-1',
  String idempotencyKey = 'idem-complete-1',
  String payloadHash = 'hash-complete-1',
  String correlationId = 'corr-complete-1',
  int expectedVersion = 4,
}) => CompleteReturnExchangeCommand(
  tenantId: tenantId,
  actorId: actorId,
  returnExchangeId: returnExchangeId,
  idempotencyKey: idempotencyKey,
  payloadHash: payloadHash,
  correlationId: correlationId,
  expectedVersion: expectedVersion,
);

void main() {
  group('TH-05 Group I S34 confirmation application boundary', () {
    test('S34 confirm/complete declare command pipeline permission metadata', () {
      final packageRoot = _findApplicationPackageRoot();
      final confirmSource = File(
        '${packageRoot.path}/lib/src/return_exchange_order/commands/'
        'confirm_return_exchange/confirm_return_exchange_command.dart',
      ).readAsStringSync();
      final completeSource = File(
        '${packageRoot.path}/lib/src/return_exchange_order/commands/'
        'complete_return_exchange/complete_return_exchange_command.dart',
      ).readAsStringSync();

      expect(
        confirmSource,
        contains('@RequiresPermission(SalesPermissions.confirmReturnExchange)'),
      );
      expect(confirmSource, contains('@RequiresTenant()'));
      expect(
        completeSource,
        contains('@RequiresPermission(SalesPermissions.completeReturnExchange)'),
      );
      expect(completeSource, contains('@RequiresTenant()'));
      expect(
        SalesPermissions.confirmReturnExchange,
        'sales.return_exchange.confirm',
      );
      expect(
        SalesPermissions.completeReturnExchange,
        'sales.return_exchange.complete',
      );
    });

    test('S34 confirm validator rejects blank context and non-positive version', () async {
      final validator = ConfirmReturnExchangeCommandValidator();

      await expectLater(
        () => validator.validate(_confirmCommand(tenantId: ' ')),
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
        () => validator.validate(_confirmCommand(returnExchangeId: ' ')),
        throwsA(isA<SalesContractException>()),
      );
      await expectLater(
        () => validator.validate(_confirmCommand(idempotencyKey: '')),
        throwsA(isA<SalesContractException>()),
      );
      await expectLater(
        () => validator.validate(_confirmCommand(payloadHash: ' ')),
        throwsA(isA<SalesContractException>()),
      );
      await expectLater(
        () => validator.validate(_confirmCommand(correlationId: '')),
        throwsA(isA<SalesContractException>()),
      );
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
    });

    test('S34 complete validator rejects blank context and non-positive version', () async {
      final validator = CompleteReturnExchangeCommandValidator();

      await expectLater(
        () => validator.validate(_completeCommand(tenantId: '')),
        throwsA(isA<SalesContractException>()),
      );
      await expectLater(
        () => validator.validate(_completeCommand(actorId: ' ')),
        throwsA(isA<SalesContractException>()),
      );
      await expectLater(
        () => validator.validate(_completeCommand(returnExchangeId: '')),
        throwsA(isA<SalesContractException>()),
      );
      await expectLater(
        () => validator.validate(_completeCommand(idempotencyKey: ' ')),
        throwsA(isA<SalesContractException>()),
      );
      await expectLater(
        () => validator.validate(_completeCommand(payloadHash: '')),
        throwsA(isA<SalesContractException>()),
      );
      await expectLater(
        () => validator.validate(_completeCommand(correlationId: ' ')),
        throwsA(isA<SalesContractException>()),
      );
      await expectLater(
        () => validator.validate(_completeCommand(expectedVersion: -1)),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'CONTEXT_INVALID',
          ),
        ),
      );
    });

    test('S34 confirm revalidates providers before command gateway', () async {
      final commands = FakeReturnExchangeCommandGateway();
      final reads = FakeReturnExchangeReadGateway(contextResult: _context());
      final references = FakeReturnExchangeReferencePort.ready();
      final handler = ConfirmReturnExchangeCommandHandler(
        readGateway: reads,
        referencePort: references,
        commandGateway: commands,
      );

      await handler.handle(_confirmCommand());
      expect(reads.getContextCalls, 1);
      expect(reads.lastContextReturnExchangeId, 'return-1');
      expect(references.evaluateCalls, 1);
      expect(references.lastSalesOrderId, 'order-1');
      expect(references.lastReserveExchangeStock, isFalse);
      expect(references.lastLines, isNotEmpty);
      expect(commands.confirmCalls, 1);
      expect(commands.lastConfirmDecision?.allowed, isTrue);
    });

    test('S34 provider blocker suppresses confirm gateway call', () async {
      final commands = FakeReturnExchangeCommandGateway();
      final reads = FakeReturnExchangeReadGateway(contextResult: _context());
      final references = FakeReturnExchangeReferencePort.blocked(
        code: 'DEPENDENCY_UNAVAILABLE',
      );
      final handler = ConfirmReturnExchangeCommandHandler(
        readGateway: reads,
        referencePort: references,
        commandGateway: commands,
      );

      await expectLater(
        () => handler.handle(_confirmCommand()),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'RETURN_EXCHANGE_BLOCKED',
          ),
        ),
      );
      expect(reads.getContextCalls, 1);
      expect(references.evaluateCalls, 1);
      expect(references.lastReserveExchangeStock, isFalse);
      expect(commands.confirmCalls, 0);
    });

    test('S34 confirm delegates exact ready decision and returns gateway result', () async {
      final committed = ReturnExchangeResultDto(
        returnExchangeId: 'return-1',
        salesOrderId: 'order-1',
        version: 4,
        status: ReturnExchangeStatus.confirmed,
      );
      final commands = FakeReturnExchangeCommandGateway(confirmResult: committed);
      final reads = FakeReturnExchangeReadGateway(
        contextResult: _context(salesOrderId: 'order-99'),
      );
      final references = FakeReturnExchangeReferencePort.ready(
        reservationIds: const <String>['res-confirm'],
      );
      final handler = ConfirmReturnExchangeCommandHandler(
        readGateway: reads,
        referencePort: references,
        commandGateway: commands,
      );

      final result = await handler.handle(_confirmCommand());

      expect(result, same(committed));
      expect(commands.lastConfirmCommand?.returnExchangeId, 'return-1');
      expect(commands.lastConfirmDecision?.reservationIds, <String>['res-confirm']);
      expect(references.lastSalesOrderId, 'order-99');
    });

    test('S34 confirm same-result replay returns identical gateway DTO', () async {
      final committed = ReturnExchangeResultDto(
        returnExchangeId: 'return-1',
        salesOrderId: 'order-1',
        version: 4,
        status: ReturnExchangeStatus.processing,
      );
      final commands = FakeReturnExchangeCommandGateway(confirmResult: committed);
      final reads = FakeReturnExchangeReadGateway(contextResult: _context());
      final references = FakeReturnExchangeReferencePort.ready();
      final handler = ConfirmReturnExchangeCommandHandler(
        readGateway: reads,
        referencePort: references,
        commandGateway: commands,
      );

      final first = await handler.handle(_confirmCommand());
      final second = await handler.handle(_confirmCommand());

      expect(first, same(committed));
      expect(second, same(committed));
      expect(commands.confirmCalls, 2);
      expect(references.evaluateCalls, 2);
    });

    test('S34 confirm passes gateway exceptions through unchanged', () async {
      final commands = FakeReturnExchangeCommandGateway(
        error: const SalesContractException('STALE_VERSION'),
      );
      final reads = FakeReturnExchangeReadGateway(contextResult: _context());
      final references = FakeReturnExchangeReferencePort.ready();
      final handler = ConfirmReturnExchangeCommandHandler(
        readGateway: reads,
        referencePort: references,
        commandGateway: commands,
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
      expect(commands.confirmCalls, 1);
    });

    test('S34 complete delegates once without provider revalidation', () async {
      final committed = ReturnExchangeResultDto(
        returnExchangeId: 'return-1',
        salesOrderId: 'order-1',
        version: 5,
        status: ReturnExchangeStatus.completed,
      );
      final commands = FakeReturnExchangeCommandGateway(completeResult: committed);
      final reads = FakeReturnExchangeReadGateway(contextResult: _context());
      final references = FakeReturnExchangeReferencePort.ready();
      final handler = CompleteReturnExchangeCommandHandler(
        commandGateway: commands,
      );

      final result = await handler.handle(_completeCommand());

      expect(result, same(committed));
      expect(commands.completeCalls, 1);
      expect(commands.lastCompleteCommand?.returnExchangeId, 'return-1');
      expect(reads.getContextCalls, 0);
      expect(references.evaluateCalls, 0);
    });

    test('S34 complete passes gateway exceptions through unchanged', () async {
      final commands = FakeReturnExchangeCommandGateway(
        error: const SalesContractException('IMPACT_PENDING'),
      );
      final handler = CompleteReturnExchangeCommandHandler(
        commandGateway: commands,
      );

      await expectLater(
        () => handler.handle(_completeCommand()),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'IMPACT_PENDING',
          ),
        ),
      );
      expect(commands.completeCalls, 1);
    });
  });
}

Directory _findApplicationPackageRoot() {
  final starts = <Directory>[
    Directory.current.absolute,
    Directory('${Directory.current.path}/modules/sales/application').absolute,
  ];
  for (final start in starts) {
    var directory = start;
    while (directory.parent.path != directory.path) {
      final pubspec = File('${directory.path}/pubspec.yaml');
      if (pubspec.existsSync() &&
          pubspec.readAsStringSync().contains('name: vet45_sales_application')) {
        return directory;
      }
      directory = directory.parent;
    }
  }
  throw StateError('Unable to locate vet45_sales_application package root');
}
