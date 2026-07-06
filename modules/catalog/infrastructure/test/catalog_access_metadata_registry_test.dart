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
    test('maps request image upload command to catalog.product.create', () {
      final metadata = catalogAccessMetadataRegistry.forType(
        RequestProductImageUploadCommand,
      );

      expect(metadata?.permission, CatalogPermissions.create);
      expect(metadata?.requiresTenant, isTrue);
    });

    test('maps set initial stock command to manage_stock', () {
      final metadata = catalogAccessMetadataRegistry.forType(
        SetInitialStockCommand,
      );

      expect(metadata?.permission, CatalogPermissions.manageStock);
      expect(metadata?.requiresTenant, isTrue);
    });

    test('maps set manual base price command to manage_pricing', () {
      final metadata = catalogAccessMetadataRegistry.forType(
        SetManualBasePriceCommand,
      );

      expect(metadata?.permission, CatalogPermissions.managePricing);
      expect(metadata?.requiresTenant, isTrue);
    });

    test('maps set initial price band command to manage_pricing', () {
      final metadata = catalogAccessMetadataRegistry.forType(
        SetInitialPriceBandCommand,
      );

      expect(metadata?.permission, CatalogPermissions.managePricing);
      expect(metadata?.requiresTenant, isTrue);
    });
  });
}
