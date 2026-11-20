import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/catalog/presentation.dart';

void main() {
  group('ProductImageDisplayResolver', () {
    test('detects upload signed URLs', () {
      const url =
          'https://example.supabase.co/storage/v1/object/upload/sign/'
          'catalog-product-images/tenant/staging/slot/original.jpg?token=abc';

      expect(ProductImageDisplayResolver.isUploadSignedUrl(url), isTrue);
    });

    test('extracts storage key from upload signed URL', () {
      const url =
          'https://example.supabase.co/storage/v1/object/upload/sign/'
          'catalog-product-images/0a8c52ed/staging/1a6c2a40/original.jpg?token=abc';

      expect(
        ProductImageDisplayResolver.extractStorageKeyFromSupabaseUrl(url),
        '0a8c52ed/staging/1a6c2a40/original.jpg',
      );
    });

    test('normalizes plain storage key references', () {
      expect(
        ProductImageDisplayResolver.normalizeToStorageKey(
          'tenant-1/staging/slot-1/original.jpeg',
        ),
        'tenant-1/staging/slot-1/original.jpeg',
      );
    });

    test('passes through permanent CDN URLs', () {
      const cdn = 'https://cdn.fake/image-1.webp';

      expect(ProductImageDisplayResolver.normalizeToStorageKey(cdn), isNull);
    });
  });
}
