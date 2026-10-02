import 'package:get_it/get_it.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_infrastructure/infrastructure.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/me_invoice_delivery_observation_provider_adapter.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/delivery_reconciliation_command_dead_letter_handler.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/einvoice_internal_command_attempt_policy.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/i_einvoice_internal_command_client.dart';

// ClaimedInternalCommand lives in the internal command client API.

void main() {
  group('Einvoice S5 reconciliation registration', () {
    late GetIt container;

    setUp(() {
      container = GetIt.asNewInstance();
      EinvoiceStartup.initializeForTesting(
        supabase: SupabaseClient('https://dummy.supabase.co', 'dummy-key'),
        container: container,
      );
    });

    tearDown(() => container.reset());

    test('observation unsupported adapter resolves in composition', () {
      expect(
        container.get<IInvoiceDeliveryObservationProviderPort>(),
        isA<MeInvoiceDeliveryObservationProviderAdapter>(),
      );
      expect(
        container.get<ReconcileInvoiceDeliveryCommandHandler>(),
        isA<ReconcileInvoiceDeliveryCommandHandler>(),
      );
      expect(
        maxAttemptsForCommandType(ReconcileInvoiceDeliveryCommand.type),
        3,
      );
    });

    test(
      'exhausted reconcile dead-letter records unsupported UNRESOLVED attention path',
      () async {
        final reconciliation = _TrackingReconciliationGateway();
        final observation = _TrackingObservationPort();
        final handler = DeliveryReconciliationCommandDeadLetterHandler(
          reconciliationGateway: reconciliation,
        );

        await handler.handleDeadLetter(
          tenantId: 'tenant-1',
          command: ClaimedInternalCommand(
            commandId: 'cmd-reconcile-1',
            commandType: ReconcileInvoiceDeliveryCommand.type,
            payload: {'reconciliation_case_id': 'case-1', 'check_sequence': 1},
            enqueuedAt: DateTime.utc(2026, 9, 2),
            claimToken: 'tok-1',
            retryCount: 3,
          ),
          error: Exception('worker exhausted'),
        );

        expect(reconciliation.loadCalls, hasLength(1));
        expect(reconciliation.recordChecks, hasLength(1));
        final check = reconciliation.recordChecks.single;
        expect(check.kind, DeliveryObservationKind.unsupported);
        expect(check.safeCode, 'DELIVERY_RECONCILIATION_WORKER_EXHAUSTED');
        expect(check.reconciliationCaseId, 'case-1');
        expect(observation.observeCalls, isEmpty);
        expect(reconciliation.sendEmailCalls, isEmpty);
      },
    );

    test(
      'reconcile dead-letter skips when loadContext returns null (not PENDING)',
      () async {
        final reconciliation = _TrackingReconciliationGateway()..context = null;
        final handler = DeliveryReconciliationCommandDeadLetterHandler(
          reconciliationGateway: reconciliation,
        );

        await handler.handleDeadLetter(
          tenantId: 'tenant-1',
          command: ClaimedInternalCommand(
            commandId: 'cmd-reconcile-2',
            commandType: ReconcileInvoiceDeliveryCommand.type,
            payload: {'reconciliation_case_id': 'case-2', 'check_sequence': 2},
            enqueuedAt: DateTime.utc(2026, 9, 2),
            claimToken: 'tok-2',
            retryCount: 3,
          ),
          error: Exception('worker exhausted'),
        );

        expect(reconciliation.recordChecks, isEmpty);
      },
    );
  });
}

final class _TrackingObservationPort
    implements IInvoiceDeliveryObservationProviderPort {
  final List<DeliveryObservationContextDto> observeCalls = [];

  @override
  Future<DeliveryObservationOutcome> observe(
    DeliveryObservationContextDto context,
  ) async {
    observeCalls.add(context);
    return const DeliveryObservationUnsupported();
  }
}

final class _TrackingReconciliationGateway
    implements IDeliveryReconciliationGateway {
  DeliveryReconciliationContextDto? context =
      const DeliveryReconciliationContextDto(
        tenantId: 'tenant-1',
        reconciliationCaseId: 'case-1',
        deliveryId: 'del-1',
        providerConnectionId: 'conn-1',
        supportsDeliveryResultObservation: false,
        checkSequence: 1,
        caseVersion: 1,
      );

  final List<String> loadCalls = [];
  final List<DeliveryReconciliationCheckRecord> recordChecks = [];
  final List<String> sendEmailCalls = [];

  @override
  Future<DeliveryReconciliationContextDto?> loadContext({
    required String tenantId,
    required String reconciliationCaseId,
    required int checkSequence,
  }) async {
    loadCalls.add('$tenantId:$reconciliationCaseId:$checkSequence');
    return context;
  }

  @override
  Future<DeliveryReconciliationResultDto> recordCheck(
    DeliveryReconciliationCheckRecord record,
  ) async {
    recordChecks.add(record);
    return const DeliveryReconciliationResultDto(
      caseStatus: ReconciliationCaseStatus.unresolved,
      deliveryStatus: DeliveryStatus.unknown,
      hasSecondaryAttention: true,
    );
  }
}
