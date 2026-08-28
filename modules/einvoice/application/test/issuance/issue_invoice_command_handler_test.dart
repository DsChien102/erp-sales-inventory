import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  group('IssueInvoiceCommandHandler', () {
    test('sourceVersion stays opaque', () async {
      final gateway = FakeIssuanceCommandGateway.processing();
      await IssueInvoiceCommandHandler(gateway: gateway).handle(
        IssueInvoiceCommand(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
          sourceVersion: 'etag:7f9d-opaque',
          idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
        ),
      );
      expect(gateway.lastRequest!.sourceVersion, 'etag:7f9d-opaque');
    });
  });

  group('IssueInvoiceCommandValidator', () {
    final validator = IssueInvoiceCommandValidator();

    Future<void> validate(IssueInvoiceCommand command) => validator.validate(command);

    test('rejects blank sourceVersion', () async {
      await expectLater(
        () => validate(
          IssueInvoiceCommand(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
            sourceVersion: '   ',
            idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('accepts opaque sourceVersion sales-v:abc/42', () async {
      await expectLater(
        validate(
          IssueInvoiceCommand(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
            sourceVersion: 'sales-v:abc/42',
            idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
          ),
        ),
        completes,
      );
    });

    test('rejects non-UUID idempotencyKey', () async {
      await expectLater(
        () => validate(
          IssueInvoiceCommand(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
            sourceVersion: 'sales-v:abc/42',
            idempotencyKey: 'issue-1',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('accepts canonical UUID idempotencyKey', () async {
      await expectLater(
        validate(
          IssueInvoiceCommand(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
            sourceVersion: 'sales-v:abc/42',
            idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
          ),
        ),
        completes,
      );
    });
  });
}
