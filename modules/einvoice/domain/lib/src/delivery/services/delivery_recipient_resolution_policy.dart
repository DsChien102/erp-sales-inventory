import '../enums/delivery_recipient_source.dart';

/// Outcome of pure recipient resolution for a delivery entry point.
final class DeliveryRecipientResolution {
  const DeliveryRecipientResolution._({
    this.email,
    this.source,
    this.skipReason,
    required this.isBlank,
  });

  const DeliveryRecipientResolution.resolved({
    required String email,
    required DeliveryRecipientSource source,
  }) : this._(email: email, source: source, isBlank: false);

  const DeliveryRecipientResolution.blank() : this._(isBlank: true);

  const DeliveryRecipientResolution.skip({required String skipReason})
    : this._(skipReason: skipReason, isBlank: false);

  final String? email;
  final DeliveryRecipientSource? source;
  final String? skipReason;
  final bool isBlank;

  bool get isResolved => email != null && source != null;

  bool get isSkip => skipReason != null;
}

/// Fixed priority matrix for delivery recipient selection (TH-08 S5).
abstract final class DeliveryRecipientResolutionPolicy {
  const DeliveryRecipientResolutionPolicy._();

  static const String invalidOrMissingEmail = 'INVALID_OR_MISSING_EMAIL';

  static DeliveryRecipientResolution resolveAutomaticInitial({
    required String? currentPartnerInvoiceEmail,
    required String? buyerInvoiceSnapshotEmail,
    required String? buyerPartnerId,
  }) {
    if (buyerPartnerId == null) {
      final snapshot = _usableEmail(buyerInvoiceSnapshotEmail);
      if (snapshot != null) {
        return DeliveryRecipientResolution.resolved(
          email: snapshot,
          source: DeliveryRecipientSource.buyerInvoiceSnapshot,
        );
      }
      return const DeliveryRecipientResolution.skip(
        skipReason: invalidOrMissingEmail,
      );
    }

    final partner = _usableEmail(currentPartnerInvoiceEmail);
    if (partner != null) {
      return DeliveryRecipientResolution.resolved(
        email: partner,
        source: DeliveryRecipientSource.currentPartnerProfile,
      );
    }

    final snapshot = _usableEmail(buyerInvoiceSnapshotEmail);
    if (snapshot != null) {
      return DeliveryRecipientResolution.resolved(
        email: snapshot,
        source: DeliveryRecipientSource.buyerInvoiceSnapshot,
      );
    }

    return const DeliveryRecipientResolution.skip(
      skipReason: invalidOrMissingEmail,
    );
  }

  static DeliveryRecipientResolution resolveManualInitialSuggestion({
    required String? currentPartnerInvoiceEmail,
    required String? lastSuccessfulPartnerDeliveryEmail,
    required String? buyerPartnerId,
    required String? lastSuccessfulDeliveryBuyerPartnerId,
  }) {
    final partner = _usableEmail(currentPartnerInvoiceEmail);
    if (partner != null) {
      return DeliveryRecipientResolution.resolved(
        email: partner,
        source: DeliveryRecipientSource.currentPartnerProfile,
      );
    }

    if (buyerPartnerId != null && buyerPartnerId == lastSuccessfulDeliveryBuyerPartnerId) {
      final history = _usableEmail(lastSuccessfulPartnerDeliveryEmail);
      if (history != null) {
        return DeliveryRecipientResolution.resolved(
          email: history,
          source: DeliveryRecipientSource.lastSuccessfulPartnerDelivery,
        );
      }
    }

    return const DeliveryRecipientResolution.blank();
  }

  static DeliveryRecipientResolution resolveManualResendSuggestion({
    required String? latestInvoiceDeliveryEmail,
  }) {
    final latest = _usableEmail(latestInvoiceDeliveryEmail);
    if (latest != null) {
      return DeliveryRecipientResolution.resolved(
        email: latest,
        source: DeliveryRecipientSource.lastInvoiceDelivery,
      );
    }
    return const DeliveryRecipientResolution.blank();
  }

  static DeliveryRecipientResolution resolveManualConfirmed({
    required String userEmail,
  }) {
    final email = _usableEmail(userEmail);
    if (email == null) {
      return const DeliveryRecipientResolution.blank();
    }
    return DeliveryRecipientResolution.resolved(
      email: email,
      source: DeliveryRecipientSource.userInput,
    );
  }

  static String? _usableEmail(String? raw) {
    if (raw == null) {
      return null;
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(trimmed)) {
      return null;
    }
    return trimmed;
  }
}
