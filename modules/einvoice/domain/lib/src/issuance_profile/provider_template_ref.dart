import 'package:equatable/equatable.dart';

import 'invoice_series_classification.dart';

/// Reference to a provider invoice template.
final class ProviderTemplateRef extends Equatable {
  const ProviderTemplateRef({
    required this.templateId,
    required this.name,
    required this.invoiceSeries,
    required this.invoiceWithCode,
    required this.isMtt,
    required this.isSendSummary,
    this.serial,
    this.isAvailable = true,
  });

  /// Builds a template ref by classifying [invoiceSeries]. Throws if malformed.
  factory ProviderTemplateRef.create({
    required String templateId,
    required String name,
    required String invoiceSeries,
    required bool isSendSummary,
    String? serial,
    bool isAvailable = true,
  }) {
    final classification = InvoiceSeriesClassification.tryParse(invoiceSeries);
    if (classification == null) {
      throw ArgumentError.value(
        invoiceSeries,
        'invoiceSeries',
        'malformed InvSeries',
      );
    }
    return ProviderTemplateRef(
      templateId: templateId,
      name: name,
      invoiceSeries: invoiceSeries.trim(),
      invoiceWithCode: classification.invoiceWithCode,
      isMtt: classification.isMtt,
      isSendSummary: isSendSummary,
      serial: serial,
      isAvailable: isAvailable,
    );
  }

  /// Prefer [tryCreate] when ingesting provider payloads that may be malformed.
  static ProviderTemplateRef? tryCreate({
    required String templateId,
    required String name,
    required String invoiceSeries,
    required bool isSendSummary,
    String? serial,
    bool isAvailable = true,
  }) {
    try {
      return ProviderTemplateRef.create(
        templateId: templateId,
        name: name,
        invoiceSeries: invoiceSeries,
        isSendSummary: isSendSummary,
        serial: serial,
        isAvailable: isAvailable,
      );
    } on ArgumentError {
      return null;
    }
  }

  /// First occurrence of each `invoiceSeries` wins; order preserved.
  static List<ProviderTemplateRef> mergeAndDedupe(
    Iterable<ProviderTemplateRef> templates,
  ) {
    final seenSeries = <String>{};
    final result = <ProviderTemplateRef>[];
    for (final template in templates) {
      if (seenSeries.add(template.invoiceSeries)) {
        result.add(template);
      }
    }
    return List<ProviderTemplateRef>.unmodifiable(result);
  }

  final String templateId;
  final String name;

  /// MISA `InvSeries` (e.g. `1C26TYY`).
  final String invoiceSeries;
  final bool invoiceWithCode;
  final bool isMtt;
  final bool isSendSummary;
  final String? serial;
  final bool isAvailable;

  /// Legacy UI / DTO alias for [invoiceSeries].
  String? get symbol => invoiceSeries.isEmpty ? null : invoiceSeries;

  @override
  List<Object?> get props => [
    templateId,
    name,
    invoiceSeries,
    invoiceWithCode,
    isMtt,
    isSendSummary,
    serial,
    isAvailable,
  ];
}
