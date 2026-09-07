import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_domain/domain.dart';

final class _FakeReconciliationGateway implements IDeliveryReconciliationGateway {
  DeliveryReconciliationContextDto? context;
  final List<DeliveryReconciliationCheckRecord> recordCalls = [];
  DeliveryReconciliationResultDto recordResult = const DeliveryReconciliationResultDto(
    caseStatus: ReconciliationCaseStatus.unresolved,
    deliveryStatus: DeliveryStatus.unknown,
    nextCheckAt: null,
    hasSecondaryAttention: true,
  );

  @override
  Future<DeliveryReconciliationContextDto?> loadContext({
    required String tenantId,
    required String reconciliationCaseId,
    required int checkSequence,
  }) async => context;

  @override
  Future<DeliveryReconciliationResultDto> recordCheck(
    DeliveryReconciliationCheckRecord record,
  ) async {
    recordCalls.add(record);
    return recordResult;
  }
}

final class _FakeObservationPort implements IInvoiceDeliveryObservationProviderPort {
  DeliveryObservationOutcome outcome = const DeliveryObservationUnsupported();
  int observeCalls = 0;
  DeliveryObservationContextDto? lastContext;

  @override
  Future<DeliveryObservationOutcome> observe(
    DeliveryObservationContextDto context,
  ) async {
    observeCalls++;
    lastContext = context;
    return outcome;
  }
}

DeliveryReconciliationContextDto _context({
  bool supportsObservation = false,
  int checkSequence = 1,
  int caseVersion = 0,
}) {
  return DeliveryReconciliationContextDto(
    tenantId: 'tenant-1',
    reconciliationCaseId: 'case-1',
    deliveryId: 'del-1',
    attemptId: 'att-1',
    providerConnectionId: 'conn-1',
    supportsDeliveryResultObservation: supportsObservation,
    checkSequence: checkSequence,
    caseVersion: caseVersion,
  );
}

ReconcileInvoiceDeliveryCommand _command({int checkSequence = 1}) {
  return ReconcileInvoiceDeliveryCommand(
    id: 'cmd-1',
    tenantId: 'tenant-1',
    reconciliationCaseId: 'case-1',
    checkSequence: checkSequence,
  );
}

