import 'package:test/test.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  group('InvoiceDelivery', () {
    final startedAt = DateTime.utc(2026, 9, 2, 10);
    final recipient = DeliveryRecipientSnapshot(
      toEmail: DeliveryRecipientEmail('buyer@clinic.vn'),
      source: DeliveryRecipientSource.userInput,
    );

    InvoiceDelivery startInitial({
      bool invoiceHasActiveLock = false,
      bool hasPriorInitialDelivery = false,
      bool hasPriorDeliveryHistory = false,
    }) {
      return InvoiceDelivery.start(
        id: 'delivery-1',
        tenantId: TenantId('tenant-1'),
        electronicInvoiceId: 'invoice-1',
        deliveryNumber: 1,
        kind: DeliveryKind.initial,
        triggerType: DeliveryTriggerType.manual,
        actorType: DeliveryActorType.user,
        actorId: 'user-1',
        recipient: recipient,
        firstAttemptId: 'attempt-1',
        providerConnectionId: 'conn-1',
        startedAt: startedAt,
        hasPriorDeliveryHistory: hasPriorDeliveryHistory,
        hasPriorInitialDelivery: hasPriorInitialDelivery,
        invoiceHasActiveLock: invoiceHasActiveLock,
      );
    }

    InvoiceDelivery startResend({
      bool invoiceHasActiveLock = false,
      bool hasPriorDeliveryHistory = true,
      bool hasPriorInitialDelivery = true,
    }) {
      return InvoiceDelivery.start(
        id: 'delivery-2',
        tenantId: TenantId('tenant-1'),
        electronicInvoiceId: 'invoice-1',
        deliveryNumber: 2,
        kind: DeliveryKind.resend,
        triggerType: DeliveryTriggerType.manual,
        actorType: DeliveryActorType.user,
        actorId: 'user-1',
        recipient: recipient,
        firstAttemptId: 'attempt-1',
        providerConnectionId: 'conn-1',
        startedAt: startedAt,
        hasPriorDeliveryHistory: hasPriorDeliveryHistory,
        hasPriorInitialDelivery: hasPriorInitialDelivery,
        invoiceHasActiveLock: invoiceHasActiveLock,
      );
    }

    test('start creates PROCESSING delivery with one QUEUED attempt', () {
      final delivery = startInitial();

      expect(delivery.status, DeliveryStatus.processing);
      expect(delivery.kind, DeliveryKind.initial);
      expect(delivery.recipient, recipient);
      expect(delivery.hasActiveLock, isTrue);
      expect(delivery.attempts, hasLength(1));
      expect(delivery.latestAttempt!.status, DeliveryAttemptStatus.queued);
      expect(delivery.latestAttempt!.attemptNumber, 1);
      expect(
        delivery.domainEvents,
        contains(isA<InvoiceDeliveryStartedDomainEvent>()),
      );
    });

    test('recipient snapshot stays immutable across retries', () {
      final delivery = startInitial();
      delivery.markAttemptSubmitted(
        attemptId: 'attempt-1',
        providerInteractionReference: 'interaction-1',
        providerRequestReference: 'request-1',
        submittedAt: startedAt.add(const Duration(seconds: 1)),
      );
      delivery.applyProviderResult(
        attemptId: 'attempt-1',
        result: const ProviderDeliveryResult.retryableFailure(
          safeCode: 'PROVIDER_THROTTLED',
        ),
        completedAt: startedAt.add(const Duration(seconds: 2)),
        nextAttemptId: 'attempt-2',
      );

      expect(delivery.recipient, recipient);
      expect(delivery.attempts, hasLength(2));
      expect(delivery.attempts.last.status, DeliveryAttemptStatus.queued);
    });

    test('initial-vs-resend rule rejects mismatched kind', () {
      expect(
        () => startInitial(hasPriorInitialDelivery: true),
        throwsA(isA<BusinessRuleValidationException>()),
      );
      expect(
        () => startResend(hasPriorDeliveryHistory: false),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });

    test('active lock blocks a competing start', () {
      expect(
        () => startInitial(invoiceHasActiveLock: true),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });

    test('legal transitions: submitted then success', () {
      final delivery = startInitial();
      delivery.markAttemptSubmitted(
        attemptId: 'attempt-1',
        providerInteractionReference: 'interaction-1',
        providerRequestReference: 'request-1',
        submittedAt: startedAt.add(const Duration(seconds: 1)),
      );
      delivery.applyProviderResult(
        attemptId: 'attempt-1',
        result: const ProviderDeliveryResult.success(
          providerReference: 'provider-send-1',
        ),
        completedAt: startedAt.add(const Duration(seconds: 2)),
      );

      expect(delivery.status, DeliveryStatus.succeeded);
      expect(delivery.latestAttempt!.status, DeliveryAttemptStatus.succeeded);
      expect(delivery.hasActiveLock, isFalse);
      expect(
        delivery.domainEvents,
        contains(isA<InvoiceDeliverySucceededDomainEvent>()),
      );
    });

    test('idempotent duplicate success result does not mutate again', () {
      final delivery = startInitial();
      delivery.markAttemptSubmitted(
        attemptId: 'attempt-1',
        providerInteractionReference: 'interaction-1',
        providerRequestReference: 'request-1',
        submittedAt: startedAt.add(const Duration(seconds: 1)),
      );
      final completedAt = startedAt.add(const Duration(seconds: 2));
      delivery.applyProviderResult(
        attemptId: 'attempt-1',
        result: const ProviderDeliveryResult.success(
          providerReference: 'provider-send-1',
        ),
        completedAt: completedAt,
      );
      delivery.clearDomainEvent();
      final version = delivery.version;

      delivery.applyProviderResult(
        attemptId: 'attempt-1',
        result: const ProviderDeliveryResult.success(
          providerReference: 'provider-send-1',
        ),
        completedAt: completedAt.add(const Duration(seconds: 1)),
      );

      expect(delivery.status, DeliveryStatus.succeeded);
      expect(delivery.version, version);
      expect(delivery.domainEvents, isEmpty);
    });

    test('success never reverses from a later failure', () {
      final delivery = startInitial();
      delivery.markAttemptSubmitted(
        attemptId: 'attempt-1',
        providerInteractionReference: 'interaction-1',
        providerRequestReference: 'request-1',
        submittedAt: startedAt.add(const Duration(seconds: 1)),
      );
      delivery.applyProviderResult(
        attemptId: 'attempt-1',
        result: const ProviderDeliveryResult.success(
          providerReference: 'provider-send-1',
        ),
        completedAt: startedAt.add(const Duration(seconds: 2)),
      );
      final version = delivery.version;

      delivery.applyProviderResult(
        attemptId: 'attempt-1',
        result: const ProviderDeliveryResult.definiteFailure(
          safeCode: 'PROVIDER_REJECTED',
        ),
        completedAt: startedAt.add(const Duration(seconds: 3)),
      );

      expect(delivery.status, DeliveryStatus.succeeded);
      expect(delivery.version, version);
    });

    test('unknown may later resolve to success for the same attempt', () {
      final delivery = startInitial();
      delivery.markAttemptSubmitted(
        attemptId: 'attempt-1',
        providerInteractionReference: 'interaction-1',
        providerRequestReference: 'request-1',
        submittedAt: startedAt.add(const Duration(seconds: 1)),
      );
      delivery.applyProviderResult(
        attemptId: 'attempt-1',
        result: const ProviderDeliveryResult.undetermined(
          safeCode: 'PROVIDER_TIMEOUT',
        ),
        completedAt: startedAt.add(const Duration(seconds: 2)),
      );
      expect(delivery.status, DeliveryStatus.unknown);
      expect(
        delivery.domainEvents,
        contains(isA<InvoiceDeliveryUndeterminedDomainEvent>()),
      );

      delivery.applyProviderResult(
        attemptId: 'attempt-1',
        result: const ProviderDeliveryResult.success(
          providerReference: 'provider-send-1',
        ),
        completedAt: startedAt.add(const Duration(seconds: 30)),
      );

      expect(delivery.status, DeliveryStatus.succeeded);
      expect(delivery.latestAttempt!.status, DeliveryAttemptStatus.succeeded);
    });

    test('unknown may later resolve to definite failure for the same attempt', () {
      final delivery = startInitial();
      delivery.markAttemptSubmitted(
        attemptId: 'attempt-1',
        providerInteractionReference: 'interaction-1',
        providerRequestReference: 'request-1',
        submittedAt: startedAt.add(const Duration(seconds: 1)),
      );
      delivery.applyProviderResult(
        attemptId: 'attempt-1',
        result: const ProviderDeliveryResult.undetermined(
          safeCode: 'PROVIDER_TIMEOUT',
        ),
        completedAt: startedAt.add(const Duration(seconds: 2)),
      );
      expect(delivery.status, DeliveryStatus.unknown);
      expect(delivery.latestAttempt!.status, DeliveryAttemptStatus.unknown);
      delivery.clearDomainEvent();

      delivery.applyProviderResult(
        attemptId: 'attempt-1',
        result: const ProviderDeliveryResult.definiteFailure(
          safeCode: 'PROVIDER_REJECTED',
        ),
        completedAt: startedAt.add(const Duration(seconds: 30)),
      );

      expect(delivery.status, DeliveryStatus.failed);
      expect(delivery.latestAttempt!.status, DeliveryAttemptStatus.failed);
      expect(delivery.hasActiveLock, isFalse);
      expect(
        delivery.domainEvents,
        contains(isA<InvoiceDeliveryFailedDomainEvent>()),
      );
    });

    test(
      'non-authoritative results while UNKNOWN are rejected by rule',
      () {
        final delivery = startInitial();
        delivery.markAttemptSubmitted(
          attemptId: 'attempt-1',
          providerInteractionReference: 'interaction-1',
          providerRequestReference: 'request-1',
          submittedAt: startedAt.add(const Duration(seconds: 1)),
        );
        delivery.applyProviderResult(
          attemptId: 'attempt-1',
          result: const ProviderDeliveryResult.undetermined(
            safeCode: 'PROVIDER_TIMEOUT',
          ),
          completedAt: startedAt.add(const Duration(seconds: 2)),
        );
        expect(delivery.status, DeliveryStatus.unknown);

        expect(
          () => delivery.applyProviderResult(
            attemptId: 'attempt-1',
            result: const ProviderDeliveryResult.retryableFailure(
              safeCode: 'PROVIDER_THROTTLED',
            ),
            completedAt: startedAt.add(const Duration(seconds: 3)),
            nextAttemptId: 'attempt-2',
          ),
          throwsA(isA<BusinessRuleValidationException>()),
        );
        expect(
          () => delivery.applyProviderResult(
            attemptId: 'attempt-1',
            result: const ProviderDeliveryResult.undetermined(
              safeCode: 'PROVIDER_TIMEOUT_AGAIN',
            ),
            completedAt: startedAt.add(const Duration(seconds: 4)),
          ),
          throwsA(isA<BusinessRuleValidationException>()),
        );

        expect(delivery.status, DeliveryStatus.unknown);
        expect(delivery.latestAttempt!.status, DeliveryAttemptStatus.unknown);
        expect(delivery.attempts, hasLength(1));
      },
    );

    test('retryable failure queues next attempt up to max three', () {
      final delivery = startInitial();

      delivery.markAttemptSubmitted(
        attemptId: 'attempt-1',
        providerInteractionReference: 'interaction-1',
        providerRequestReference: 'request-1',
        submittedAt: startedAt.add(const Duration(seconds: 1)),
      );
      delivery.applyProviderResult(
        attemptId: 'attempt-1',
        result: const ProviderDeliveryResult.retryableFailure(
          safeCode: 'PROVIDER_THROTTLED',
        ),
        completedAt: startedAt.add(const Duration(seconds: 2)),
        nextAttemptId: 'attempt-2',
      );
      expect(delivery.status, DeliveryStatus.processing);
      expect(delivery.attempts, hasLength(2));

      delivery.markAttemptSubmitted(
        attemptId: 'attempt-2',
        providerInteractionReference: 'interaction-2',
        providerRequestReference: 'request-2',
        submittedAt: startedAt.add(const Duration(seconds: 3)),
      );
      delivery.applyProviderResult(
        attemptId: 'attempt-2',
        result: const ProviderDeliveryResult.retryableFailure(
          safeCode: 'PROVIDER_THROTTLED',
        ),
        completedAt: startedAt.add(const Duration(seconds: 4)),
        nextAttemptId: 'attempt-3',
      );
      expect(delivery.attempts, hasLength(3));

      delivery.markAttemptSubmitted(
        attemptId: 'attempt-3',
        providerInteractionReference: 'interaction-3',
        providerRequestReference: 'request-3',
        submittedAt: startedAt.add(const Duration(seconds: 5)),
      );
      delivery.applyProviderResult(
        attemptId: 'attempt-3',
        result: const ProviderDeliveryResult.retryableFailure(
          safeCode: 'PROVIDER_THROTTLED',
        ),
        completedAt: startedAt.add(const Duration(seconds: 6)),
      );

      expect(delivery.attempts, hasLength(3));
      expect(delivery.status, DeliveryStatus.failed);
      expect(delivery.latestAttempt!.status, DeliveryAttemptStatus.failed);
      expect(
        delivery.domainEvents,
        contains(isA<InvoiceDeliveryFailedDomainEvent>()),
      );
    });

    test('pre-dispatch queued attempt may fail without submission', () {
      final delivery = startInitial();
      delivery.applyProviderResult(
        attemptId: 'attempt-1',
        result: const ProviderDeliveryResult.definiteFailure(
          safeCode: 'WORKER_DEAD_LETTER',
        ),
        completedAt: startedAt.add(const Duration(seconds: 1)),
      );

      expect(delivery.status, DeliveryStatus.failed);
      expect(delivery.latestAttempt!.status, DeliveryAttemptStatus.failed);
    });

    test('undetermined does not enqueue another attempt', () {
      final delivery = startInitial();
      delivery.markAttemptSubmitted(
        attemptId: 'attempt-1',
        providerInteractionReference: 'interaction-1',
        providerRequestReference: 'request-1',
        submittedAt: startedAt.add(const Duration(seconds: 1)),
      );
      delivery.applyProviderResult(
        attemptId: 'attempt-1',
        result: const ProviderDeliveryResult.undetermined(
          safeCode: 'PROVIDER_TIMEOUT',
        ),
        completedAt: startedAt.add(const Duration(seconds: 2)),
        nextAttemptId: 'attempt-2',
      );

      expect(delivery.attempts, hasLength(1));
      expect(delivery.status, DeliveryStatus.unknown);
    });
  });
}
