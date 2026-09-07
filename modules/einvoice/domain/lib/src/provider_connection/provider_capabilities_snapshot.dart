import 'package:equatable/equatable.dart';

import '../electronic_invoice/enums/invoice_document_type.dart';
import '../issuance_profile/provider_template_ref.dart';

/// Embedded capability snapshot from provider sync (replaceable on sync).
final class ProviderCapabilitiesSnapshot extends Equatable {
  const ProviderCapabilitiesSnapshot({
    required this.supportsEmailDelivery,
    required this.templateCount,
    this.templates = const [],
    this.syncedAt,
    this.supportedDocumentTypes = const {},
    this.supportsDeliveryResultObservation = false,
    this.supportsPreview = false,
  });

  final bool supportsEmailDelivery;
  final int templateCount;
  final List<ProviderTemplateRef> templates;
  final DateTime? syncedAt;
  final Set<InvoiceDocumentType> supportedDocumentTypes;

  /// Fail-closed: current MISA never advertises delivery-result observation.
  final bool supportsDeliveryResultObservation;

  /// Fail-closed until capability sync advertises unpublished preview support.
  final bool supportsPreview;

  bool supports(InvoiceDocumentType type) => supportedDocumentTypes.contains(type);

  ProviderCapabilitiesSnapshot copyWith({
    bool? supportsEmailDelivery,
    int? templateCount,
    List<ProviderTemplateRef>? templates,
    DateTime? syncedAt,
    Set<InvoiceDocumentType>? supportedDocumentTypes,
    bool? supportsDeliveryResultObservation,
    bool? supportsPreview,
  }) {
    return ProviderCapabilitiesSnapshot(
      supportsEmailDelivery: supportsEmailDelivery ?? this.supportsEmailDelivery,
      templateCount: templateCount ?? this.templateCount,
      templates: templates ?? this.templates,
      syncedAt: syncedAt ?? this.syncedAt,
      supportedDocumentTypes: supportedDocumentTypes ?? this.supportedDocumentTypes,
      supportsDeliveryResultObservation:
          supportsDeliveryResultObservation ?? this.supportsDeliveryResultObservation,
      supportsPreview: supportsPreview ?? this.supportsPreview,
    );
  }

  @override
  List<Object?> get props => [
    supportsEmailDelivery,
    templateCount,
    templates,
    syncedAt,
    supportedDocumentTypes,
    supportsDeliveryResultObservation,
    supportsPreview,
  ];
}
