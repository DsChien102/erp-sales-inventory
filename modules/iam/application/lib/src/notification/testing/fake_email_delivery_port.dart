import '../ports/i_email_delivery_port.dart';
import '../shared/email_delivery_outcome_dto.dart';
import '../shared/email_delivery_status.dart';
import '../shared/enqueue_email_delivery_request.dart';

/// Named fake scenarios from harness/07-api-contracts.md §S-NOTIFY.
enum FakeEmailDeliveryScenario {
  notifyQueuedOk,
  notifySentOk,
  notifyFailed,
  notifyRateLimited,
}

/// In-memory [IEmailDeliveryPort] for FE/BE unit tests without Resend/network.
///
/// Simulates the side effect of a mutation RPC that would call
/// `enqueue_outbox_message` + record queued outcome — not a Dart outbox writer.
final class FakeEmailDeliveryPort implements IEmailDeliveryPort {
  FakeEmailDeliveryPort({
    this.scenario = FakeEmailDeliveryScenario.notifyQueuedOk,
  });

  FakeEmailDeliveryScenario scenario;

  final List<EnqueueEmailDeliveryRequest> enqueued =
      <EnqueueEmailDeliveryRequest>[];

  final Map<String, EmailDeliveryOutcomeDto> _byCorrelation =
      <String, EmailDeliveryOutcomeDto>{};

  int _seq = 0;

  @override
  Future<EmailDeliveryOutcomeDto> enqueue(
    EnqueueEmailDeliveryRequest request,
  ) async {
    enqueued.add(request);
    final id = 'email-outcome-${++_seq}';

    final EmailDeliveryStatus status;
    String? providerMessageId;
    String? error;

    switch (scenario) {
      case FakeEmailDeliveryScenario.notifyQueuedOk:
        status = EmailDeliveryStatus.queued;
      case FakeEmailDeliveryScenario.notifySentOk:
        status = EmailDeliveryStatus.sent;
        providerMessageId = 're_fake_$_seq';
      case FakeEmailDeliveryScenario.notifyFailed:
        status = EmailDeliveryStatus.failed;
        error = 'resend_5xx';
      case FakeEmailDeliveryScenario.notifyRateLimited:
        status = EmailDeliveryStatus.failed;
        error = 'resend_429_rate_limited';
    }

    final outcome = EmailDeliveryOutcomeDto(
      id: id,
      tenantId: request.tenantId,
      templateId: request.templateId,
      status: status,
      correlationId: request.correlationId,
      provider: EmailDeliveryConstants.providerResend,
      providerMessageId: providerMessageId,
      error: error,
      toEmailMasked: _maskEmail(request.toEmail),
    );
    _byCorrelation[request.correlationId] = outcome;
    return outcome;
  }

  @override
  Future<EmailDeliveryOutcomeDto?> getOutcomeByCorrelationId(
    String correlationId,
  ) async {
    return _byCorrelation[correlationId];
  }

  static String _maskEmail(String email) {
    final at = email.indexOf('@');
    if (at <= 1) {
      return '***';
    }
    return '${email[0]}***${email.substring(at)}';
  }
}
