final class InvoicePreviewResultDto {
  const InvoicePreviewResultDto({
    this.viewerRef,
    this.failureCode,
    required this.warnings,
  });

  final String? viewerRef;

  /// Mã lỗi khi bản xem trước thất bại (vd. `PROVIDER_REJECTED_INVOICE_DATA`).
  /// Màn hình chưa hiển thị — việc phát sinh.
  final String? failureCode;
  final List<String> warnings;
}
