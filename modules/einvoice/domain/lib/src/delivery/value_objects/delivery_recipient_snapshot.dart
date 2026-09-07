import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../enums/delivery_recipient_source.dart';
import 'delivery_recipient_email.dart';

/// Immutable recipient captured at delivery start.
final class DeliveryRecipientSnapshot extends ValueObject {
  DeliveryRecipientSnapshot({
    required this.toEmail,
    required this.source,
    this.ccEmails = const [],
    this.recipientName,
    this.messageReference,
    this.schemaVersion = '1',
  });

  final DeliveryRecipientEmail toEmail;
  final DeliveryRecipientSource source;
  final List<DeliveryRecipientEmail> ccEmails;
  final String? recipientName;
  final String? messageReference;
  final String schemaVersion;

  @override
  List<Object?> get props => [
    toEmail,
    source,
    ccEmails,
    recipientName,
    messageReference,
    schemaVersion,
  ];
}
