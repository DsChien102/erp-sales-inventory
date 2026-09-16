import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_application/application.dart';

final class _FakeAutoIssuanceGateway implements IAutoIssuanceGateway {
  _FakeAutoIssuanceGateway._({
    this.startResult,
  });

  factory _FakeAutoIssuanceGateway.started({
    String processId = 'proc-1',
    String attemptId = 'att-1',
  }) {
    return _FakeAutoIssuanceGateway._(
      startResult: AutoIssuanceResultDto(
        started: true,
        skipped: false,
        processId: processId,
        attemptId: attemptId,
        status: 'ATTEMPT_STARTED',
      ),
    );
  }

  factory _FakeAutoIssuanceGateway.skipped(String reason) {
    return _FakeAutoIssuanceGateway._(
      startResult: AutoIssuanceResultDto(
        started: false,
        skipped: true,
        reason: reason,
        status: 'SKIPPED',
      ),
    );
  }

  final AutoIssuanceResultDto? startResult;
  AutoIssuanceStartRequest? lastStartRequest;
  AutoIssuanceReevaluationRequest? lastReevaluateRequest;

  @override
  Future<AutoIssuanceResultDto> start(AutoIssuanceStartRequest request) async {
    lastStartRequest = request;
    return startResult ?? const AutoIssuanceResultDto(started: true, skipped: false);
  }

  @override
  Future<AutoIssuanceResultDto> reevaluate(
    AutoIssuanceReevaluationRequest request,
  ) async {
    lastReevaluateRequest = request;
    return const AutoIssuanceResultDto(started: true, skipped: false);
  }

  @override
  Future<List<OpenAutoIssuanceProcessDto>> listOpenProcesses({
    required String tenantId,
    required String partnerId,
  }) async {
    return [];
  }
}

void main() {
  group('StartAutoIssuanceCommandValidator', () {
    final validator = StartAutoIssuanceCommandValidator();
    const validKey = 'a6547397-1158-5873-a825-9ee320d9fcc5';

    test('accepts valid command', () async {
      final command = StartAutoIssuanceCommand(
        tenantId: 'tenant-1',
        salesOrderId: 'order-1',
        triggerKey: 'sales_order_finalized.v1:event-1:order-1:sales-v17',
        idempotencyKey: validKey,
      );

      expect(() => validator.validate(command), returnsNormally);
    });

    test('rejects empty tenantId', () async {
      final command = StartAutoIssuanceCommand(
        tenantId: '   ',
        salesOrderId: 'order-1',
        triggerKey: 'sales_order_finalized.v1:event-1:order-1:sales-v17',
        idempotencyKey: validKey,
      );

      expect(
        () => validator.validate(command),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('tenantId'),
          ),
        ),
      );
    });

    test('rejects empty salesOrderId', () async {
      final command = StartAutoIssuanceCommand(
        tenantId: 'tenant-1',
        salesOrderId: '',
        triggerKey: 'sales_order_finalized.v1:event-1:order-1:sales-v17',
        idempotencyKey: validKey,
      );

      expect(
        () => validator.validate(command),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('salesOrderId'),
          ),
        ),
      );
    });

    test('rejects empty triggerKey', () async {
      final command = StartAutoIssuanceCommand(
        tenantId: 'tenant-1',
        salesOrderId: 'order-1',
        triggerKey: ' ',
        idempotencyKey: validKey,
      );

      expect(
        () => validator.validate(command),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('triggerKey'),
          ),
        ),
      );
    });

    test('rejects non-UUID idempotencyKey', () async {
      final command = StartAutoIssuanceCommand(
        tenantId: 'tenant-1',
        salesOrderId: 'order-1',
        triggerKey: 'sales_order_finalized.v1:event-1:order-1:sales-v17',
        idempotencyKey: 'not-a-uuid',
      );

      expect(
        () => validator.validate(command),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('UUID'),
          ),
        ),
      );
    });
  });

  group('StartAutoIssuanceCommandHandler', () {
    const validKey = 'a6547397-1158-5873-a825-9ee320d9fcc5';
    final validCommand = StartAutoIssuanceCommand(
      tenantId: 'tenant-1',
      salesOrderId: 'order-1',
      triggerKey: 'sales_order_finalized.v1:event-1:order-1:sales-v17',
      idempotencyKey: validKey,
    );

    test('scn_e02_u03_fr01_01 forwards stable trigger identity', () async {
      final gateway = _FakeAutoIssuanceGateway.started();
      final handler = StartAutoIssuanceCommandHandler(gateway: gateway);

      final result = await handler.handle(validCommand);

      expect(result.started, isTrue);
      expect(result.skipped, isFalse);
      expect(gateway.lastStartRequest, isNotNull);
      expect(gateway.lastStartRequest!.tenantId, 'tenant-1');
      expect(gateway.lastStartRequest!.salesOrderId, 'order-1');
      expect(
        gateway.lastStartRequest!.triggerKey,
        'sales_order_finalized.v1:event-1:order-1:sales-v17',
      );
      expect(gateway.lastStartRequest!.idempotencyKey, validKey);
    });

    test('policy-off is a successful skip, not an exception', () async {
      final gateway = _FakeAutoIssuanceGateway.skipped('POLICY_OFF');
      final handler = StartAutoIssuanceCommandHandler(gateway: gateway);

      final result = await handler.handle(validCommand);

      expect(result.started, isFalse);
      expect(result.skipped, isTrue);
      expect(result.reason, 'POLICY_OFF');
    });

    test('auto_issue_skipped_not_ready returns skipped with reason', () async {
      final gateway = _FakeAutoIssuanceGateway.skipped('NOT_READY');
      final handler = StartAutoIssuanceCommandHandler(gateway: gateway);

      final result = await handler.handle(validCommand);

      expect(result.started, isFalse);
      expect(result.skipped, isTrue);
      expect(result.reason, 'NOT_READY');
    });

    test('duplicate trigger replay returns skipped duplicate result', () async {
      final gateway = _FakeAutoIssuanceGateway.skipped('DUPLICATE_TRIGGER');
      final handler = StartAutoIssuanceCommandHandler(gateway: gateway);

      final result = await handler.handle(validCommand);

      expect(result.started, isFalse);
      expect(result.skipped, isTrue);
      expect(result.reason, 'DUPLICATE_TRIGGER');
    });
  });
}
