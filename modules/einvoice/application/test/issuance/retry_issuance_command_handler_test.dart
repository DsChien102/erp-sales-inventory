import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  group('RetryIssuanceCommandHandler', () {
    const validKey = '692c44cb-03a4-456b-a8a8-c5973f4e93db';

    test('scn_e02_u05_fr04_01 sends retry source version and actor', () async {
      final gateway = FakeIssuanceCommandGateway.retryPreparing();
      final result = await RetryIssuanceCommandHandler(gateway: gateway).handle(
        RetryIssuanceCommand(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
          expectedOrderVersion: 18,
          idempotencyKey: validKey,
        ),
      );

      expect(result.status, IssuanceAttemptStatus.preparing);
      expect(result.issuanceId, 'iss-1');
      expect(result.attemptId, 'att-1');
      expect(gateway.lastRetry, isNotNull);
      expect(gateway.lastRetry!.tenantId, 'tenant-1');
      expect(gateway.lastRetry!.actorId, 'actor-1');
      expect(gateway.lastRetry!.salesOrderId, 'order-1');
      expect(gateway.lastRetry!.expectedOrderVersion, 18);
      expect(gateway.lastRetry!.idempotencyKey, validKey);
      expect(gateway.lastRetry!.acknowledgeWarnings, isFalse);
    });

    test('forwards acknowledgeWarnings when explicitly true', () async {
      final gateway = FakeIssuanceCommandGateway.retryPreparing();
      await RetryIssuanceCommandHandler(gateway: gateway).handle(
        RetryIssuanceCommand(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
          expectedOrderVersion: 18,
          idempotencyKey: validKey,
          acknowledgeWarnings: true,
        ),
      );

      expect(gateway.lastRetry!.acknowledgeWarnings, isTrue);
    });
  });

  group('RetryIssuanceCommandValidator', () {
    final validator = RetryIssuanceCommandValidator();
    const validKey = '692c44cb-03a4-456b-a8a8-c5973f4e93db';

    test('accepts valid command', () async {
      final command = RetryIssuanceCommand(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: 'order-1',
        expectedOrderVersion: 18,
        idempotencyKey: validKey,
      );

      expect(() => validator.validate(command), returnsNormally);
    });

    test('rejects blank tenantId', () async {
      final command = RetryIssuanceCommand(
        tenantId: '   ',
        actorId: 'actor-1',
        salesOrderId: 'order-1',
        expectedOrderVersion: 18,
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

    test('rejects blank actorId', () async {
      final command = RetryIssuanceCommand(
        tenantId: 'tenant-1',
        actorId: '   ',
        salesOrderId: 'order-1',
        expectedOrderVersion: 18,
        idempotencyKey: validKey,
      );

      expect(
        () => validator.validate(command),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('actorId'),
          ),
        ),
      );
    });

    test('rejects blank salesOrderId', () async {
      final command = RetryIssuanceCommand(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: '   ',
        expectedOrderVersion: 18,
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

    test('rejects expectedOrderVersion <= 0', () async {
      for (final invalidVersion in [0, -1, -99]) {
        final command = RetryIssuanceCommand(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
          expectedOrderVersion: invalidVersion,
          idempotencyKey: validKey,
        );

        expect(
          () => validator.validate(command),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              contains('expectedOrderVersion'),
            ),
          ),
        );
      }
    });

    test('rejects non-UUID idempotencyKey', () async {
      final command = RetryIssuanceCommand(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: 'order-1',
        expectedOrderVersion: 18,
        idempotencyKey: 'not-a-uuid',
      );

      expect(
        () => validator.validate(command),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('idempotencyKey'),
          ),
        ),
      );
    });
  });
}
