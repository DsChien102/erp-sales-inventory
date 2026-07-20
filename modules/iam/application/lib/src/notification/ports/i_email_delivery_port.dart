import '../shared/email_delivery_outcome_dto.dart';
import '../shared/enqueue_email_delivery_request.dart';

/// Application port for email delivery **outcome** projection and test doubles.
///
/// Production path: mutation RPC enqueues outbox (`enqueue_outbox_message`) and
/// may record `queued` outcome in the same transaction. Dart never calls
/// `enqueue_outbox_message` directly.
///
/// [enqueue] is implemented by [FakeEmailDeliveryPort] for FE/unit scenarios;
/// the production adapter throws if called.
abstract interface class IEmailDeliveryPort {
  /// Test-double / Fake only — simulates RPC side effect (queued/sent/failed).
  Future<EmailDeliveryOutcomeDto> enqueue(EnqueueEmailDeliveryRequest request);

  /// Latest outcome for [correlationId], if any.
  Future<EmailDeliveryOutcomeDto?> getOutcomeByCorrelationId(
    String correlationId,
  );
}
