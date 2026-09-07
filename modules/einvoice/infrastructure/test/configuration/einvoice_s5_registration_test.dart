import 'package:get_it/get_it.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_infrastructure/infrastructure.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/me_invoice_delivery_observation_provider_adapter.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/worker_only_invoice_delivery_provider_port.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/generated/einvoice_internal_command_registry.g.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/delivery_command_dead_letter_handler.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/delivery_reconciliation_command_dead_letter_handler.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/einvoice_internal_command_attempt_policy.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/process_internal_commands_command_handler.dart';
import 'package:vet45_einvoice_infrastructure/src/domain/delivery/supabase_delivery_command_gateway.dart';
import 'package:vet45_einvoice_infrastructure/src/domain/delivery/supabase_delivery_read_gateway.dart';
import 'package:vet45_einvoice_infrastructure/src/domain/delivery/supabase_delivery_reconciliation_gateway.dart';

void main() {
  group('Einvoice S5 registration', () {
    late GetIt container;

    setUp(() {
      container = GetIt.asNewInstance();
      EinvoiceStartup.initializeForTesting(
        supabase: SupabaseClient('https://dummy.supabase.co', 'dummy-key'),
        container: container,
      );
    });

    tearDown(() => container.reset());

    test('registers S5 delivery gateways and handlers exactly once', () {
      expect(
        container.get<IDeliveryCommandGateway>(),
        isA<SupabaseDeliveryCommandGateway>(),
      );
      expect(
        container.get<IDeliveryReadGateway>(),
        isA<SupabaseDeliveryReadGateway>(),
      );
      expect(
        container.get<IDeliveryReconciliationGateway>(),
        isA<SupabaseDeliveryReconciliationGateway>(),
      );
      expect(
        container.get<IInvoiceDeliveryObservationProviderPort>(),
        isA<MeInvoiceDeliveryObservationProviderAdapter>(),
      );
      expect(
        container.get<SendInvoiceEmailCommandHandler>(),
        isA<SendInvoiceEmailCommandHandler>(),
      );
      expect(
        container.get<ReconcileInvoiceDeliveryCommandHandler>(),
        isA<ReconcileInvoiceDeliveryCommandHandler>(),
      );
      expect(
        container.get<StartAutoDeliveryCommandHandler>(),
        isA<StartAutoDeliveryCommandHandler>(),
      );
      expect(
        container.get<ProcessInternalCommandsCommandHandler>(),
        isA<ProcessInternalCommandsCommandHandler>(),
      );

      expect(container.isRegistered<IDeliveryCommandGateway>(), isTrue);
      expect(container.isRegistered<IInvoiceDeliveryProviderPort>(), isTrue);
    });

    test(
      'ERP composition registers worker-only delivery provider port',
      () async {
        final port = container.get<IInvoiceDeliveryProviderPort>();
        expect(port, isA<WorkerOnlyInvoiceDeliveryProviderPort>());

        await expectLater(
          port.sendEmail(
            const DeliveryProviderContextDto(
              tenantId: 'tenant-1',
              providerConnectionId: 'conn-1',
              providerTransactionId: 'txn-1',
              invoiceSeries: '1C26TYY',
              recipientEmail: 'buyer@example.com',
              recipientName: 'Buyer',
            ),
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('worker-only'),
            ),
          ),
        );
      },
    );

    test('internal command registry deserializes S5 worker commands', () {
      final serializer = createGeneratedEinvoiceInternalCommandSerializer();

      final send = serializer.deserialize(
        commandType: SendInvoiceEmailCommand.type,
        payload: {
          'tenant_id': 'tenant-1',
          'delivery_id': 'del-1',
          'attempt_id': 'att-1',
        },
        id: 'cmd-send-1',
      );
      expect(send, isA<SendInvoiceEmailCommand>());

      final reconcile = serializer.deserialize(
        commandType: ReconcileInvoiceDeliveryCommand.type,
        payload: {
          'tenant_id': 'tenant-1',
          'reconciliation_case_id': 'case-1',
          'check_sequence': 1,
        },
        id: 'cmd-reconcile-1',
      );
      expect(reconcile, isA<ReconcileInvoiceDeliveryCommand>());
    });

    test('attempt policy caps send and reconcile at three', () {
      expect(maxAttemptsForCommandType(SendInvoiceEmailCommand.type), 3);
      expect(
        maxAttemptsForCommandType(ReconcileInvoiceDeliveryCommand.type),
        3,
      );
    });

    test('S5 dead-letter handlers are concrete and distinct', () {
      expect(DeliveryCommandDeadLetterHandler, isA<Type>());
      expect(DeliveryReconciliationCommandDeadLetterHandler, isA<Type>());
      expect(
        DeliveryCommandDeadLetterHandler,
        isNot(DeliveryReconciliationCommandDeadLetterHandler),
      );
    });

    test('ProcessInternalCommands maps live S5 dead-letter handlers', () {
      final handler = container.get<ProcessInternalCommandsCommandHandler>();
      final deadLetterHandlers = handler.deadLetterHandlersForTest;

      expect(
        deadLetterHandlers[SendInvoiceEmailCommand.type],
        isA<DeliveryCommandDeadLetterHandler>(),
      );
      expect(
        deadLetterHandlers[ReconcileInvoiceDeliveryCommand.type],
        isA<DeliveryReconciliationCommandDeadLetterHandler>(),
      );
    });
  });
}
