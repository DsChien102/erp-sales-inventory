import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';

void main() {
  test('legacy SQL camelCase payload deserializes into canonical keys', () {
    final command = SendInvoiceEmailCommand.fromJson({
      'tenantId': 'tenant',
      'deliveryId': 'delivery',
      'retryCount': 1,
    }, id: 'command');
    expect(command.toJson(), {
      'tenant_id': 'tenant',
      'delivery_id': 'delivery',
      'retry_count': 1,
    });
  });
  test('conflicting aliases reject instead of selecting one identity', () {
    expect(
      () => SendInvoiceEmailCommand.fromJson({
        'tenant_id': 'tenant',
        'tenantId': 'other',
        'delivery_id': 'delivery',
        'retry_count': 0,
      }, id: 'command'),
      throwsFormatException,
    );
  });
  for (final bad in [null, '', ' ', 12]) {
    test('invalid identity $bad rejects with safe field error', () {
      expect(
        () => SendInvoiceEmailCommand.fromJson({
          'tenant_id': 'tenant',
          'delivery_id': bad,
          'retry_count': 0,
        }, id: 'command'),
        throwsFormatException,
      );
    });
  }
  for (final bad in [null, '0', -1, 3, 1.5]) {
    test('invalid retry count $bad rejects', () {
      expect(
        () => SendInvoiceEmailCommand.fromJson({
          'tenant_id': 'tenant',
          'delivery_id': 'delivery',
          'retry_count': bad,
        }, id: 'command'),
        throwsFormatException,
      );
    });
  }
}
