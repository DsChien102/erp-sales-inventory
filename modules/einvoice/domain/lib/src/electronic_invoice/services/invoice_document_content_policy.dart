import '../enums/invoice_document_type.dart';

/// Validates downloaded invoice document bytes before storage.
abstract final class InvoiceDocumentContentPolicy {
  const InvoiceDocumentContentPolicy._();

  static const maxBytes = 20 * 1024 * 1024;

  static String? validate({
    required InvoiceDocumentType type,
    required List<int> bytes,
  }) {
    if (bytes.isEmpty || bytes.length > maxBytes) {
      return 'DOCUMENT_CONTENT_INVALID';
    }
    return switch (type) {
      InvoiceDocumentType.pdf =>
        bytes.length >= 5 && String.fromCharCodes(bytes.take(5)) == '%PDF-'
            ? null
            : 'DOCUMENT_CONTENT_INVALID',
      InvoiceDocumentType.xml => _looksLikeXml(bytes) ? null : 'DOCUMENT_CONTENT_INVALID',
    };
  }

  static bool isZip(List<int> bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0x50 &&
        bytes[1] == 0x4B &&
        bytes[2] == 0x03 &&
        bytes[3] == 0x04;
  }

  static bool _looksLikeXml(List<int> bytes) {
    if (bytes.isEmpty) return false;

    // ZIP archive container support (MISA may package XML invoice into zip)
    if (isZip(bytes)) {
      return true;
    }

    var offset = 0;
    // Strip UTF-8 BOM: EF BB BF
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      offset = 3;
    } else if (bytes.length >= 2 &&
        ((bytes[0] == 0xFE && bytes[1] == 0xFF) ||
            (bytes[0] == 0xFF && bytes[1] == 0xFE))) {
      // Strip UTF-16 BOM
      offset = 2;
    }

    // Skip leading whitespace (space, tab, CR, LF, null)
    while (offset < bytes.length &&
        (bytes[offset] == 0x20 ||
            bytes[offset] == 0x09 ||
            bytes[offset] == 0x0D ||
            bytes[offset] == 0x0A ||
            bytes[offset] == 0x00)) {
      offset++;
    }

    if (offset >= bytes.length) return false;

    // XML starts with '<' (ASCII 0x3C)
    return bytes[offset] == 0x3C;
  }
}
