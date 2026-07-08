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

    test('maps product custom field value params', () {
      final getParams = CustomFieldRpcMapper.getProductCustomFieldValuesParams(
        tenantId: 'tenant-1',
        productId: 'product-1',
        includeInactiveValues: true,
      );

      expect(getParams['p_tenant_id'], 'tenant-1');
      expect(getParams['p_product_id'], 'product-1');
      expect(getParams['p_include_inactive_values'], isTrue);

      final command = UpsertCustomFieldValuesCommand(
        tenantId: 'tenant-1',
        productId: 'product-1',
        values: [
          ProductCustomFieldValueInput(
            fieldId: 'field-1',
            textValue: 'Vitamin A',
          ),
          ProductCustomFieldValueInput(
            fieldId: 'field-2',
            numberValue: 7,
          ),
          ProductCustomFieldValueInput(
            fieldId: 'field-3',
            dateValue: DateTime.utc(2026, 7, 7),
          ),
        ],
      );

      final upsertParams = CustomFieldRpcMapper.upsertProductCustomFieldValuesParams(
        command: command,
      );
      expect(upsertParams['p_tenant_id'], 'tenant-1');
      expect(upsertParams['p_product_id'], 'product-1');
      expect(upsertParams['p_values'], [
        {
          'field_id': 'field-1',
          'text_value': 'Vitamin A',
        },
        {
          'field_id': 'field-2',
          'number_value': 7.0,
        },
        {
          'field_id': 'field-3',
          'date_value': '2026-07-07',
        },
      ]);
    });

    test('maps product custom field values response', () {
      final values = CustomFieldRpcMapper.productCustomFieldValuesFromJson({
        'product_id': 'product-1',
        'groups': [
          {
            'group_id': 'group-1',
            'name': 'Thông tin thuốc',
            'icon_key': 'pill',
            'sort_order': 0,
            'fields': [
              {
                'field_id': 'field-1',
                'group_id': 'group-1',
                'name': 'Thành phần',
                'field_type': 'text',
                'options': [],
                'is_required': true,
                'is_missing': false,
                'sort_order': 0,
                'display_value': 'Vitamin A',
                'text_value': 'Vitamin A',
              },
              {
                'field_id': 'field-2',
                'group_id': 'group-1',
                'name': 'Hạn dùng',
                'field_type': 'date',
                'options': [],
                'sort_order': 1,
                'display_value': '2026-07-07',
                'date_value': '2026-07-07',
              },
            ],
          },
        ],
      });

      expect(values.productId, 'product-1');
      expect(values.groups.single.name, 'Thông tin thuốc');
      expect(values.groups.single.fields.first.isRequired, isTrue);
      expect(values.groups.single.fields.first.displayValue, 'Vitamin A');
      expect(values.groups.single.fields.last.dateValue, DateTime.utc(2026, 7, 7));
    });

    test('maps upsert product custom field values result', () {
      final result = CustomFieldRpcMapper.upsertProductCustomFieldValuesResultFromJson({
        'product_id': 'product-1',
        'values': {
          'product_id': 'product-1',
          'groups': [],
        },
        'readiness_summary': {
          'status': 'readyToSell',
          'blockers': [],
        },
      });

      expect(result.productId, 'product-1');
      expect(result.values.productId, 'product-1');
      expect(result.readinessSummary.status, ReadinessStatus.readyToSell);
    });

    test('maps list custom field filter options params and response', () {
      final params = CustomFieldRpcMapper.listCustomFieldFilterOptionsParams(
        tenantId: 'tenant-1',
        maxOptionsPerField: 25,
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_max_options_per_field'], 25);

      final options = CustomFieldRpcMapper.filterOptionsFromJson([
        {
          'field_id': 'field-1',
          'group_id': 'group-1',
          'group_name': 'Thông tin thuốc',
          'field_name': 'Dạng dùng',
          'field_type': 'singleSelect',
          'options': [
            {
              'option_id': 'opt-1',
              'label': 'Dung dịch',
              'sort_order': 0,
              'is_active': true,
            },
          ],
          'sort_order': 10,
        },
      ]);

      expect(options.single.fieldName, 'Dạng dùng');
      expect(options.single.options.single.label, 'Dung dịch');
    });

    test('maps product custom field snapshot params and response', () {
      final params = CustomFieldRpcMapper.getProductCustomFieldSnapshotParams(
        tenantId: 'tenant-1',
        productIds: ['product-1', 'product-2'],
        includeInactiveValues: true,
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_product_ids'], ['product-1', 'product-2']);
      expect(params['p_include_inactive_values'], isTrue);

      final snapshot = CustomFieldRpcMapper.snapshotFromJson({
        'products': {
          'product-1': [
            {
              'product_id': 'product-1',
              'field_id': 'field-1',
              'group_id': 'group-1',
              'group_name': 'Thông tin thuốc',
              'field_name': 'Dạng dùng',
              'field_type': 'singleSelect',
              'display_value': 'Dung dịch',
              'option_id': 'opt-1',
              'option_label': 'Dung dịch',
              'is_active': true,
            },
          ],
        },
      });

      expect(snapshot.products['product-1']!.single.displayValue, 'Dung dịch');
      expect(snapshot.products['product-1']!.single.isActive, isTrue);
    });

    test('maps custom field list values from search row json', () {
      final values = CustomFieldRpcMapper.listValuesFromJson([
        {
          'field_id': 'field-1',
          'group_id': 'group-1',
          'group_name': 'Thông tin thuốc',
          'field_name': 'Dạng dùng',
          'field_type': 'singleSelect',
          'display_value': 'Dung dịch',
          'sort_order': 10,
        },
      ]);

      expect(values.single.displayValue, 'Dung dịch');
      expect(values.single.sortOrder, 10);
    });
  });
}
