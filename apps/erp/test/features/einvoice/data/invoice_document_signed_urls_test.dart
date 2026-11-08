import 'package:erp/features/einvoice/data/invoice_document_signed_urls.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

class _FakeStorageFileApi implements StorageFileApi {
  Future<String> Function(String path, int expiresIn)? onCreateSignedUrl;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #createSignedUrl) {
      final path = invocation.positionalArguments[0] as String;
      final expiresIn = invocation.positionalArguments[1] as int;
      if (onCreateSignedUrl != null) {
        return onCreateSignedUrl!(path, expiresIn);
      }
      return Future.value('https://signed.url/$path');
    }
    return super.noSuchMethod(invocation);
  }
}

class _FakeStorageClient implements SupabaseStorageClient {
  _FakeStorageClient(this.fileApi);

  final _FakeStorageFileApi fileApi;
  String? fromBucket;

  @override
  StorageFileApi from(String id) {
    fromBucket = id;
    return fileApi;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('tryCreate returns signed url when storage succeeds', () async {
    final fileApi = _FakeStorageFileApi();
    final client = _FakeStorageClient(fileApi);
    final signedUrls = InvoiceDocumentSignedUrls(storage: client, ttlSeconds: 300);

    final url = await signedUrls.tryCreate('path/to/invoice.pdf');

    expect(url, 'https://signed.url/path/to/invoice.pdf');
    expect(client.fromBucket, 'einvoice-documents');
  });

  test('tryCreate returns null when storage throws StorageException or Exception', () async {
    final fileApi = _FakeStorageFileApi()
      ..onCreateSignedUrl = (p, exp) => Future.error(const StorageException('not found', statusCode: '404'));
    final client = _FakeStorageClient(fileApi);
    final signedUrls = InvoiceDocumentSignedUrls(storage: client);

    final url = await signedUrls.tryCreate('path/to/missing.pdf');
    expect(url, isNull);
  });

  test('leaseExpiresAt adds ttlSeconds to now', () {
    final fileApi = _FakeStorageFileApi();
    final client = _FakeStorageClient(fileApi);
    final signedUrls = InvoiceDocumentSignedUrls(storage: client, ttlSeconds: 300);
    final now = DateTime.utc(2026, 11, 8, 12, 0, 0);

    expect(
      signedUrls.leaseExpiresAt(now: now),
      DateTime.utc(2026, 11, 8, 12, 5, 0),
    );
  });
}
