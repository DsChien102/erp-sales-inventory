import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';

void main() {
  group('custom field search contract handlers', () {
    test('assembler maps custom field list values to product list dto', () {
      final row = ProductListItemReadRow(
        id: 'product-1',
        name: 'Amoxicillin 500mg',
        sku: 'SP0001',
        barcode: '8930000000001',
        businessStatus: ProductBusinessStatus.active,
        facts: const ProductReadinessFacts(
          productId: 'product-1',
          productName: 'Amoxicillin 500mg',
          hasBaseUnit: true,
          hasImages: true,
          hasStock: true,
          hasBasePrice: true,
          hasPriceBand: true,
          hasRequiredCustomFields: true,
        ),
        updatedAt: DateTime.utc(2026, 7, 1),
        customFieldValues: const [
          CustomFieldListValueDto(
            fieldId: 'cf-dosage-form',
            groupId: 'cf-group-medicine',
            groupName: 'Thông tin thuốc',
            fieldName: 'Dạng dùng',
            fieldType: 'singleSelect',
            displayValue: 'Dung dịch',
            sortOrder: 1001,
          ),
        ],
      );

      final dto = ProductListItemAssembler.toDto(row);

      expect(dto.customFieldValues.single.displayValue, 'Dung dịch');
    });
  });
}
