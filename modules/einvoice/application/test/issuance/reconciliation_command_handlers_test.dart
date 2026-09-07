import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

final class FakeReconciliationGateway implements IIssuanceReconciliationGateway {
  ReconciliationCaseDto? openResult;
  ReconciliationPollContextDto? claimResult;
  ReconciliationCaseDto? resolveResult;
  RecoverInternalFinalizationResultDto? recoverResult;
  IssuanceAttemptStatusDto? statusResult;
  Map<String, Object?>? lastResolveEvidence;

  final List<String> calls = [];

  @override
  Future<ReconciliationCaseDto> openReconciliationCase({
    required String tenantId,
    required String attemptId,
    required String reason,
  }) async {
    calls.add('openReconciliationCase:$attemptId:$reason');
    return openResult ??
        ReconciliationCaseDto(
          caseId: 'case-1',
          attemptId: attemptId,
          status: ReconciliationCaseStatus.pending,
        );
  }

  @override
  Future<ReconciliationPollContextDto?> claimReconciliationCase({
    required String tenantId,
    required String caseId,
    required String workerId,
  }) async {
    calls.add('claimReconciliationCase:$caseId');
    return claimResult;
  }

  @override
  Future<void> recordPendingCheck({
    required String tenantId,
    required String caseId,
    required String claimToken,
    required Duration nextDelay,
    required int checkSequence,
  }) async {
    calls.add('recordPendingCheck:$caseId:$checkSequence');
  }

  @override
  Future<ReconciliationCaseDto> resolveReconciliationCase({
    required String tenantId,
    required String caseId,
    required String outcome,
    Map<String, Object?>? evidence,
  }) async {
    lastResolveEvidence = evidence;
    calls.add('resolveReconciliationCase:$caseId:$outcome');
    return resolveResult ??
        ReconciliationCaseDto(
          caseId: caseId,
          attemptId: 'attempt-1',
          status: ReconciliationCaseStatus.resolved,
        );
  }

  @override
  Future<void> markUnresolved({
    required String tenantId,
    required String caseId,
    required String claimToken,
    required String reasonCode,
  }) async {
    calls.add('markUnresolved:$caseId:$reasonCode');
  }

  @override
  Future<RecoverInternalFinalizationResultDto> recoverFinalization({
    required String tenantId,
    required String attemptId,
  }) async {
    calls.add('recoverFinalization:$attemptId');
    return recoverResult ??
        const RecoverInternalFinalizationResultDto(
          invoice: ElectronicInvoiceDto(
            electronicInvoiceId: 'inv-1',
            salesOrderId: 'so-1',
            providerInvoiceRef: '1C24TYY',
            invoiceNumber: '000001',
          ),
        );
  }

