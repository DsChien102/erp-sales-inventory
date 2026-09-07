import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  group('StartAutoDeliveryCommandValidator', () {
    final validator = StartAutoDeliveryCommandValidator();
    const validKey = 'a6547397-1158-5873-a825-9ee320d9fcc5';

    test('accepts valid command', () async {
      final command = StartAutoDeliveryCommand(
        tenantId: 'tenant-1',
        electronicInvoiceId: 'ei-1',
        triggerId: 'event-1',
        idempotencyKey: validKey,
      );

      expect(() => validator.validate(command), returnsNormally);
    });

    test('rejects empty tenantId', () async {
      final command = StartAutoDeliveryCommand(
        tenantId: '   ',
        electronicInvoiceId: 'ei-1',
        triggerId: 'event-1',
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

    test('rejects empty electronicInvoiceId', () async {
      final command = StartAutoDeliveryCommand(
        tenantId: 'tenant-1',
        electronicInvoiceId: '',
        triggerId: 'event-1',
        idempotencyKey: validKey,
      );

      expect(
        () => validator.validate(command),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('electronicInvoiceId'),
          ),
        ),
      );
    });

    test('rejects empty triggerId', () async {
      final command = StartAutoDeliveryCommand(
        tenantId: 'tenant-1',
        electronicInvoiceId: 'ei-1',
        triggerId: ' ',
        idempotencyKey: validKey,
      );

      expect(
        () => validator.validate(command),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('triggerId'),
          ),
        ),
      );
    });

    test('rejects non-UUID idempotencyKey', () async {
      final command = StartAutoDeliveryCommand(
        tenantId: 'tenant-1',
        electronicInvoiceId: 'ei-1',
        triggerId: 'event-1',
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

  group('StartAutoDeliveryCommandHandler', () {
    const validKey = 'a6547397-1158-5873-a825-9ee320d9fcc5';
    final validCommand = StartAutoDeliveryCommand(
      tenantId: 'tenant-1',
      electronicInvoiceId: 'ei-1',
      triggerId: 'event-1',
      idempotencyKey: validKey,
    );

    test('forwards stable auto identity to gateway', () async {
      final gateway = FakeDeliveryCommandGateway.started(deliveryId: 'del-1');
      final handler = StartAutoDeliveryCommandHandler(gateway: gateway);

      final result = await handler.handle(validCommand);

      expect(result.disposition, AutoDeliveryDisposition.started);
      expect(result.deliveryId, 'del-1');
      expect(gateway.lastStartAuto, isNotNull);
      expect(gateway.lastStartAuto!.tenantId, 'tenant-1');
      expect(gateway.lastStartAuto!.electronicInvoiceId, 'ei-1');
      expect(gateway.lastStartAuto!.triggerId, 'event-1');
      expect(gateway.lastStartAuto!.idempotencyKey, validKey);
    });

    test('preserves caller idempotency key without regenerating', () async {
      final gateway = FakeDeliveryCommandGateway.started();
      final handler = StartAutoDeliveryCommandHandler(gateway: gateway);

      await handler.handle(validCommand);

      expect(gateway.lastStartAuto!.idempotencyKey, validKey);
    });

    test('policy-off is a successful skip, not an exception', () async {
      final gateway = FakeDeliveryCommandGateway.skipped(
        AutoDeliverySkipReason.policyOff,
      );
      final handler = StartAutoDeliveryCommandHandler(gateway: gateway);

      final result = await handler.handle(validCommand);

      expect(result.disposition, AutoDeliveryDisposition.skipped);
      expect(result.skipReason, AutoDeliverySkipReason.policyOff);
      expect(result.deliveryId, isNull);
    });
  });

  group('AutoDeliveryIdempotencyKey', () {
    test('uses frozen namespace and pipe-separated seed', () {
      final key = AutoDeliveryIdempotencyKey.generate(
        tenantId: 'tenant-1',
        electronicInvoiceId: 'ei-1',
      );

      expect(
        key,
        AutoDeliveryIdempotencyKey.generate(
          tenantId: 'tenant-1',
          electronicInvoiceId: 'ei-1',
        ),
      );
      expect(
        key,
        isNot(
          equals(
            AutoDeliveryIdempotencyKey.generate(
              tenantId: 'tenant-1',
              electronicInvoiceId: 'ei-2',
            ),
          ),
        ),
      );
      expect(AutoDeliveryIdempotencyKey.namespace, '9d4c1d80-8d2c-5f2a-8b86-ff34c8a8e275');
    });
  });
}
