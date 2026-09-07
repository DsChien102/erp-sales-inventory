final class StoredInvoiceDocumentDto {
  const StoredInvoiceDocumentDto({
    required this.storageReference,
    required this.checksum,
    required this.contentType,
    required this.fileName,
    required this.fileSize,
  });

  final String storageReference;
  final String checksum;
  final String contentType;
  final String fileName;
  final int fileSize;
}
