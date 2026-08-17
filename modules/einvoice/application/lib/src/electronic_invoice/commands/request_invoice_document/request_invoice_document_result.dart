final class InvoiceDocumentRetrievalDto {
  const InvoiceDocumentRetrievalDto({
    this.downloadUrl, this.fileRef, this.checksum,
  });

  final String? downloadUrl;
  final String? fileRef;
  final String? checksum;
}
