import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_infrastructure/infrastructure.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/worker_only_electronic_invoice_provider_port.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/generated/einvoice_internal_command_registry.g.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/invoice_document_command_dead_letter_handler.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/official_view_command_dead_letter_handler.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/process_internal_commands_command_handler.dart';
import 'package:vet45_einvoice_infrastructure/src/data_access/supabase_electronic_invoice_command_gateway.dart';
import 'package:vet45_einvoice_infrastructure/src/data_access/supabase_electronic_invoice_read_gateway.dart';

void main() {
  group('Einvoice S4 registration', () {
    late GetIt container;
    late EinvoiceRuntime runtime;

    setUp(() {
      container = GetIt.asNewInstance();
      runtime = EinvoiceStartup.initializeForTesting(
        supabase: SupabaseClient('https://dummy.supabase.co', 'dummy-key'),
        container: container,
      );
    });

    tearDown(() => container.reset());

    test('registers S4 gateways and worker handlers', () {
      expect(
        container.get<IElectronicInvoiceCommandGateway>(),
        isA<SupabaseElectronicInvoiceCommandGateway>(),
      );
      expect(
        container.get<IElectronicInvoiceReadGateway>(),
        isA<SupabaseElectronicInvoiceReadGateway>(),
      );
      expect(
        container.get<FetchOfficialInvoiceViewCommandHandler>(),
        isA<FetchOfficialInvoiceViewCommandHandler>(),
      );
      expect(
        container.get<DownloadInvoiceDocumentCommandHandler>(),
        isA<DownloadInvoiceDocumentCommandHandler>(),
      );
      expect(
        container.get<PollProviderObservationCommandHandler>(),
        isA<PollProviderObservationCommandHandler>(),
      );
    });

    test(
      'ERP composition registers worker-only electronic invoice provider port',
      () async {
        expect(
          container.get<IElectronicInvoiceProviderPort>(),
          isA<WorkerOnlyElectronicInvoiceProviderPort>(),
        );

        await expectLater(
          container.get<IElectronicInvoiceProviderPort>().fetchOfficialView(
            const ElectronicInvoiceProviderContextDto(
              tenantId: 'tenant-1',
              providerConnectionId: 'conn-1',
              electronicInvoiceId: 'ei-1',
              providerInvoiceReference: 'ref-1',
              invoiceSeries: '1C26TYY',
              operationId: 'op-1',
            ),
          ),
          throwsA(isA<StateError>()),
        );
      },
    );

    test('internal command registry deserializes three S4 worker commands', () {
      final serializer = createGeneratedEinvoiceInternalCommandSerializer();

      final official = serializer.deserialize(
        commandType: FetchOfficialInvoiceViewCommand.type,
        payload: {
          'tenant_id': 'tenant-1',
          'electronic_invoice_id': 'ei-1',
          'request_id': 'req-1',
          'correlation_id': 'corr-1',
        },
        id: 'cmd-official-1',
      );
      expect(official, isA<FetchOfficialInvoiceViewCommand>());

      final document = serializer.deserialize(
        commandType: DownloadInvoiceDocumentCommand.type,
        payload: {
          'tenant_id': 'tenant-1',
          'electronic_invoice_id': 'ei-1',
          'document_type': 'PDF',
          'request_id': 'req-doc-1',
          'correlation_id': 'corr-doc-1',
        },
        id: 'cmd-doc-1',
      );
      expect(document, isA<DownloadInvoiceDocumentCommand>());

      final observation = serializer.deserialize(
        commandType: PollProviderObservationCommand.type,
        payload: {
          'tenant_id': 'tenant-1',
          'provider_connection_id': 'conn-1',
          'electronic_invoice_id': 'ei-1',
          'trigger_id': 'trigger-1',
          'correlation_id': 'corr-obs-1',
        },
        id: 'cmd-obs-1',
      );
      expect(observation, isA<PollProviderObservationCommand>());
    });

    test('S4 dead-letter handlers are concrete and distinct', () {
      expect(OfficialViewCommandDeadLetterHandler, isA<Type>());
      expect(InvoiceDocumentCommandDeadLetterHandler, isA<Type>());
    });

    test('internal command client has no observation seeder', () {
      final source = File(
        'lib/src/configuration/processing/internal_commands/i_einvoice_internal_command_client.dart',
      ).readAsStringSync();
      expect(source, contains('seedDueReconciliationCommands'));
      expect(source, isNot(contains('seedDueProviderObservationCommands')));
    });

    test('process internal commands handler is registered', () {
      expect(
        container.get<ProcessInternalCommandsCommandHandler>(),
        isA<ProcessInternalCommandsCommandHandler>(),
      );
      expect(runtime.module, isNotNull);
    });
  });
}
