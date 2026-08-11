import 'package:vet45_iam_application/application.dart';

/// Production adapter: read email delivery outcomes only.
///
/// Outbox enqueue (`iam.email.delivery_requested`) happens inside mutation RPC
/// via `enqueue_outbox_message` — not from Dart. Use [FakeEmailDeliveryPort]
/// in FE/unit tests to simulate the RPC side effect.
final class SupabaseEmailDeliveryPort implements IEmailDeliveryPort {
  SupabaseEmailDeliveryPort({required IEmailDeliveryOutcomeStore outcomes})
    : _outcomes = outcomes;

  final IEmailDeliveryOutcomeStore _outcomes;

  @override
  Future<EmailDeliveryOutcomeDto> enqueue(EnqueueEmailDeliveryRequest request) {
    throw UnsupportedError(
      'Email outbox enqueue belongs in mutation RPC '
      '(iam.enqueue_outbox_message + optional queued outcome). '
      'Do not call IEmailDeliveryPort.enqueue from Dart production code; '
      'use FakeEmailDeliveryPort in tests.',
    );
  }

  @override
  Future<EmailDeliveryOutcomeDto?> getOutcomeByCorrelationId(
    String correlationId,
  ) {
    return _outcomes.getByCorrelationId(correlationId);
  }
}
