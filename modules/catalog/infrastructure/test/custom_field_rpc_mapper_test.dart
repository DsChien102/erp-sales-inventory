import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_catalog_infrastructure/src/domain/custom_fields/custom_field_rpc_mapper.dart';

void main() {
  group('CustomFieldRpcMapper', () {
    test('maps initialize template params and result', () {
      final command = InitializeCustomFieldTemplateCommand(
        tenantId: 'tenant-1',
        templateId: 'vet_pharmacy_default',
      );

      final params = CustomFieldRpcMapper.initializeTemplateParams(command: command);
      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_template_id'], 'vet_pharmacy_default');

      final result = CustomFieldRpcMapper.initializeTemplateResult({
        'groups_created': 2,
        'fields_created': 3,
        'skipped_count': 1,
      });
      expect(result.groupsCreated, 2);
      expect(result.fieldsCreated, 3);
      expect(result.skippedCount, 1);
    });

    test('maps field and group json', () {
      final field = CustomFieldRpcMapper.fieldFromJson({
        'field_id': 'field-1',
        'group_id': 'group-1',
        'name': 'Thành phần',
        'field_type': 'text',
        'options': [],
        'is_required': true,
        'is_searchable': false,
        'is_filterable': true,
        'display_on_list': false,
        'sort_order': 1,
        'status': 'active',
      });

      expect(field.fieldId, 'field-1');
      expect(field.fieldType, CustomFieldType.text);
      expect(field.isRequired, isTrue);
      expect(field.status, CustomFieldConfigStatus.active);

      final group = CustomFieldRpcMapper.groupFromJson({
        'group_id': 'group-1',
        'name': 'Thông tin thuốc',
        'icon_key': '💊',
        'sort_order': 0,
        'status': 'inactive',
        'field_count': 1,
        'required_field_count': 1,
        'fields': [
          {
            'field_id': 'field-1',
            'group_id': 'group-1',
            'name': 'Thành phần',
            'field_type': 'singleSelect',
            'options': [
              {
                'option_id': 'opt-1',
                'label': 'A',
                'sort_order': 0,
                'is_active': true,
              },
            ],
            'is_required': false,
            'is_searchable': false,
            'is_filterable': false,
            'display_on_list': false,
            'sort_order': 0,
            'status': 'active',
          },
        ],
      });

      expect(group.status, CustomFieldConfigStatus.inactive);
      expect(group.fields.single.fieldType, CustomFieldType.singleSelect);
      expect(group.fields.single.options.single.label, 'A');
    });

    test('maps configure attributes result', () {
      final result = CustomFieldRpcMapper.configureAttributesResult({
        'field': {
          'field_id': 'field-1',
          'group_id': 'group-1',
          'name': 'Thành phần',
          'field_type': 'text',
          'options': [],
          'is_required': true,
          'is_searchable': false,
          'is_filterable': false,
          'display_on_list': false,
          'sort_order': 0,
          'status': 'active',
        },
        'existing_products_missing_count': 5,
      });

      expect(result.existingProductsMissingCount, 5);
      expect(result.field.isRequired, isTrue);
    });
  });
}
