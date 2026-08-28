import 'package:messaging_worker/einvoice_messaging_command_factory.dart';
import 'package:test/test.dart';
import 'package:vet45_einvoice_infrastructure/infrastructure.dart';

void main() {
  group('EinvoiceMessagingCommandFactory', () {
    const factory = EinvoiceMessagingCommandFactory();

    test('maps outbox/inbox/internal_commands to einvoice Process* types', () {
      final outbox = factory.commandFor(
        queueType: 'outbox',
        tenantId: 't1',
        batchSize: 5,
      );
      final inbox = factory.commandFor(
        queueType: 'inbox',
        tenantId: 't1',
        batchSize: 5,
      );
      final internal = factory.commandFor(
        queueType: 'internal_commands',
        tenantId: 't1',
        batchSize: 5,
      );

      expect(outbox, isA<ProcessOutboxCommand>());
      expect((outbox! as ProcessOutboxCommand).batchSize, 5);
      expect(inbox, isA<ProcessInboxCommand>());
      expect(internal, isA<ProcessInternalCommandsCommand>());
    });

    test('returns null for unknown queue type', () {
      expect(
        factory.commandFor(
          queueType: 'dead_letter',
          tenantId: 't1',
          batchSize: 5,
        ),
        isNull,
      );
    });
  });
}
