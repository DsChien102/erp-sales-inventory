import 'package:test/test.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  group('CustomFieldGroup', () {
    test('create rejects empty name', () {
      expect(
        () => CustomFieldGroup.create(
          id: 'g-1',
          tenantId: 'tenant-1',
          name: '   ',
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });

    test('deactivate and reactivate change status', () {
      final group = CustomFieldGroup.create(
        id: 'g-1',
        tenantId: 'tenant-1',
        name: 'Thông tin thuốc',
        icon: '💊',
      );

      expect(group.status, CustomFieldConfigStatus.active);
      expect(group.deactivate().status, CustomFieldConfigStatus.inactive);
      expect(
        group.deactivate().reactivate().status,
        CustomFieldConfigStatus.active,
      );
    });
  });

  group('CustomField', () {
    test('create rejects empty name', () {
      expect(
        () => CustomField.create(
          id: 'f-1',
          groupId: 'g-1',
          tenantId: 'tenant-1',
          name: '',
          fieldType: CustomFieldType.text,
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });

    test('single select requires options', () {
      expect(
        () => CustomField.create(
          id: 'f-2',
          groupId: 'g-1',
          tenantId: 'tenant-1',
          name: 'Loại',
          fieldType: CustomFieldType.singleSelect,
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });

    test('configureAttributes updates flags', () {
      final field = CustomField.create(
        id: 'f-3',
        groupId: 'g-1',
        tenantId: 'tenant-1',
        name: 'Thành phần',
        fieldType: CustomFieldType.text,
      );

      final updated = field.configureAttributes(
        isRequired: true,
        isSearchable: true,
      );

      expect(updated.isRequired, isTrue);
      expect(updated.isSearchable, isTrue);
      expect(updated.isFilterable, isFalse);
    });
  });
}
