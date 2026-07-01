import 'package:test/test.dart';
import 'package:vet45_partner_integration_events/integration_events.dart';

void main() {
  test('SalesOrderCheckedOutIntegrationEvent.fromInbox uses message id', () {
    final event = SalesOrderCheckedOutIntegrationEvent.fromInbox(
      messageId: 'msg-1',
      occurredOn: DateTime.parse('2026-06-30T12:00:00Z'),
      payload: {
        'tenant_id': 'tenant-1',
        'business_partner_id': 'partner-1',
        'order_id': 'order-1',
        'order_code': 'SO-001',
      },
    );

    expect(event.id, 'msg-1');
    expect(event.tenantId, 'tenant-1');
    expect(event.orderId, 'order-1');
    expect(event.eventType, SalesOrderCheckedOutIntegrationEvent.type);
  });
}
