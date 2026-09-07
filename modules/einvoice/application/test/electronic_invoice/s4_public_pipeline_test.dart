import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

import 's4_test_support.dart';

void main() {
  group('S4 public pipeline guards', () {
    test('blank tenant rejects before gateway call', () async {
      final gateway = RecordingElectronicInvoiceCommandGateway();
      final handler = RequestOfficialInvoiceViewCommandHandler(gateway: gateway);
      final validator = RequestOfficialInvoiceViewCommandValidator();
      final decorator =
          ValidationCommandHandlerDecorator<
            RequestOfficialInvoiceViewCommand,
            OfficialInvoiceViewDto
          >(
            validator: validator,
            inner: handler.handle,
          );

      await expectLater(
        decorator.handle(
          RequestOfficialInvoiceViewCommand(
            tenantId: ' ',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(gateway.officialViewRequests, isEmpty);
    });

    test('blank idempotency key rejects before gateway call', () async {
      final gateway = RecordingElectronicInvoiceCommandGateway();
      final handler = RequestInvoiceDocumentCommandHandler(gateway: gateway);
      final validator = RequestInvoiceDocumentCommandValidator();
      final decorator =
          ValidationCommandHandlerDecorator<
            RequestInvoiceDocumentCommand,
            InvoiceDocumentRetrievalDto
          >(
            validator: validator,
            inner: handler.handle,
          );

      await expectLater(
        decorator.handle(
          RequestInvoiceDocumentCommand(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
            documentType: InvoiceDocumentType.pdf,
            idempotencyKey: ' ',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(gateway.documentRequests, isEmpty);
    });

    test('missing permission rejects before gateway call', () async {
      final gateway = RecordingElectronicInvoiceCommandGateway();
      final handler = RequestOfficialInvoiceViewCommandHandler(gateway: gateway);
      final checker = FakePermissionChecker(deny: {EInvoicePermissions.view});
      final decorator =
          AuthorizationCommandHandlerDecorator<
            RequestOfficialInvoiceViewCommand,
            OfficialInvoiceViewDto
          >(
            permissionChecker: checker,
            permissionCode: EInvoicePermissions.view,
            inner: handler.handle,
          );

      await expectLater(
        decorator.handleCommand(
          RequestOfficialInvoiceViewCommand(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
          ),
        ),
        throwsA(isA<ApplicationException>()),
      );
      expect(gateway.officialViewRequests, isEmpty);
      expect(checker.required, [EInvoicePermissions.view]);
    });
  });
}