  @override
  Future<IssuanceAttemptStatusDto> getAttemptStatus({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) async {
    calls.add('getAttemptStatus:$salesOrderId');
    return statusResult ??
        const IssuanceAttemptStatusDto(
          attemptId: 'att-1',
          status: IssuanceAttemptStatus.succeeded,
          internalFinalizationStatus: InternalFinalizationStatus.completed,
          hasElectronicInvoice: true,
          hasActiveOperation: false,
          failureCode: null,
        );
  }
}

void main() {
  group('OpenReconciliationCase', () {
    test('validator accepts valid command', () async {
      final validator = OpenReconciliationCaseCommandValidator();
      await expectLater(
        validator.validate(
          OpenReconciliationCaseCommand(
            tenantId: 'tenant-1',
            attemptId: 'att-1',
            reason: 'MANUAL',
          ),
        ),
        completes,
      );
    });

    test('validator rejects empty fields', () {
      final validator = OpenReconciliationCaseCommandValidator();
      expect(
        () => validator.validate(
          OpenReconciliationCaseCommand(tenantId: '', attemptId: 'att-1', reason: 'MANUAL'),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => validator.validate(
          OpenReconciliationCaseCommand(tenantId: 'tenant-1', attemptId: '', reason: 'MANUAL'),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => validator.validate(
          OpenReconciliationCaseCommand(tenantId: 'tenant-1', attemptId: 'att-1', reason: ''),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('handler delegates to gateway', () async {
      final gateway = FakeReconciliationGateway();
      final handler = OpenReconciliationCaseCommandHandler(gateway: gateway);

      final result = await handler.handle(
        OpenReconciliationCaseCommand(
          tenantId: 'tenant-1',
          attemptId: 'att-1',
          reason: 'TIMEOUT',
        ),
      );

      expect(gateway.calls.single, 'openReconciliationCase:att-1:TIMEOUT');
      expect(result.status, ReconciliationCaseStatus.pending);
    });
  });

  group('ResolveReconciliationCase', () {
    test('validator accepts valid command', () async {
      final validator = ResolveReconciliationCaseCommandValidator();
      await expectLater(
        validator.validate(
          ResolveReconciliationCaseCommand(
            tenantId: 'tenant-1',
            caseId: 'case-1',
            outcome: 'SUCCESS',
            evidence: const {
              'provider_reference': 'tx-1',
              'invoice_number': '000001',
              'invoice_series': '1C26TYY',
              'issued_at': '2026-08-31T00:00:00.000Z',
            },
          ),
        ),
        completes,
      );
    });

    test('validator rejects empty fields', () {
      final validator = ResolveReconciliationCaseCommandValidator();
      expect(
        () => validator.validate(
          ResolveReconciliationCaseCommand(tenantId: '', caseId: 'case-1', outcome: 'SUCCESS'),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => validator.validate(
          ResolveReconciliationCaseCommand(tenantId: 'tenant-1', caseId: '', outcome: 'SUCCESS'),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => validator.validate(
          ResolveReconciliationCaseCommand(tenantId: 'tenant-1', caseId: 'case-1', outcome: ''),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => validator.validate(
          ResolveReconciliationCaseCommand(
            tenantId: 'tenant-1',
            caseId: 'case-1',
            outcome: 'SUCCESS',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('handler delegates to gateway', () async {
      final gateway = FakeReconciliationGateway();
      final handler = ResolveReconciliationCaseCommandHandler(gateway: gateway);

      final result = await handler.handle(
        ResolveReconciliationCaseCommand(
          tenantId: 'tenant-1',
          caseId: 'case-1',
          outcome: 'SUCCESS',
          evidence: const {
            'provider_reference': 'tx-1',
            'invoice_number': '000001',
            'invoice_series': '1C26TYY',
            'issued_at': '2026-08-31T00:00:00.000Z',
          },
        ),
      );

      expect(gateway.calls.single, 'resolveReconciliationCase:case-1:SUCCESS');
      expect(gateway.lastResolveEvidence?['provider_reference'], 'tx-1');
      expect(result.status, ReconciliationCaseStatus.resolved);
    });
  });

  group('RecoverInternalFinalization', () {
    test('validator accepts valid command', () async {
      final validator = RecoverInternalFinalizationCommandValidator();
      await expectLater(
        validator.validate(
          RecoverInternalFinalizationCommand(
            tenantId: 'tenant-1',
            attemptId: 'att-1',
          ),
        ),
        completes,
      );
    });

    test('validator rejects empty fields', () {
      final validator = RecoverInternalFinalizationCommandValidator();
      expect(
        () => validator.validate(
          RecoverInternalFinalizationCommand(tenantId: '', attemptId: 'att-1'),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => validator.validate(
          RecoverInternalFinalizationCommand(tenantId: 'tenant-1', attemptId: ''),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('handler delegates to gateway', () async {
      final gateway = FakeReconciliationGateway();
      final handler = RecoverInternalFinalizationCommandHandler(gateway: gateway);

      final result = await handler.handle(
        RecoverInternalFinalizationCommand(
          tenantId: 'tenant-1',
          attemptId: 'att-1',
        ),
      );

      expect(gateway.calls.single, 'recoverFinalization:att-1');
      expect(result.invoice.electronicInvoiceId, 'inv-1');
    });
  });

  group('GetIssuanceAttemptStatusQuery', () {
    test('handler delegates to gateway and returns safe DTO', () async {
      final gateway = FakeReconciliationGateway();
      final handler = GetIssuanceAttemptStatusQueryHandler(gateway: gateway);

      final result = await handler.handle(
        GetIssuanceAttemptStatusQuery(
          tenantId: 'tenant-1',
          actorId: 'act-1',
          salesOrderId: 'so-1',
        ),
      );

      expect(gateway.calls.single, 'getAttemptStatus:so-1');
      expect(result.status, IssuanceAttemptStatus.succeeded);
      expect(result.internalFinalizationStatus, InternalFinalizationStatus.completed);
      expect(result.hasElectronicInvoice, isTrue);
      expect(result.hasActiveOperation, isFalse);
    });
  });
}
