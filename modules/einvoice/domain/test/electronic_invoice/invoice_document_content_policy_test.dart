import 'package:vet45_einvoice_domain/domain.dart';
import 'package:test/test.dart';

void main() {
  test('accepts PDF signature and rejects empty or non-PDF bytes', () {
    expect(
      InvoiceDocumentContentPolicy.validate(
        type: InvoiceDocumentType.pdf,
        bytes: const [0x25, 0x50, 0x44, 0x46, 0x2D],
      ),
      isNull,
    );
    expect(
      InvoiceDocumentContentPolicy.validate(
        type: InvoiceDocumentType.pdf,
        bytes: const [1, 2, 3],
      ),
      'DOCUMENT_CONTENT_INVALID',
    );
  });

  test('accepts XML prefix and rejects empty bytes', () {
    expect(
      InvoiceDocumentContentPolicy.validate(
        type: InvoiceDocumentType.xml,
        bytes: '<?xml version="1.0"?>'.codeUnits,
      ),
      isNull,
    );
    expect(
      InvoiceDocumentContentPolicy.validate(
        type: InvoiceDocumentType.xml,
        bytes: const [0xEF, 0xBB, 0xBF, ...[0x3C, 0x3F, 0x78, 0x6D, 0x6C]],
      ),
      isNull,
      reason: 'accepts UTF-8 BOM before XML declaration',
    );
    expect(
      InvoiceDocumentContentPolicy.validate(
        type: InvoiceDocumentType.xml,
        bytes: '\r\n   <HDon>'.codeUnits,
      ),
      isNull,
      reason: 'accepts leading whitespace before XML root tag',
    );
    expect(
      InvoiceDocumentContentPolicy.validate(
        type: InvoiceDocumentType.xml,
        bytes: const [0x50, 0x4B, 0x03, 0x04, 0x00, 0x00],
      ),
      isNull,
      reason: 'accepts ZIP archive container',
    );
    expect(
      InvoiceDocumentContentPolicy.validate(
        type: InvoiceDocumentType.xml,
        bytes: const [],
      ),
      'DOCUMENT_CONTENT_INVALID',
    );
  });
}
