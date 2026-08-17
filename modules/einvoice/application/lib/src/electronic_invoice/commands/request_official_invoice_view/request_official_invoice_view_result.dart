final class OfficialInvoiceViewDto {
  const OfficialInvoiceViewDto({
    this.viewerUrl, this.token, this.expiresAt,
  });

  final String? viewerUrl;
  final String? token;
  final DateTime? expiresAt;
}
