import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_catalog_infrastructure/src/configuration/processing/generated/catalog_access_metadata.g.dart';

void main() {
  group('catalogAccessMetadataRegistry', () {
    test('maps create product command to catalog.product.create', () {
      final metadata = catalogAccessMetadataRegistry.forType(
        CreateProductCommand,
      );

      expect(metadata?.permission, CatalogPermissions.create);
      expect(metadata?.requiresTenant, isTrue);
    });

    test('maps check duplicate query to catalog.product.create', () {
      final metadata = catalogAccessMetadataRegistry.forType(
        CheckDuplicateProductCodeQuery,
      );

      expect(metadata?.permission, CatalogPermissions.create);
      expect(metadata?.requiresTenant, isTrue);
    });
  });
}
