import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/catalog/data/catalog_errors.dart';
import 'package:erp/features/catalog/logic/catalog_error_messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('catalogErrorMessage', () {
    test('returns fallback for non-AppException object', () {
      expect(catalogErrorMessage(Exception('random')), 'Đã xảy ra lỗi. Vui lòng thử lại.');
      expect(
        catalogErrorMessage('some string', fallback: 'Custom fallback'),
        'Custom fallback',
      );
    });

    group('knownServerMessages', () {
      test('product name is required (client rule or server)', () {
        final err = AppException(
          AppErrorCode.validation,
          serverMessage: 'Product name is required.',
        );
        expect(catalogErrorMessage(err), 'Tên nội bộ không được bỏ trống');
      });

      test('base unit is required for stock or pricing', () {
        final err = AppException(
          AppErrorCode.validation,
          serverMessage: 'Base unit is required for stock or pricing',
        );
        expect(catalogErrorMessage(err), 'Cần thiết lập đơn vị cơ sở trước.');
      });

      test('already has a base unit', () {
        final err = AppException(
          AppErrorCode.validation,
          serverMessage: 'Product already has a base unit; cannot change',
        );
        expect(catalogErrorMessage(err), 'Đơn vị cơ sở không đổi được sau khi đã đặt.');
      });

      test('conversion rate must be greater than zero', () {
        final err = AppException(
          AppErrorCode.validation,
          serverMessage: 'Conversion rate must be greater than zero.',
        );
        expect(catalogErrorMessage(err), 'Tỷ lệ quy đổi phải > 0');
      });

      test('base price cannot be negative', () {
        final err = AppException(
          AppErrorCode.validation,
          serverMessage: 'Base price cannot be negative.',
        );
        expect(catalogErrorMessage(err), 'Giá cơ sở không hợp lệ');
      });

      test('markup ratios are invalid', () {
        final err = AppException(
          AppErrorCode.validation,
          serverMessage: 'Markup ratios are invalid.',
        );
        expect(catalogErrorMessage(err), 'Tỷ lệ giá sàn không được lớn hơn tỷ lệ giá niêm yết.');
      });

      test('single select field requires options', () {
        final err = AppException(
          AppErrorCode.validation,
          serverMessage: 'Single select field requires options.',
        );
        expect(catalogErrorMessage(err), 'Cần có ít nhất 1 tùy chọn');
      });

      test('product is already inactive (precedence over already active)', () {
        final err = AppException(
          AppErrorCode.validation,
          serverMessage: 'Product is already inactive.',
        );
        expect(catalogErrorMessage(err), 'Sản phẩm đã ngừng kinh doanh.');
      });

      test('product is already active', () {
        final err = AppException(
          AppErrorCode.validation,
          serverMessage: 'Product is already active.',
        );
        expect(catalogErrorMessage(err), 'Sản phẩm đang kinh doanh.');
      });

      test('product is not soft-deleted on restore blocked', () {
        final err = AppException(
          CatalogErrorCodes.productRestoreBlocked,
          serverMessage: 'Product is not soft-deleted.',
        );
        expect(catalogErrorMessage(err), 'Sản phẩm chưa bị xoá.');
      });
    });

    group('switch code branches', () {
      test('noPermission and authRequired', () {
        expect(
          catalogErrorMessage(const AppException(AppErrorCode.noPermission)),
          'Bạn không có quyền thực hiện thao tác này.',
        );
        expect(
          catalogErrorMessage(const AppException(AppErrorCode.authRequired)),
          'Bạn không có quyền thực hiện thao tác này.',
        );
      });

      test('productNotFound', () {
        expect(
          catalogErrorMessage(const AppException(CatalogErrorCodes.productNotFound)),
          'Sản phẩm không tồn tại hoặc đã bị xoá.',
        );
      });

      test('staleProductVersion', () {
        expect(
          catalogErrorMessage(const AppException(CatalogErrorCodes.staleProductVersion)),
          'Sản phẩm đã được cập nhật ở nơi khác. Vui lòng tải lại.',
        );
      });

      test('duplicateSku', () {
        final err = const AppException(
          CatalogErrorCodes.duplicateSku,
          details: {'value': 'SKU-001'},
        );
        expect(catalogErrorMessage(err), 'SKU "SKU-001" đã được sử dụng');
      });

      test('duplicateBarcode', () {
        final err = const AppException(
          CatalogErrorCodes.duplicateBarcode,
          details: {'value': '8930001'},
        );
        expect(catalogErrorMessage(err), 'Barcode "8930001" đã được sử dụng');
      });

      test('productNameRequired', () {
        expect(
          catalogErrorMessage(const AppException(CatalogErrorCodes.productNameRequired)),
          'Tên nội bộ không được bỏ trống',
        );
      });

      test('productSoftDeleted', () {
        expect(
          catalogErrorMessage(const AppException(CatalogErrorCodes.productSoftDeleted)),
          'Sản phẩm đã bị xoá, không sửa được.',
        );
      });

      test('missingBaseUnit', () {
        expect(
          catalogErrorMessage(const AppException(CatalogErrorCodes.missingBaseUnit)),
          'Cần thiết lập đơn vị cơ sở trước.',
        );
      });

      test('duplicateProductUnit', () {
        final err = const AppException(
          CatalogErrorCodes.duplicateProductUnit,
          details: {'value': 'Hộp'},
        );
        expect(catalogErrorMessage(err), 'Đơn vị "Hộp" đã có trong sản phẩm.');
      });

      test('conversionUnitDeleteBlocked', () {
        final err = const AppException(
          CatalogErrorCodes.conversionUnitDeleteBlocked,
          serverMessage: 'Đơn vị đang có ràng buộc',
        );
        expect(catalogErrorMessage(err), 'Đơn vị đang có ràng buộc');
        expect(
          catalogErrorMessage(
            const AppException(CatalogErrorCodes.conversionUnitDeleteBlocked),
            fallback: 'Fallback',
          ),
          'Fallback',
        );
      });

      test('inactiveProductUnit', () {
        expect(
          catalogErrorMessage(const AppException(CatalogErrorCodes.inactiveProductUnit)),
          'Đơn vị bán đang không hoạt động.',
        );
      });

      test('staleStockQuantity', () {
        expect(
          catalogErrorMessage(const AppException(CatalogErrorCodes.staleStockQuantity)),
          'Tồn kho hiện tại đã thay đổi. Vui lòng tải lại dữ liệu trước khi điều chỉnh.',
        );
      });

      test('floorGreaterThanList', () {
        expect(
          catalogErrorMessage(const AppException(CatalogErrorCodes.floorGreaterThanList)),
          'Giá sàn không được lớn hơn giá niêm yết.',
        );
      });

      test('staleBasePrice', () {
        expect(
          catalogErrorMessage(const AppException(CatalogErrorCodes.staleBasePrice)),
          'Giá cơ sở vừa thay đổi. Vui lòng tải lại.',
        );
      });

      test('missingBasePrice', () {
        expect(
          catalogErrorMessage(const AppException(CatalogErrorCodes.missingBasePrice)),
          'Sản phẩm chưa có giá cơ sở.',
        );
      });

      test('storePriceRuleNotFound', () {
        expect(
          catalogErrorMessage(const AppException(CatalogErrorCodes.storePriceRuleNotFound)),
          'Cửa hàng chưa cấu hình khung giá.',
        );
      });

      test('storePriceRuleInactive', () {
        expect(
          catalogErrorMessage(const AppException(CatalogErrorCodes.storePriceRuleInactive)),
          'Khung giá cửa hàng đang tắt.',
        );
      });

      test('duplicateCustomFieldGroupName', () {
        expect(
          catalogErrorMessage(const AppException(CatalogErrorCodes.duplicateCustomFieldGroupName)),
          'Tên nhóm đã tồn tại.',
        );
      });

      test('duplicateCustomFieldName', () {
        expect(
          catalogErrorMessage(const AppException(CatalogErrorCodes.duplicateCustomFieldName)),
          'Tên trường đã tồn tại trong nhóm.',
        );
      });

      test('customFieldTypeChangeBlocked', () {
        expect(
          catalogErrorMessage(const AppException(CatalogErrorCodes.customFieldTypeChangeBlocked)),
          'Không đổi được kiểu dữ liệu do đã có dữ liệu.',
        );
      });

      test('customFieldGroupNotFound and customFieldNotFound', () {
        expect(
          catalogErrorMessage(const AppException(CatalogErrorCodes.customFieldGroupNotFound)),
          'Không tìm thấy nhóm / trường.',
        );
        expect(
          catalogErrorMessage(const AppException(CatalogErrorCodes.customFieldNotFound)),
          'Không tìm thấy nhóm / trường.',
        );
      });

      test('productDeleteBlocked and productRestoreBlocked with custom serverMessage', () {
        expect(
          catalogErrorMessage(
            const AppException(
              CatalogErrorCodes.productDeleteBlocked,
              serverMessage: 'Còn tồn kho 5 sản phẩm',
            ),
          ),
          'Còn tồn kho 5 sản phẩm',
        );
        expect(
          catalogErrorMessage(
            const AppException(
              CatalogErrorCodes.productRestoreBlocked,
              serverMessage: 'Không thể khôi phục',
            ),
          ),
          'Không thể khôi phục',
        );
      });

      test('AppErrorCode.validation with general message or empty', () {
        expect(
          catalogErrorMessage(
            const AppException(AppErrorCode.validation, serverMessage: 'Tùy chọn không hợp lệ'),
          ),
          'Tùy chọn không hợp lệ',
        );
        expect(
          catalogErrorMessage(
            const AppException(AppErrorCode.validation, serverMessage: '  '),
            fallback: 'Fallback validation',
          ),
          'Fallback validation',
        );
      });

      test('unknown code returns fallback', () {
        expect(
          catalogErrorMessage(
            const AppException('SOME_RANDOM_CODE'),
            fallback: 'Unknown error',
          ),
          'Unknown error',
        );
      });
    });
  });
}

