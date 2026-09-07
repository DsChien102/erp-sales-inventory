import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  group('SendElectronicInvoiceCommandValidator', () {
    final validator = SendElectronicInvoiceCommandValidator();
    const validKey = 'a6547397-1158-5873-a825-9ee320d9fcc5';

    test('accepts valid command', () async {
      final command = SendElectronicInvoiceCommand(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: 'so-1',
        recipientEmail: 'buyer@test.com',
        idempotencyKey: validKey,
      );

      expect(() => validator.validate(command), returnsNormally);
    });

    test('rejects empty recipientEmail', () async {
      final command = SendElectronicInvoiceCommand(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: 'so-1',
        recipientEmail: '  ',
        idempotencyKey: validKey,
      );

      expect(
        () => validator.validate(command),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-UUID idempotencyKey', () async {
      final command = SendElectronicInvoiceCommand(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: 'so-1',
        recipientEmail: 'buyer@test.com',
        idempotencyKey: 'bad',
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

  group('SendElectronicInvoiceCommandHandler', () {
    const validKey = 'a6547397-1158-5873-a825-9ee320d9fcc5';

    test('forwards manual start args without deliveryKind', () async {
      final gateway = FakeDeliveryCommandGateway.manualStarted(
        deliveryId: 'del-9',
      );
      final handler = SendElectronicInvoiceCommandHandler(gateway: gateway);

      final result = await handler.handle(
        SendElectronicInvoiceCommand(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'so-1',
          recipientEmail: 'buyer@test.com',
          idempotencyKey: validKey,
        ),
      );

      expect(result.deliveryId, 'del-9');
      expect(result.status, DeliveryStatus.processing);
      expect(gateway.lastStartManual, isNotNull);
      expect(gateway.lastStartManual!.tenantId, 'tenant-1');
      expect(gateway.lastStartManual!.actorId, 'actor-1');
      expect(gateway.lastStartManual!.salesOrderId, 'so-1');
      expect(gateway.lastStartManual!.recipientEmail, 'buyer@test.com');
      expect(gateway.lastStartManual!.idempotencyKey, validKey);
    });
  });
}
