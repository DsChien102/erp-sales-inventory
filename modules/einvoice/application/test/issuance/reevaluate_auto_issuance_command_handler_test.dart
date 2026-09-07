import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_application/application.dart';

final class _FakeAutoIssuanceGateway implements IAutoIssuanceGateway {
  _FakeAutoIssuanceGateway({
    this.reevaluateResult,
  });

  final AutoIssuanceResultDto? reevaluateResult;
  AutoIssuanceReevaluationRequest? lastReevaluateRequest;

  @override
  Future<AutoIssuanceResultDto> start(AutoIssuanceStartRequest request) async {
    throw UnimplementedError();
  }

  @override
  Future<AutoIssuanceResultDto> reevaluate(
    AutoIssuanceReevaluationRequest request,
  ) async {
    lastReevaluateRequest = request;
    return reevaluateResult ??
        const AutoIssuanceResultDto(
          started: true,
          skipped: false,
          processId: 'proc-1',
          attemptId: 'att-1',
          status: 'ATTEMPT_STARTED',
        );
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
  group('ReevaluateAutoIssuanceCommandValidator', () {
    final validator = ReevaluateAutoIssuanceCommandValidator();

    test('accepts valid command', () async {
      final command = ReevaluateAutoIssuanceCommand(
        tenantId: 'tenant-1',
        processId: 'proc-1',
        sourceEventId: 'evt-100',
      );

      expect(() => validator.validate(command), returnsNormally);
    });

    test('rejects empty tenantId', () async {
      final command = ReevaluateAutoIssuanceCommand(
        tenantId: '  ',
        processId: 'proc-1',
        sourceEventId: 'evt-100',
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

    test('rejects empty processId', () async {
      final command = ReevaluateAutoIssuanceCommand(
        tenantId: 'tenant-1',
        processId: '',
        sourceEventId: 'evt-100',
      );

      expect(
        () => validator.validate(command),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('processId'),
          ),
        ),
      );
    });

    test('rejects empty sourceEventId', () async {
      final command = ReevaluateAutoIssuanceCommand(
        tenantId: 'tenant-1',
        processId: 'proc-1',
        sourceEventId: '   ',
      );

      expect(
        () => validator.validate(command),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('sourceEventId'),
          ),
        ),
      );
    });
  });

  group('ReevaluateAutoIssuanceCommandHandler', () {
    final validCommand = ReevaluateAutoIssuanceCommand(
      tenantId: 'tenant-1',
      processId: 'proc-1',
      sourceEventId: 'evt-100',
    );

    test('forwards tenantId, processId, sourceEventId to gateway reevaluate', () async {
      final gateway = _FakeAutoIssuanceGateway();
      final handler = ReevaluateAutoIssuanceCommandHandler(gateway: gateway);

      final result = await handler.handle(validCommand);

      expect(result.started, isTrue);
      expect(gateway.lastReevaluateRequest, isNotNull);
      expect(gateway.lastReevaluateRequest!.tenantId, 'tenant-1');
      expect(gateway.lastReevaluateRequest!.processId, 'proc-1');
      expect(gateway.lastReevaluateRequest!.sourceEventId, 'evt-100');
    });

    test('returns skipped when process is still blocked or unchanged', () async {
      final gateway = _FakeAutoIssuanceGateway(
        reevaluateResult: const AutoIssuanceResultDto(
          started: false,
          skipped: true,
          processId: 'proc-1',
          status: 'PENDING_REEVALUATION',
          reason: 'STILL_BLOCKED',
        ),
      );
      final handler = ReevaluateAutoIssuanceCommandHandler(gateway: gateway);

      final result = await handler.handle(validCommand);

      expect(result.started, isFalse);
      expect(result.skipped, isTrue);
      expect(result.processId, 'proc-1');
      expect(result.status, 'PENDING_REEVALUATION');
      expect(result.reason, 'STILL_BLOCKED');
    });
  });
}