void main() {
  group('ReconcileInvoiceDeliveryCommand', () {
    test('serializes only tenant, case id, and check sequence', () {
      final command = _command();
      final json = command.toJson();

      expect(command.commandType, 'einvoice.reconcile_invoice_delivery');
      expect(json.keys.toSet(), {
        'tenant_id',
        'reconciliation_case_id',
        'check_sequence',
      });
      expect(json, isNot(contains('recipient_email')));
      expect(json, isNot(contains('getStatus')));
    });

    test('round-trips through fromJson', () {
      final original = _command(checkSequence: 3);
      final restored = ReconcileInvoiceDeliveryCommand.fromJson(
        original.toJson(),
        id: original.id,
      );

      expect(restored.tenantId, original.tenantId);
      expect(restored.reconciliationCaseId, original.reconciliationCaseId);
      expect(restored.checkSequence, original.checkSequence);
      expect(restored.id, original.id);
    });
  });

  group('ReconcileInvoiceDeliveryCommandHandler', () {
    test('missing or stale case is a no-op', () async {
      final gateway = _FakeReconciliationGateway()..context = null;
      final observation = _FakeObservationPort();
      final interactions = FakeProviderInteractionGateway();

      await ReconcileInvoiceDeliveryCommandHandler(
        reconciliationGateway: gateway,
        observationPort: observation,
        interactionGateway: interactions,
      ).handle(_command());

      expect(observation.observeCalls, 0);
      expect(interactions.startCalls, isEmpty);
      expect(gateway.recordCalls, isEmpty);
    });

    test(
      'unsupported capability records unsupported without provider calls',
      () async {
        final gateway = _FakeReconciliationGateway()
          ..context = _context(supportsObservation: false);
        final observation = _FakeObservationPort();
        final interactions = FakeProviderInteractionGateway();

        await ReconcileInvoiceDeliveryCommandHandler(
          reconciliationGateway: gateway,
          observationPort: observation,
          interactionGateway: interactions,
        ).handle(_command());

        expect(observation.observeCalls, 0);
        expect(interactions.startCalls, isEmpty);
        expect(interactions.finalizeCalls, isEmpty);
        expect(gateway.recordCalls, hasLength(1));
        final record = gateway.recordCalls.single;
        expect(record.kind, DeliveryObservationKind.unsupported);
        expect(record.safeCode, 'DELIVERY_RESULT_OBSERVATION_UNSUPPORTED');
        expect(record.interactionReference, isNull);
        expect(record.checkSequence, 1);
        expect(record.expectedCaseVersion, 0);
      },
    );

    test(
      'supported capability performs exactly one observation interaction',
      () async {
        final gateway = _FakeReconciliationGateway()
          ..context = _context(supportsObservation: true)
          ..recordResult = const DeliveryReconciliationResultDto(
            caseStatus: ReconciliationCaseStatus.resolved,
            deliveryStatus: DeliveryStatus.succeeded,
            nextCheckAt: null,
            hasSecondaryAttention: false,
          );
        final observation = _FakeObservationPort()
          ..outcome = const DeliveryObservedSucceeded(
            providerReference: 'prov-del-1',
          );
        final interactions = FakeProviderInteractionGateway();

        await ReconcileInvoiceDeliveryCommandHandler(
          reconciliationGateway: gateway,
          observationPort: observation,
          interactionGateway: interactions,
        ).handle(_command());

        expect(observation.observeCalls, 1);
        expect(interactions.startCalls, hasLength(1));
        expect(
          interactions.startCalls.single.operationType,
          ReconcileInvoiceDeliveryCommand.type,
        );
        expect(interactions.startCalls.single.targetType, 'DELIVERY_ATTEMPT');
        expect(interactions.startCalls.single.targetId, 'att-1');
        expect(interactions.finalizeCalls, hasLength(1));
        expect(gateway.recordCalls, hasLength(1));
        expect(gateway.recordCalls.single.kind, DeliveryObservationKind.succeeded);
        expect(gateway.recordCalls.single.providerReference, 'prov-del-1');
        expect(gateway.recordCalls.single.interactionReference, isNotNull);
      },
    );

    test('terminal definite failure records resolution check', () async {
      final gateway = _FakeReconciliationGateway()
        ..context = _context(supportsObservation: true)
        ..recordResult = const DeliveryReconciliationResultDto(
          caseStatus: ReconciliationCaseStatus.resolved,
          deliveryStatus: DeliveryStatus.failed,
          nextCheckAt: null,
          hasSecondaryAttention: false,
        );
      final observation = _FakeObservationPort()
        ..outcome = const DeliveryObservedDefiniteFailure(
          'PROVIDER_DELIVERY_REJECTED',
        );
      final interactions = FakeProviderInteractionGateway();

      await ReconcileInvoiceDeliveryCommandHandler(
        reconciliationGateway: gateway,
        observationPort: observation,
        interactionGateway: interactions,
      ).handle(_command());

      expect(gateway.recordCalls.single.kind, DeliveryObservationKind.definiteFailure);
      expect(gateway.recordCalls.single.safeCode, 'PROVIDER_DELIVERY_REJECTED');
    });

    test('undetermined observation continues the same case', () async {
      final gateway = _FakeReconciliationGateway()
        ..context = _context(supportsObservation: true, checkSequence: 2)
        ..recordResult = DeliveryReconciliationResultDto(
          caseStatus: ReconciliationCaseStatus.pending,
          deliveryStatus: DeliveryStatus.unknown,
          nextCheckAt: DateTime.utc(2026, 9, 3, 1),
          hasSecondaryAttention: false,
        );
      final observation = _FakeObservationPort()
        ..outcome = const DeliveryObservationUndetermined(
          'PROVIDER_DELIVERY_PENDING',
        );
      final interactions = FakeProviderInteractionGateway();

      await ReconcileInvoiceDeliveryCommandHandler(
        reconciliationGateway: gateway,
        observationPort: observation,
        interactionGateway: interactions,
      ).handle(_command(checkSequence: 2));

      expect(observation.observeCalls, 1);
      expect(gateway.recordCalls.single.kind, DeliveryObservationKind.undetermined);
      expect(gateway.recordCalls.single.checkSequence, 2);
      expect(gateway.recordResult.caseStatus, ReconciliationCaseStatus.pending);
      expect(gateway.recordResult.nextCheckAt, isNotNull);
    });
  });
}
