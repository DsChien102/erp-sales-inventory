// ignore_for_file: implementation_imports

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/catalog/data/models/catalog_enums.dart' as app_enum;
import 'package:erp/features/catalog/data/models/product_inputs.dart' as app_in;
import 'package:erp/features/catalog/logic/catalog_rules.dart' as app_rules;
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  group('catalog_rules parity', () {
    group('old (CommandValidators)', () {
      group('CreateGuidedProductCommandValidator', () {
        final validator = CreateGuidedProductCommandValidator();

        test('fails when productName is blank', () async {
          final cmd = CreateGuidedProductCommand(
            tenantId: 't1',
            actorId: 'a1',
            productName: '  ',
          );
          expect(
            () => validator.validate(cmd),
            throwsA(
              isA<ValidationException>().having(
                (e) => e.message,
                'message',
                'Tenant, actor and product name are required.',
              ),
            ),
          );
        });

        test('fails when images count > 8', () async {
          final images = List.generate(
            9,
            (i) => ProductImageInput(storageKey: 'k$i'),
          );
          final cmd = CreateGuidedProductCommand(
            tenantId: 't1',
            actorId: 'a1',
            productName: 'P1',
            images: images,
          );
          expect(
            () => validator.validate(cmd),
            throwsA(
              isA<ValidationException>().having(
                (e) => e.message,
                'message',
                'A product can have at most 8 images.',
              ),
            ),
          );
        });

        test('fails when more than 1 primary image', () async {
          final cmd = CreateGuidedProductCommand(
            tenantId: 't1',
            actorId: 'a1',
            productName: 'P1',
            images: const [
              ProductImageInput(storageKey: 'k1', isPrimary: true),
              ProductImageInput(storageKey: 'k2', isPrimary: true),
            ],
          );
          expect(
            () => validator.validate(cmd),
            throwsA(
              isA<ValidationException>().having(
                (e) => e.message,
                'message',
                'Only one primary image is allowed.',
              ),
            ),
          );
        });

        test('fails when baseUnit ExistingTenantUnit id is empty', () async {
          final cmd = CreateGuidedProductCommand(
            tenantId: 't1',
            actorId: 'a1',
            productName: 'P1',
            baseUnit: const ExistingTenantUnit('   '),
          );
          expect(
            () => validator.validate(cmd),
            throwsA(
              isA<ValidationException>().having(
                (e) => e.message,
                'message',
                'Base unit id is required.',
              ),
            ),
          );
        });

        test('fails when baseUnit NewTenantUnit name is empty', () async {
          final cmd = CreateGuidedProductCommand(
            tenantId: 't1',
            actorId: 'a1',
            productName: 'P1',
            baseUnit: const NewTenantUnit('   '),
          );
          expect(
            () => validator.validate(cmd),
            throwsA(
              isA<ValidationException>().having(
                (e) => e.message,
                'message',
                'Base unit name is required.',
              ),
            ),
          );
        });

        test('fails when stock/price set without base unit', () async {
          final cmd = CreateGuidedProductCommand(
            tenantId: 't1',
            actorId: 'a1',
            productName: 'P1',
            basicStockQuantityBase: 10,
          );
          expect(
            () => validator.validate(cmd),
            throwsA(
              isA<ValidationException>().having(
                (e) => e.message,
                'message',
                'Cần thiết lập đơn vị cơ sở trước tồn kho hoặc giá.',
              ),
            ),
          );
        });

        test('fails when basicStockQuantityBase < 0', () async {
          final cmd = CreateGuidedProductCommand(
            tenantId: 't1',
            actorId: 'a1',
            productName: 'P1',
            baseUnit: const NewTenantUnit('Hộp'),
            basicStockQuantityBase: -1,
          );
          expect(
            () => validator.validate(cmd),
            throwsA(
              isA<ValidationException>().having(
                (e) => e.message,
                'message',
                'Số lượng tồn kho ban đầu phải là số nguyên không âm.',
              ),
            ),
          );
        });

        test('fails when basePrice < 0', () async {
          final cmd = CreateGuidedProductCommand(
            tenantId: 't1',
            actorId: 'a1',
            productName: 'P1',
            baseUnit: const NewTenantUnit('Hộp'),
            basePrice: -500,
          );
          expect(
            () => validator.validate(cmd),
            throwsA(
              isA<ValidationException>().having(
                (e) => e.message,
                'message',
                'Giá phải là số không âm.',
              ),
            ),
          );
        });

        test('fails when floorBeforeVat > listBeforeVat', () async {
          final cmd = CreateGuidedProductCommand(
            tenantId: 't1',
            actorId: 'a1',
            productName: 'P1',
            baseUnit: const NewTenantUnit('Hộp'),
            listBeforeVat: 10000,
            floorBeforeVat: 15000,
          );
          expect(
            () => validator.validate(cmd),
            throwsA(
              isA<ValidationException>().having(
                (e) => e.message,
                'message',
                'Giá sàn không được lớn hơn giá niêm yết.',
              ),
            ),
          );
        });

        test('fails when customConfig markup ratios are invalid', () async {
          final cmd = CreateGuidedProductCommand(
            tenantId: 't1',
            actorId: 'a1',
            productName: 'P1',
            baseUnit: const NewTenantUnit('Hộp'),
            priceBandSourceType: PriceBandSourceType.customConfig,
            listMarkupRatio: -0.1,
          );
          expect(
            () => validator.validate(cmd),
            throwsA(
              isA<ValidationException>().having(
                (e) => e.message,
                'message',
                'Cấu hình giá tự động riêng không hợp lệ.',
              ),
            ),
          );
        });

        test('fails when manual priceBand missing listBeforeVat', () async {
          final cmd = CreateGuidedProductCommand(
            tenantId: 't1',
            actorId: 'a1',
            productName: 'P1',
            baseUnit: const NewTenantUnit('Hộp'),
            priceBandSourceType: PriceBandSourceType.manual,
            listBeforeVat: null,
          );
          expect(
            () => validator.validate(cmd),
            throwsA(
              isA<ValidationException>().having(
                (e) => e.message,
                'message',
                'Giá niêm yết là bắt buộc.',
              ),
            ),
          );
        });

        test('fails when ruleBased priceBand without useStorePriceRule', () async {
          final cmd = CreateGuidedProductCommand(
            tenantId: 't1',
            actorId: 'a1',
            productName: 'P1',
            baseUnit: const NewTenantUnit('Hộp'),
            priceBandSourceType: PriceBandSourceType.ruleBased,
            useStorePriceRule: false,
          );
          expect(
            () => validator.validate(cmd),
            throwsA(
              isA<ValidationException>().having(
                (e) => e.message,
                'message',
                'Cần áp dụng khung giá cửa hàng.',
              ),
            ),
          );
        });

        test('fails when custom field value has duplicate fieldId', () async {
          final cmd = CreateGuidedProductCommand(
            tenantId: 't1',
            actorId: 'a1',
            productName: 'P1',
            customFieldValues: const [
              ProductCustomFieldValueInput(fieldId: 'f1', textValue: 'A'),
              ProductCustomFieldValueInput(fieldId: 'f1', textValue: 'B'),
            ],
          );
          expect(
            () => validator.validate(cmd),
            throwsA(
              isA<ValidationException>().having(
                (e) => e.message,
                'message',
                'Custom field value không hợp lệ.',
              ),
            ),
          );
        });

        test('fails when custom field value has multiple types set', () async {
          final cmd = CreateGuidedProductCommand(
            tenantId: 't1',
            actorId: 'a1',
            productName: 'P1',
            customFieldValues: const [
              ProductCustomFieldValueInput(
                fieldId: 'f1',
                textValue: 'A',
                numberValue: 12.0,
              ),
            ],
          );
          expect(
            () => validator.validate(cmd),
            throwsA(
              isA<ValidationException>().having(
                (e) => e.message,
                'message',
                'Mỗi custom field chỉ được có một kiểu giá trị.',
              ),
            ),
          );
        });

        test('succeeds for valid create guided product command', () async {
          final cmd = CreateGuidedProductCommand(
            tenantId: 't1',
            actorId: 'a1',
            productName: 'Thuốc hạ sốt',
            baseUnit: const NewTenantUnit('Hộp'),
            basicStockQuantityBase: 100,
            basePrice: 50000,
            listBeforeVat: 60000,
            floorBeforeVat: 55000,
            priceBandSourceType: PriceBandSourceType.manual,
          );
          await expectLater(validator.validate(cmd), completes);
        });
      });

      group('RequestProductImageUploadCommandValidator', () {
        final validator = RequestProductImageUploadCommandValidator();

        test('fails when fileName is empty', () async {
          final cmd = RequestProductImageUploadCommand(
            tenantId: 't1',
            actorId: 'a1',
            fileName: '   ',
            contentType: 'image/png',
            byteSize: 100,
          );
          expect(
            () => validator.validate(cmd),
            throwsA(
              isA<ValidationException>().having(
                (e) => e.message,
                'message',
                'File name is required.',
              ),
            ),
          );
        });

        test('fails when contentType is unsupported', () async {
          final cmd = RequestProductImageUploadCommand(
            tenantId: 't1',
            actorId: 'a1',
            fileName: 'pic.gif',
            contentType: 'image/gif',
            byteSize: 100,
          );
          expect(
            () => validator.validate(cmd),
            throwsA(
              isA<ValidationException>().having(
                (e) => e.message,
                'message',
                'Unsupported image content type.',
              ),
            ),
          );
        });

        test('fails when byteSize <= 0', () async {
          final cmd = RequestProductImageUploadCommand(
            tenantId: 't1',
            actorId: 'a1',
            fileName: 'pic.png',
            contentType: 'image/png',
            byteSize: 0,
          );
          expect(
            () => validator.validate(cmd),
            throwsA(
              isA<ValidationException>().having(
                (e) => e.message,
                'message',
                'Image byte size must be positive.',
              ),
            ),
          );
        });

        test('fails when byteSize > 10MB', () async {
          final cmd = RequestProductImageUploadCommand(
            tenantId: 't1',
            actorId: 'a1',
            fileName: 'pic.png',
            contentType: 'image/png',
            byteSize: 10 * 1024 * 1024 + 1,
          );
          expect(
            () => validator.validate(cmd),
            throwsA(
              isA<ValidationException>().having(
                (e) => e.message,
                'message',
                'Image exceeds maximum allowed size.',
              ),
            ),
          );
        });

        test('succeeds for valid image upload request', () async {
          final cmd = RequestProductImageUploadCommand(
            tenantId: 't1',
            actorId: 'a1',
            fileName: 'pic.jpg',
            contentType: 'image/jpeg',
            byteSize: 1024 * 500,
          );
          await expectLater(validator.validate(cmd), completes);
        });
      });

      group('UpdateProductProfileCommandValidator', () {
        final validator = UpdateProductProfileCommandValidator();

        test('fails when productName is blank', () async {
          final cmd = UpdateProductProfileCommand(
            tenantId: 't1',
            actorId: 'a1',
            productId: 'p1',
            productName: '  ',
          );
          expect(
            () => validator.validate(cmd),
            throwsA(
              isA<ValidationException>().having(
                (e) => e.message,
                'message',
                'Product name is required.',
              ),
            ),
          );
        });

        test('fails when expectedVersion <= 0', () async {
          final cmd = UpdateProductProfileCommand(
            tenantId: 't1',
            actorId: 'a1',
            productId: 'p1',
            productName: 'Paracetamol',
            expectedVersion: 0,
          );
          expect(
            () => validator.validate(cmd),
            throwsA(
              isA<ValidationException>().having(
                (e) => e.message,
                'message',
                'Expected version must be positive.',
              ),
            ),
          );
        });

        test('succeeds for valid update profile command', () async {
          final cmd = UpdateProductProfileCommand(
            tenantId: 't1',
            actorId: 'a1',
            productId: 'p1',
            productName: 'Paracetamol 500mg',
            expectedVersion: 2,
          );
          await expectLater(validator.validate(cmd), completes);
        });
      });

      group('UpdateProductImagesCommandValidator', () {
        final validator = UpdateProductImagesCommandValidator();

        test('fails when expectedVersion <= 0', () async {
          final cmd = UpdateProductImagesCommand(
            tenantId: 't1',
            actorId: 'a1',
            productId: 'p1',
            expectedVersion: -1,
            images: const [],
          );
          expect(
            () => validator.validate(cmd),
            throwsA(
              isA<ValidationException>().having(
                (e) => e.message,
                'message',
                'Expected version must be positive.',
              ),
            ),
          );
        });

        test('fails when more than 1 primary image', () async {
          final cmd = UpdateProductImagesCommand(
            tenantId: 't1',
            actorId: 'a1',
            productId: 'p1',
            expectedVersion: 1,
            images: const [
              ProductImageMutationInput(storageKey: 'k1', isPrimary: true),
              ProductImageMutationInput(storageKey: 'k2', isPrimary: true),
            ],
          );
          expect(
            () => validator.validate(cmd),
            throwsA(
              isA<ValidationException>().having(
                (e) => e.message,
                'message',
                'A product may have at most one primary image.',
              ),
            ),
          );
        });

        test('fails when storageKey is blank', () async {
          final cmd = UpdateProductImagesCommand(
            tenantId: 't1',
            actorId: 'a1',
            productId: 'p1',
            expectedVersion: 1,
            images: const [
              ProductImageMutationInput(storageKey: '   '),
            ],
          );
          expect(
            () => validator.validate(cmd),
            throwsA(
              isA<ValidationException>().having(
                (e) => e.message,
                'message',
                'Image storage key is required.',
              ),
            ),
          );
        });

        test('succeeds for valid update images command', () async {
          final cmd = UpdateProductImagesCommand(
            tenantId: 't1',
            actorId: 'a1',
            productId: 'p1',
            expectedVersion: 1,
            images: const [
              ProductImageMutationInput(storageKey: 'key_1', isPrimary: true),
            ],
          );
          await expectLater(validator.validate(cmd), completes);
        });
      });
    });

    group('new (catalog_rules)', () {
      group('checkCreateGuided', () {
        test('fails when productName is blank', () {
          const input = app_in.CreateGuidedProductInput(productName: '  ');
          expect(
            () => app_rules.checkCreateGuided(input),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having((e) => e.serverMessage, 'serverMessage', 'Tenant, actor and product name are required.'),
            ),
          );
        });

        test('fails when images count > 8', () {
          final images = List.generate(9, (i) => app_in.ProductImageInput(storageKey: 'k$i'));
          final input = app_in.CreateGuidedProductInput(productName: 'P1', images: images);
          expect(
            () => app_rules.checkCreateGuided(input),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having((e) => e.serverMessage, 'serverMessage', 'A product can have at most 8 images.'),
            ),
          );
        });

        test('fails when more than 1 primary image', () {
          const input = app_in.CreateGuidedProductInput(
            productName: 'P1',
            images: [
              app_in.ProductImageInput(storageKey: 'k1', isPrimary: true),
              app_in.ProductImageInput(storageKey: 'k2', isPrimary: true),
            ],
          );
          expect(
            () => app_rules.checkCreateGuided(input),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having((e) => e.serverMessage, 'serverMessage', 'Only one primary image is allowed.'),
            ),
          );
        });

        test('fails when baseUnit ExistingTenantUnit id is empty', () {
          const input = app_in.CreateGuidedProductInput(
            productName: 'P1',
            baseUnit: app_in.ExistingTenantUnit('   '),
          );
          expect(
            () => app_rules.checkCreateGuided(input),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having((e) => e.serverMessage, 'serverMessage', 'Base unit id is required.'),
            ),
          );
        });

        test('fails when baseUnit NewTenantUnit name is empty', () {
          const input = app_in.CreateGuidedProductInput(
            productName: 'P1',
            baseUnit: app_in.NewTenantUnit('   '),
          );
          expect(
            () => app_rules.checkCreateGuided(input),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having((e) => e.serverMessage, 'serverMessage', 'Base unit name is required.'),
            ),
          );
        });

        test('fails when stock/price set without base unit', () {
          const input = app_in.CreateGuidedProductInput(
            productName: 'P1',
            basicStockQuantityBase: 10,
          );
          expect(
            () => app_rules.checkCreateGuided(input),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Cần thiết lập đơn vị cơ sở trước tồn kho hoặc giá.',
                  ),
            ),
          );
        });

        test('fails when basicStockQuantityBase < 0', () {
          const input = app_in.CreateGuidedProductInput(
            productName: 'P1',
            baseUnit: app_in.NewTenantUnit('Hộp'),
            basicStockQuantityBase: -1,
          );
          expect(
            () => app_rules.checkCreateGuided(input),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Số lượng tồn kho ban đầu phải là số nguyên không âm.',
                  ),
            ),
          );
        });

        test('fails when basePrice < 0', () {
          const input = app_in.CreateGuidedProductInput(
            productName: 'P1',
            baseUnit: app_in.NewTenantUnit('Hộp'),
            basePrice: -500,
          );
          expect(
            () => app_rules.checkCreateGuided(input),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having((e) => e.serverMessage, 'serverMessage', 'Giá phải là số không âm.'),
            ),
          );
        });

        test('fails when floorBeforeVat > listBeforeVat', () {
          const input = app_in.CreateGuidedProductInput(
            productName: 'P1',
            baseUnit: app_in.NewTenantUnit('Hộp'),
            listBeforeVat: 10000,
            floorBeforeVat: 15000,
          );
          expect(
            () => app_rules.checkCreateGuided(input),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having((e) => e.serverMessage, 'serverMessage', 'Giá sàn không được lớn hơn giá niêm yết.'),
            ),
          );
        });

        test('fails when customConfig markup ratios are invalid', () {
          final input = app_in.CreateGuidedProductInput(
            productName: 'P1',
            baseUnit: const app_in.NewTenantUnit('Hộp'),
            priceBandSourceType: app_enum.PriceBandSourceType.customConfig,
            listMarkupRatio: -0.1,
          );
          expect(
            () => app_rules.checkCreateGuided(input),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Cấu hình giá tự động riêng không hợp lệ.',
                  ),
            ),
          );
        });

        test('fails when manual priceBand missing listBeforeVat', () {
          final input = app_in.CreateGuidedProductInput(
            productName: 'P1',
            baseUnit: const app_in.NewTenantUnit('Hộp'),
            priceBandSourceType: app_enum.PriceBandSourceType.manual,
            listBeforeVat: null,
          );
          expect(
            () => app_rules.checkCreateGuided(input),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having((e) => e.serverMessage, 'serverMessage', 'Giá niêm yết là bắt buộc.'),
            ),
          );
        });

        test('fails when ruleBased priceBand without useStorePriceRule', () {
          final input = app_in.CreateGuidedProductInput(
            productName: 'P1',
            baseUnit: const app_in.NewTenantUnit('Hộp'),
            priceBandSourceType: app_enum.PriceBandSourceType.ruleBased,
            useStorePriceRule: false,
          );
          expect(
            () => app_rules.checkCreateGuided(input),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having((e) => e.serverMessage, 'serverMessage', 'Cần áp dụng khung giá cửa hàng.'),
            ),
          );
        });

        test('fails when custom field value has duplicate fieldId', () {
          const input = app_in.CreateGuidedProductInput(
            productName: 'P1',
            customFieldValues: [
              app_in.ProductCustomFieldValueInput(fieldId: 'f1', textValue: 'A'),
              app_in.ProductCustomFieldValueInput(fieldId: 'f1', textValue: 'B'),
            ],
          );
          expect(
            () => app_rules.checkCreateGuided(input),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having((e) => e.serverMessage, 'serverMessage', 'Custom field value không hợp lệ.'),
            ),
          );
        });

        test('fails when custom field value has multiple types set', () {
          const input = app_in.CreateGuidedProductInput(
            productName: 'P1',
            customFieldValues: [
              app_in.ProductCustomFieldValueInput(
                fieldId: 'f1',
                textValue: 'A',
                numberValue: 12.0,
              ),
            ],
          );
          expect(
            () => app_rules.checkCreateGuided(input),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Mỗi custom field chỉ được có một kiểu giá trị.',
                  ),
            ),
          );
        });

        test('succeeds for valid create guided product input', () {
          final input = app_in.CreateGuidedProductInput(
            productName: 'Thuốc hạ sốt',
            baseUnit: const app_in.NewTenantUnit('Hộp'),
            basicStockQuantityBase: 100,
            basePrice: 50000,
            listBeforeVat: 60000,
            floorBeforeVat: 55000,
            priceBandSourceType: app_enum.PriceBandSourceType.manual,
          );
          expect(() => app_rules.checkCreateGuided(input), returnsNormally);
        });
      });

      group('checkImageUploadRequest', () {
        test('fails when fileName is empty', () {
          expect(
            () => app_rules.checkImageUploadRequest(
              fileName: '   ',
              contentType: 'image/png',
              byteSize: 100,
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having((e) => e.serverMessage, 'serverMessage', 'File name is required.'),
            ),
          );
        });

        test('fails when contentType is unsupported', () {
          expect(
            () => app_rules.checkImageUploadRequest(
              fileName: 'pic.gif',
              contentType: 'image/gif',
              byteSize: 100,
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having((e) => e.serverMessage, 'serverMessage', 'Unsupported image content type.'),
            ),
          );
        });

        test('fails when byteSize <= 0', () {
          expect(
            () => app_rules.checkImageUploadRequest(
              fileName: 'pic.png',
              contentType: 'image/png',
              byteSize: 0,
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having((e) => e.serverMessage, 'serverMessage', 'Image byte size must be positive.'),
            ),
          );
        });

        test('fails when byteSize > 10MB', () {
          expect(
            () => app_rules.checkImageUploadRequest(
              fileName: 'pic.png',
              contentType: 'image/png',
              byteSize: 10 * 1024 * 1024 + 1,
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having((e) => e.serverMessage, 'serverMessage', 'Image exceeds maximum allowed size.'),
            ),
          );
        });

        test('succeeds for valid image upload request', () {
          expect(
            () => app_rules.checkImageUploadRequest(
              fileName: 'pic.jpg',
              contentType: 'image/jpeg',
              byteSize: 1024 * 500,
            ),
            returnsNormally,
          );
        });
      });

      group('checkUpdateProfile', () {
        test('fails when productName is blank', () {
          expect(
            () => app_rules.checkUpdateProfile(
              productName: '  ',
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having((e) => e.serverMessage, 'serverMessage', 'Product name is required.'),
            ),
          );
        });

        test('fails when expectedVersion <= 0', () {
          expect(
            () => app_rules.checkUpdateProfile(
              productName: 'Paracetamol',
              expectedVersion: 0,
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having((e) => e.serverMessage, 'serverMessage', 'Expected version must be positive.'),
            ),
          );
        });

        test('succeeds for valid update profile params', () {
          expect(
            () => app_rules.checkUpdateProfile(
              productName: 'Paracetamol 500mg',
              expectedVersion: 2,
            ),
            returnsNormally,
          );
        });
      });

      group('checkUpdateImages', () {
        test('fails when expectedVersion <= 0', () {
          expect(
            () => app_rules.checkUpdateImages(
              expectedVersion: -1,
              images: const [],
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having((e) => e.serverMessage, 'serverMessage', 'Expected version must be positive.'),
            ),
          );
        });

        test('fails when more than 1 primary image', () {
          expect(
            () => app_rules.checkUpdateImages(
              expectedVersion: 1,
              images: const [
                app_in.ProductImageMutationInput(storageKey: 'k1', isPrimary: true),
                app_in.ProductImageMutationInput(storageKey: 'k2', isPrimary: true),
              ],
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'A product may have at most one primary image.',
                  ),
            ),
          );
        });

        test('fails when storageKey is blank', () {
          expect(
            () => app_rules.checkUpdateImages(
              expectedVersion: 1,
              images: const [
                app_in.ProductImageMutationInput(storageKey: '   '),
              ],
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having((e) => e.serverMessage, 'serverMessage', 'Image storage key is required.'),
            ),
          );
        });

        test('succeeds for valid update images', () {
          expect(
            () => app_rules.checkUpdateImages(
              expectedVersion: 1,
              images: const [
                app_in.ProductImageMutationInput(storageKey: 'key_1', isPrimary: true),
              ],
            ),
            returnsNormally,
          );
        });
      });
    });
  });
}
