import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_application/testing.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  group('FakeCatalogModule', () {
    test('guided_create_ok returns product and readiness blockers', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.guidedCreateOk,
      );

      final result = await module.executeCommandAsync(
        CreateProductCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productName: 'Amoxicillin 100ml',
          baseUnitName: 'Lọ',
        ),
      );

      expect(result.productId, startsWith('product-new-'));
      expect(result.readinessSummary.status, ReadinessStatus.incomplete);
      expect(
        result.readinessSummary.blockers.map((b) => b.code),
        contains(ReadinessBlockerCode.missingPrice),
      );
      expect(
        result.readinessSummary.blockers.map((b) => b.code),
        isNot(contains(ReadinessBlockerCode.missingBaseUnit)),
      );
    });

    test('guided_create_dup_sku throws DuplicateSkuException', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.guidedCreateDupSku,
      );

      await expectLater(
        module.executeCommandAsync(
          CreateProductCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productName: 'Thuốc A',
            sku: 'SKU-001',
          ),
        ),
        throwsA(
          isA<DuplicateSkuException>().having((e) => e.sku, 'sku', 'SKU-001'),
        ),
      );
    });

    test('guided_create_dup_barcode throws DuplicateBarcodeException', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.guidedCreateDupBarcode,
      );

      await expectLater(
        module.executeCommandAsync(
          CreateProductCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productName: 'Thuốc A',
            barcode: '8901234567890',
          ),
        ),
        throwsA(
          isA<DuplicateBarcodeException>().having(
            (e) => e.barcode,
            'barcode',
            '8901234567890',
          ),
        ),
      );
    });

    test('guided_create_missing_name throws ValidationException', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.guidedCreateMissingName,
      );

      await expectLater(
        module.executeCommandAsync(
          CreateProductCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productName: '',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('guided_create_no_images returns optional image blocker', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.guidedCreateNoImages,
      );

      final result = await module.executeCommandAsync(
        CreateProductCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productName: 'Thuốc B',
          baseUnitName: 'Hộp',
        ),
      );

      expect(result.productId, startsWith('product-new-'));
      expect(
        result.readinessSummary.blockers.map((b) => b.code),
        contains(ReadinessBlockerCode.missingImage),
      );
    });

    test('guided_create_upload_slot_ok returns upload slot', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.guidedCreateUploadSlotOk,
      );

      final result = await module.executeCommandAsync(
        RequestProductImageUploadCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          fileName: 'photo.jpg',
          contentType: 'image/jpeg',
          byteSize: 2048,
        ),
      );

      expect(result.slotId, startsWith('slot-'));
      expect(result.storageKey, contains('staging'));
      expect(result.signedUploadUrl, isNotEmpty);
    });

    test('guided_create_upload_invalid_type throws ValidationException', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.guidedCreateUploadInvalidType,
      );

      await expectLater(
        module.executeCommandAsync(
          RequestProductImageUploadCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            fileName: 'photo.gif',
            contentType: 'image/gif',
            byteSize: 1024,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test(
      'guided_create_permission_denied throws ApplicationException',
      () async {
        final module = FakeCatalogModule(
          scenario: FakeCatalogScenario.guidedCreatePermissionDenied,
        );

        await expectLater(
          module.executeCommandAsync(
            CreateProductCommand(
              tenantId: 'tenant-1',
              actorId: 'user-1',
              productName: 'Thuốc C',
            ),
          ),
          throwsA(
            isA<ApplicationException>().having(
              (e) => e.message,
              'message',
              'Permission denied',
            ),
          ),
        );
      },
    );

    test('dup sku scenario returns matches from check query', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.guidedCreateDupSku,
      );

      final matches = await module.executeQueryAsync(
        CheckDuplicateProductCodeQuery(
          tenantId: 'tenant-1',
          sku: 'SKU-001',
        ),
      );

      expect(matches, hasLength(1));
      expect(matches.single.field, ProductDuplicateField.sku);
      expect(matches.single.matchedValue, 'SKU-001');
    });

    test('ok scenario returns empty duplicate matches', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.guidedCreateOk,
      );

      final matches = await module.executeQueryAsync(
        CheckDuplicateProductCodeQuery(
          tenantId: 'tenant-1',
          sku: 'SKU-NEW',
        ),
      );

      expect(matches, isEmpty);
    });
  });

  group('CreateProductCommandValidator', () {
    final validator = CreateProductCommandValidator();

    test('rejects empty product name', () async {
      await expectLater(
        validator.validate(
          CreateProductCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productName: '   ',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('accepts minimal valid command', () async {
      await validator.validate(
        CreateProductCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productName: 'Amoxicillin 100ml',
        ),
      );
    });
  });
}
