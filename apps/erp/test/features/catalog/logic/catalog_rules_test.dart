// ignore_for_file: implementation_imports, depend_on_referenced_packages

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/catalog/data/catalog_errors.dart';
import 'package:erp/features/catalog/data/models/catalog_enums.dart' as app_enum;
import 'package:erp/features/catalog/data/models/custom_field_config.dart' as app_cf;
import 'package:erp/features/catalog/data/models/custom_field_filter_option.dart' as app_cfo;
import 'package:erp/features/catalog/data/models/price_band.dart' as app_pb;
import 'package:erp/features/catalog/data/models/product_inputs.dart' as app_in;
import 'package:erp/features/catalog/logic/catalog_rules.dart' as app_rules;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('catalog_rules parity', () {
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

      group('checkBaseUnitSelection', () {
        test('fails when ExistingTenantUnit id is empty', () {
          expect(
            () => app_rules.checkBaseUnitSelection(
              const app_in.ExistingTenantUnit('   '),
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Measurement unit id is required.',
                  ),
            ),
          );
        });

        test('fails when NewTenantUnit name is empty', () {
          expect(
            () => app_rules.checkBaseUnitSelection(
              const app_in.NewTenantUnit('   '),
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Unit name must not be empty.',
                  ),
            ),
          );
        });

        test('fails when NewTenantUnit name > 80 chars', () {
          expect(
            () => app_rules.checkBaseUnitSelection(
              app_in.NewTenantUnit('A' * 81),
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Unit name is too long.',
                  ),
            ),
          );
        });

        test('succeeds for valid base unit selection', () {
          expect(
            () => app_rules.checkBaseUnitSelection(
              const app_in.ExistingTenantUnit('u1'),
            ),
            returnsNormally,
          );
        });
      });

      group('checkConversionUnit', () {
        test('fails when unitName is empty', () {
          expect(
            () => app_rules.checkConversionUnit(
              unitName: '   ',
              conversionRateToBase: 10.0,
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Unit name must not be empty.',
                  ),
            ),
          );
        });

        test('fails when unitName > 80 chars', () {
          expect(
            () => app_rules.checkConversionUnit(
              unitName: 'A' * 81,
              conversionRateToBase: 10.0,
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Unit name is too long.',
                  ),
            ),
          );
        });

        test('fails when conversionRateToBase <= 0', () {
          expect(
            () => app_rules.checkConversionUnit(
              unitName: 'Hộp',
              conversionRateToBase: 0,
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Conversion rate must be greater than zero.',
                  ),
            ),
          );
        });

        test('succeeds for valid conversion unit', () {
          expect(
            () => app_rules.checkConversionUnit(
              unitName: 'Hộp',
              conversionRateToBase: 10,
            ),
            returnsNormally,
          );
        });
      });

      group('checkUpsertCustomFieldGroup', () {
        test('fails when group name is empty', () {
          expect(
            () => app_rules.checkUpsertCustomFieldGroup('   '),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Group name must not be empty.',
                  ),
            ),
          );
        });

        test('succeeds for valid group name', () {
          expect(
            () => app_rules.checkUpsertCustomFieldGroup('Thông tin chung'),
            returnsNormally,
          );
        });
      });

      group('checkReorderGroups', () {
        test('fails when orderedGroupIds is empty', () {
          expect(
            () => app_rules.checkReorderGroups(const []),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Ordered group ids must include all groups.',
                  ),
            ),
          );
        });

        test('fails when a group id is empty', () {
          expect(
            () => app_rules.checkReorderGroups(const ['g1', '   ']),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Group id must not be empty.',
                  ),
            ),
          );
        });

        test('succeeds for valid group ids', () {
          expect(
            () => app_rules.checkReorderGroups(const ['g1', 'g2']),
            returnsNormally,
          );
        });
      });

      group('checkReorderFields', () {
        test('fails when orderedFieldIds is empty', () {
          expect(
            () => app_rules.checkReorderFields(const []),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Ordered field ids must include all fields.',
                  ),
            ),
          );
        });

        test('fails when a field id is empty', () {
          expect(
            () => app_rules.checkReorderFields(const ['f1', '   ']),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Field id must not be empty.',
                  ),
            ),
          );
        });

        test('succeeds for valid field ids', () {
          expect(
            () => app_rules.checkReorderFields(const ['f1', 'f2']),
            returnsNormally,
          );
        });
      });

      group('checkUpsertCustomField', () {
        test('fails when name is empty', () {
          expect(
            () => app_rules.checkUpsertCustomField(
              name: '   ',
              fieldType: app_cf.CustomFieldType.text,
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Field name must not be empty.',
                  ),
            ),
          );
        });

        test('fails when singleSelect without options on create (fieldId null)', () {
          expect(
            () => app_rules.checkUpsertCustomField(
              fieldId: null,
              name: 'Dạng bào chế',
              fieldType: app_cf.CustomFieldType.singleSelect,
              options: const [],
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Single select field requires options.',
                  ),
            ),
          );
        });

        test('singleSelect on edit (fieldId not null) with blank option label throws domain rule message', () {
          expect(
            () => app_rules.checkUpsertCustomField(
              fieldId: 'f1',
              name: 'Dạng bào chế',
              fieldType: app_cf.CustomFieldType.singleSelect,
              options: const [
                app_cfo.CustomFieldSelectOptionDto(
                  optionId: 'opt-1',
                  label: '  ',
                  sortOrder: 0,
                  isActive: true,
                ),
              ],
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Trường single select phải có ít nhất một option hợp lệ.',
                  ),
            ),
          );
        });

        test('succeeds for valid single select field', () {
          expect(
            () => app_rules.checkUpsertCustomField(
              fieldId: 'f1',
              name: 'Dạng bào chế',
              fieldType: app_cf.CustomFieldType.singleSelect,
              options: const [
                app_cfo.CustomFieldSelectOptionDto(
                  optionId: 'opt-1',
                  label: 'Viên nén',
                  sortOrder: 0,
                  isActive: true,
                ),
              ],
            ),
            returnsNormally,
          );
        });
      });

      group('checkUpsertProductValues', () {
        test('fails when fieldId is empty', () {
          expect(
            () => app_rules.checkUpsertProductValues(const [
              app_in.ProductCustomFieldValueInput(fieldId: '   ', textValue: 'val'),
            ]),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Field id is required.',
                  ),
            ),
          );
        });

        test('fails when duplicate fieldId', () {
          expect(
            () => app_rules.checkUpsertProductValues(const [
              app_in.ProductCustomFieldValueInput(fieldId: 'f1', textValue: 'v1'),
              app_in.ProductCustomFieldValueInput(fieldId: 'f1', textValue: 'v2'),
            ]),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Duplicate custom field value.',
                  ),
            ),
          );
        });

        test('fails when multiple typed values on one item', () {
          expect(
            () => app_rules.checkUpsertProductValues(const [
              app_in.ProductCustomFieldValueInput(
                fieldId: 'f1',
                textValue: 'v1',
                numberValue: 123,
              ),
            ]),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Only one typed value is allowed per custom field.',
                  ),
            ),
          );
        });

        test('succeeds for valid values', () {
          expect(
            () => app_rules.checkUpsertProductValues(const [
              app_in.ProductCustomFieldValueInput(fieldId: 'f1', textValue: 'v1'),
              app_in.ProductCustomFieldValueInput(fieldId: 'f2', numberValue: 10),
            ]),
            returnsNormally,
          );
        });
      });

      group('checkManualBasePrice', () {
        test('fails when basePrice < 0', () {
          expect(
            () => app_rules.checkManualBasePrice(-1),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Giá cơ sở không được âm.',
                  ),
            ),
          );
        });

        test('succeeds for valid basePrice', () {
          expect(
            () => app_rules.checkManualBasePrice(50000),
            returnsNormally,
          );
        });
      });

      group('checkUnitPriceBand', () {
        test('fails for ruleBased source type', () {
          expect(
            () => app_rules.checkUnitPriceBand(
              sourceType: app_enum.PriceBandSourceType.ruleBased,
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Vui lòng dùng lệnh áp dụng khung giá cửa hàng.',
                  ),
            ),
          );
        });

        test('customConfig fails with prices', () {
          expect(
            () => app_rules.checkUnitPriceBand(
              sourceType: app_enum.PriceBandSourceType.customConfig,
              listBeforeVat: 10000,
              listMarkupRatio: 0.2,
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Cấu hình riêng chỉ nhận tỷ lệ phần trăm.',
                  ),
            ),
          );
        });

        test('customConfig fails when listMarkupRatio is null', () {
          expect(
            () => app_rules.checkUnitPriceBand(
              sourceType: app_enum.PriceBandSourceType.customConfig,
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Tỷ lệ giá niêm yết là bắt buộc.',
                  ),
            ),
          );
        });

        test('customConfig fails when listMarkupRatio < 0', () {
          expect(
            () => app_rules.checkUnitPriceBand(
              sourceType: app_enum.PriceBandSourceType.customConfig,
              listMarkupRatio: -0.1,
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Tỷ lệ không được âm.',
                  ),
            ),
          );
        });

        test('customConfig fails when floorMarkupRatio < 0', () {
          expect(
            () => app_rules.checkUnitPriceBand(
              sourceType: app_enum.PriceBandSourceType.customConfig,
              listMarkupRatio: 0.2,
              floorMarkupRatio: -0.05,
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Tỷ lệ không được âm.',
                  ),
            ),
          );
        });

        test('customConfig fails when floorMarkupRatio > listMarkupRatio', () {
          expect(
            () => app_rules.checkUnitPriceBand(
              sourceType: app_enum.PriceBandSourceType.customConfig,
              listMarkupRatio: 0.1,
              floorMarkupRatio: 0.2,
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Tỷ lệ giá sàn không được lớn hơn tỷ lệ giá niêm yết.',
                  ),
            ),
          );
        });

        test('manual fails when formula markup ratio is provided', () {
          expect(
            () => app_rules.checkUnitPriceBand(
              sourceType: app_enum.PriceBandSourceType.manual,
              listBeforeVat: 10000,
              listAfterVat: 11000,
              listMarkupRatio: 0.2,
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Giá thủ công không được có nguồn công thức.',
                  ),
            ),
          );
        });

        test('manual fails when list prices missing', () {
          expect(
            () => app_rules.checkUnitPriceBand(
              sourceType: app_enum.PriceBandSourceType.manual,
              listBeforeVat: 10000,
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Giá niêm yết là bắt buộc.',
                  ),
            ),
          );
        });

        test('manual fails when list price < 0', () {
          expect(
            () => app_rules.checkUnitPriceBand(
              sourceType: app_enum.PriceBandSourceType.manual,
              listBeforeVat: -1000,
              listAfterVat: 1000,
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Giá không được âm.',
                  ),
            ),
          );
        });

        test('manual fails when floor price < 0', () {
          expect(
            () => app_rules.checkUnitPriceBand(
              sourceType: app_enum.PriceBandSourceType.manual,
              listBeforeVat: 10000,
              listAfterVat: 11000,
              floorBeforeVat: -500,
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Giá không được âm.',
                  ),
            ),
          );
        });

        test('manual fails with FLOOR_GREATER_THAN_LIST when floorBefore > listBefore', () {
          expect(
            () => app_rules.checkUnitPriceBand(
              sourceType: app_enum.PriceBandSourceType.manual,
              listBeforeVat: 10000,
              listAfterVat: 11000,
              floorBeforeVat: 12000,
            ),
            throwsA(
              isA<AppException>().having(
                (e) => e.code,
                'code',
                CatalogErrorCodes.floorGreaterThanList,
              ),
            ),
          );
        });

        test('manual fails with FLOOR_GREATER_THAN_LIST when floorAfter > listAfter', () {
          expect(
            () => app_rules.checkUnitPriceBand(
              sourceType: app_enum.PriceBandSourceType.manual,
              listBeforeVat: 10000,
              listAfterVat: 11000,
              floorAfterVat: 12000,
            ),
            throwsA(
              isA<AppException>().having(
                (e) => e.code,
                'code',
                CatalogErrorCodes.floorGreaterThanList,
              ),
            ),
          );
        });

        test('manual succeeds for valid prices', () {
          expect(
            () => app_rules.checkUnitPriceBand(
              sourceType: app_enum.PriceBandSourceType.manual,
              listBeforeVat: 10000,
              listAfterVat: 11000,
              floorBeforeVat: 8000,
              floorAfterVat: 8800,
            ),
            returnsNormally,
          );
        });

        test('customConfig succeeds for valid ratios', () {
          expect(
            () => app_rules.checkUnitPriceBand(
              sourceType: app_enum.PriceBandSourceType.customConfig,
              listMarkupRatio: 0.2,
              floorMarkupRatio: 0.1,
            ),
            returnsNormally,
          );
        });
      });

      group('checkStorePriceRule', () {
        test('fails when name is empty', () {
          expect(
            () => app_rules.checkStorePriceRule(
              name: '   ',
              listMarkupRatio: 0.2,
              floorMarkupRatio: 0.1,
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Tên quy tắc giá là bắt buộc.',
                  ),
            ),
          );
        });

        test('fails when listMarkupRatio < 0', () {
          expect(
            () => app_rules.checkStorePriceRule(
              name: 'Rule',
              listMarkupRatio: -0.1,
              floorMarkupRatio: 0.1,
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Tỷ lệ cộng thêm Giá niêm yết phải lớn hơn hoặc bằng 0.',
                  ),
            ),
          );
        });

        test('fails when floorMarkupRatio < 0', () {
          expect(
            () => app_rules.checkStorePriceRule(
              name: 'Rule',
              listMarkupRatio: 0.2,
              floorMarkupRatio: -0.1,
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Tỷ lệ cộng thêm Giá sàn phải lớn hơn hoặc bằng 0.',
                  ),
            ),
          );
        });

        test('fails when rounded floor > list', () {
          expect(
            () => app_rules.checkStorePriceRule(
              name: 'Rule',
              listMarkupRatio: 0.1,
              floorMarkupRatio: 0.2,
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Giá sàn không được lớn hơn giá niêm yết.',
                  ),
            ),
          );
        });

        test('fails when unrounded floor > list (0.1 vs 0.104)', () {
          expect(
            () => app_rules.checkStorePriceRule(
              name: 'Rule',
              listMarkupRatio: 0.1,
              floorMarkupRatio: 0.104,
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Floor markup ratio must not be greater than list markup ratio.',
                  ),
            ),
          );
        });

        test('succeeds for valid store price rule', () {
          expect(
            () => app_rules.checkStorePriceRule(
              name: 'Rule standard',
              listMarkupRatio: 0.2,
              floorMarkupRatio: 0.1,
            ),
            returnsNormally,
          );
        });
      });

      group('checkPriceBandSnapshotRequest', () {
        test('fails when items is empty', () {
          expect(
            () => app_rules.checkPriceBandSnapshotRequest(const []),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'At least one item is required.',
                  ),
            ),
          );
        });

        test('fails when items > 100', () {
          expect(
            () => app_rules.checkPriceBandSnapshotRequest(
              List.generate(
                101,
                (i) => app_pb.ProductPriceBandSnapshotRequest(productId: 'p$i', productUnitId: 'u$i'),
              ),
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'At most 100 items can be read at once.',
                  ),
            ),
          );
        });

        test('fails when productId is empty', () {
          expect(
            () => app_rules.checkPriceBandSnapshotRequest(const [
              app_pb.ProductPriceBandSnapshotRequest(productId: '   ', productUnitId: 'u1'),
            ]),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Product id is required.',
                  ),
            ),
          );
        });

        test('fails when productUnitId is empty', () {
          expect(
            () => app_rules.checkPriceBandSnapshotRequest(const [
              app_pb.ProductPriceBandSnapshotRequest(productId: 'p1', productUnitId: '   '),
            ]),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Product unit id is required.',
                  ),
            ),
          );
        });

        test('fails when duplicate pair', () {
          expect(
            () => app_rules.checkPriceBandSnapshotRequest(const [
              app_pb.ProductPriceBandSnapshotRequest(productId: 'p1', productUnitId: 'u1'),
              app_pb.ProductPriceBandSnapshotRequest(productId: 'p1', productUnitId: 'u1'),
            ]),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Duplicate product and unit pair is not allowed.',
                  ),
            ),
          );
        });

        test('succeeds for valid snapshot query', () {
          expect(
            () => app_rules.checkPriceBandSnapshotRequest(const [
              app_pb.ProductPriceBandSnapshotRequest(productId: 'p1', productUnitId: 'u1'),
              app_pb.ProductPriceBandSnapshotRequest(productId: 'p1', productUnitId: 'u2'),
            ]),
            returnsNormally,
          );
        });
      });

      group('checkSetBasicStock', () {
        test('fails when quantity < 0', () {
          expect(
            () => app_rules.checkSetBasicStock(-1),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Số lượng tồn kho ban đầu không được âm.',
                  ),
            ),
          );
        });

        test('passes when quantity >= 0', () {
          expect(() => app_rules.checkSetBasicStock(0), returnsNormally);
          expect(() => app_rules.checkSetBasicStock(10), returnsNormally);
        });
      });

      group('checkAdjustBasicStock', () {
        test('fails when newQuantity < 0', () {
          expect(
            () => app_rules.checkAdjustBasicStock(-1),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.validation)
                  .having(
                    (e) => e.serverMessage,
                    'serverMessage',
                    'Số lượng tồn kho không được âm.',
                  ),
            ),
          );
        });

        test('passes when newQuantity >= 0', () {
          expect(() => app_rules.checkAdjustBasicStock(0), returnsNormally);
          expect(() => app_rules.checkAdjustBasicStock(10), returnsNormally);
        });
      });
    });
  });
}
