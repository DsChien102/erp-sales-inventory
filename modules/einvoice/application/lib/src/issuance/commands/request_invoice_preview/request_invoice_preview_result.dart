final class InvoicePreviewResultDto {
  const InvoicePreviewResultDto({
    this.viewerRef, this.previewPayload, required this.warnings,
  });

  final String? viewerRef;
  final Map<String, Object?>? previewPayload;
  final List<String> warnings;
}
