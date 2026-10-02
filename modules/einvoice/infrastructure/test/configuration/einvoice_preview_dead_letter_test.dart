import 'package:get_it/get_it.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_infrastructure/infrastructure.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/i_einvoice_internal_command_client.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/preview_command_dead_letter_handler.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/process_internal_commands_command_handler.dart';

void main() {
  group('preview command dead letter', () {
    late GetIt container;

    setUp(() {
      container = GetIt.asNewInstance();
      EinvoiceStartup.initializeForTesting(
        supabase: SupabaseClient('https://dummy.supabase.co', 'dummy-key'),
        container: container,
      );
    });

    tearDown(() => container.reset());

    test('registers a dead-letter handler for preview_invoice', () {
      final handlers = container
          .get<ProcessInternalCommandsCommandHandler>()
          .deadLetterHandlersForTest;

      expect(
        handlers[PreviewInvoiceCommand.type],
        isA<PreviewCommandDeadLetterHandler>(),
      );
    });

    test('dead letter records FAILED with INTERNAL source', () async {
      final gateway = FakeInvoicePreviewGateway(requestId: 'req-1');
      final handler = PreviewCommandDeadLetterHandler(previewGateway: gateway);

      await handler.handleDeadLetter(
        tenantId: 'tenant-1',
        command: ClaimedInternalCommand(
          commandId: 'cmd-1',
          commandType: PreviewInvoiceCommand.type,
          payload: {'sales_order_id': 'order-1', 'preview_request_id': 'req-1'},
          enqueuedAt: DateTime.utc(2026, 10, 1),
          claimToken: 'token-1',
        ),
        error: StateError('PROVIDER_UNAVAILABLE'),
      );

      expect(gateway.stored, hasLength(1));
      expect(gateway.stored.single.status, 'FAILED');
      expect(gateway.stored.single.failureCode, 'PROVIDER_UNAVAILABLE');
      expect(gateway.stored.single.failureSource, FailureSource.internal);
      expect(gateway.stored.single.requestId, 'req-1');
      expect(gateway.stored.single.salesOrderId, 'order-1');
    });

    test('dead letter ignores a payload without request id', () async {
      final gateway = FakeInvoicePreviewGateway(requestId: 'req-1');
      final handler = PreviewCommandDeadLetterHandler(previewGateway: gateway);

      await handler.handleDeadLetter(
        tenantId: 'tenant-1',
        command: ClaimedInternalCommand(
          commandId: 'cmd-1',
          commandType: PreviewInvoiceCommand.type,
          payload: {'sales_order_id': 'order-1'},
          enqueuedAt: DateTime.utc(2026, 10, 1),
          claimToken: 'token-1',
        ),
        error: StateError('PROVIDER_UNAVAILABLE'),
      );

      expect(gateway.stored, isEmpty);
    });
  });
}
