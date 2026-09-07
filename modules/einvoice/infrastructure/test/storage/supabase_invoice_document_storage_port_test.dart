import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_infrastructure/src/storage/invoice_document_signed_url_resolver.dart';
import 'package:vet45_einvoice_infrastructure/src/storage/supabase_invoice_document_storage_port.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../support/fake_invoice_document_storage_supabase.dart';

List<int> _pdfBytes() => '%PDF-1.4 test'.codeUnits;

void main() {
  group('SupabaseInvoiceDocumentStoragePort', () {
    test(
      'uploads to deterministic path with checksum and MIME mapping',
      () async {
        final fake = FakeInvoiceDocumentStorageSupabase();
        final port = SupabaseInvoiceDocumentStoragePort(supabase: fake);
        final bytes = _pdfBytes();
        final checksum = sha256.convert(bytes).toString();

        final stored = await port.store(
          tenantId: 'tenant-1',
          electronicInvoiceId: 'invoice-1',
          documentType: InvoiceDocumentType.pdf,
          documentVersion: 2,
          bytes: bytes,
        );

        expect(fake.bucket.lastPath, 'tenant-1/invoice-1/pdf/v2/$checksum.pdf');
        expect(fake.bucket.lastFileOptions?.upsert, isFalse);
        expect(fake.bucket.lastFileOptions?.contentType, 'application/pdf');
        expect(stored.storageReference, fake.bucket.lastPath);
        expect(stored.checksum, checksum);
        expect(stored.fileName, '$checksum.pdf');
        expect(stored.fileSize, bytes.length);
        expect(stored.contentType, 'application/pdf');
      },
    );

    test(
      'reuses existing object when deterministic path already exists',
      () async {
        final fake = FakeInvoiceDocumentStorageSupabase();
        final port = SupabaseInvoiceDocumentStoragePort(supabase: fake);
        final bytes = _pdfBytes();

        final first = await port.store(
          tenantId: 'tenant-1',
          electronicInvoiceId: 'invoice-1',
          documentType: InvoiceDocumentType.pdf,
          documentVersion: 1,
          bytes: bytes,
        );
        final second = await port.store(
          tenantId: 'tenant-1',
          electronicInvoiceId: 'invoice-1',
          documentType: InvoiceDocumentType.pdf,
          documentVersion: 1,
          bytes: bytes,
        );

        expect(second.storageReference, first.storageReference);
        expect(second.checksum, first.checksum);
      },
    );

    test('rejects invalid content before upload', () async {
      final fake = FakeInvoiceDocumentStorageSupabase();
      final port = SupabaseInvoiceDocumentStoragePort(supabase: fake);

      await expectLater(
        port.store(
          tenantId: 'tenant-1',
          electronicInvoiceId: 'invoice-1',
          documentType: InvoiceDocumentType.pdf,
          documentVersion: 1,
          bytes: [1, 2, 3],
        ),
        throwsA(isA<RpcException>()),
      );
      expect(fake.bucket.lastPath, isNull);
    });
  });

  group('InvoiceDocumentSignedUrlResolver', () {
    test('creates 300-second signed URL on read', () async {
      final fake = FakeInvoiceDocumentStorageSupabase();
      final resolver = InvoiceDocumentSignedUrlResolver(supabase: fake);

      final url = await resolver.tryCreateSignedUrl(
        'tenant-1/invoice-1/pdf/v1/a.pdf',
      );

      expect(url, contains('ttl=300'));
      expect(InvoiceDocumentSignedUrlResolver.defaultSignedUrlTtlSeconds, 300);
    });
  });
}
