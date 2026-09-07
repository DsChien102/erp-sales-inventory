import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_domain/domain.dart';

void main() {
  group('GetSendInvoiceSheetContextQueryHandler', () {
    test('delegates to read gateway', () async {
      final gateway = FakeDeliveryReadGateway(
        sheet: const SendInvoiceSheetContextDto(
          mode: SendInvoiceSheetMode.send,
          suggestedEmail: 'buyer@test.com',
          suggestedEmailSource: DeliveryRecipientSource.currentPartnerProfile,
          history: [],
          operationLocked: false,
          displayState: DeliveryDisplayState.notSent,
        ),
      );
      final handler = GetSendInvoiceSheetContextQueryHandler(gateway: gateway);

      final result = await handler.handle(
        GetSendInvoiceSheetContextQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'so-1',
        ),
      );

      expect(result.mode, SendInvoiceSheetMode.send);
      expect(result.suggestedEmail, 'buyer@test.com');
      expect(gateway.lastSheetTenantId, 'tenant-1');
      expect(gateway.lastSheetActorId, 'actor-1');
      expect(gateway.lastSheetSalesOrderId, 'so-1');
    });
  });

  group('GetInvoiceDeliveryHistoryQueryHandler', () {
    test('delegates to read gateway', () async {
      final gateway = FakeDeliveryReadGateway(
        history: const InvoiceDeliveryHistoryDto(
          deliveries: [],
          displayState: DeliveryDisplayState.sent,
          hasSecondaryAttention: true,
        ),
      );
      final handler = GetInvoiceDeliveryHistoryQueryHandler(gateway: gateway);

      final result = await handler.handle(
        GetInvoiceDeliveryHistoryQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'so-1',
        ),
      );

      expect(result.displayState, DeliveryDisplayState.sent);
      expect(result.hasSecondaryAttention, isTrue);
      expect(gateway.lastHistoryTenantId, 'tenant-1');
      expect(gateway.lastHistoryActorId, 'actor-1');
      expect(gateway.lastHistorySalesOrderId, 'so-1');
    });
  });
}
