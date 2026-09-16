import 'package:messaging_worker/sales_messaging_command_factory.dart';
import 'package:test/test.dart';
import 'package:vet45_sales_infrastructure/infrastructure.dart' as sales;

void main() {
  group('SalesMessagingCommandFactory', () {
    const factory = SalesMessagingCommandFactory();

    test('maps outbox to sales ProcessOutboxCommand', () {
      final command = factory.commandFor(
        queueType: 'outbox',
        tenantId: 'tenant-1',
        batchSize: 10,
      );

      expect(command, isA<sales.ProcessOutboxCommand>());
      expect((command! as sales.ProcessOutboxCommand).tenantId, 'tenant-1');
      expect((command as sales.ProcessOutboxCommand).batchSize, 10);
    });

    test('returns null for inbox and internal_commands', () {
      expect(
        factory.commandFor(
          queueType: 'inbox',
          tenantId: 'tenant-1',
          batchSize: 10,
        ),
        isNull,
      );
      expect(
        factory.commandFor(
          queueType: 'internal_commands',
          tenantId: 'tenant-1',
          batchSize: 10,
        ),
        isNull,
      );
    });

    test('returns null for unknown queue type', () {
      expect(
        factory.commandFor(
          queueType: 'dead_letter',
          tenantId: 'tenant-1',
          batchSize: 10,
        ),
        isNull,
      );
    });
  });
}
