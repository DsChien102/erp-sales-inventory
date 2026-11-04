// ignore_for_file: implementation_imports

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/catalog/data/catalog_errors.dart';
import 'package:erp/features/catalog/data/custom_field_repository.dart';
import 'package:erp/features/catalog/data/measurement_unit_repository.dart';
import 'package:erp/features/catalog/data/models/catalog_enums.dart' as app_enum;
import 'package:erp/features/catalog/data/models/custom_field_config.dart' as app_cf;
import 'package:erp/features/catalog/data/models/custom_field_filter_option.dart' as app_cfo;
import 'package:erp/features/catalog/data/models/price_band.dart' as app_pb;
import 'package:erp/features/catalog/data/models/product_inputs.dart' as app_in;
import 'package:erp/features/catalog/data/models/store_price_rule.dart' as app_spr;
import 'package:erp/features/catalog/data/product_price_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const tenantId = 'tenant-123';
const productId = '11111111-1111-4111-8111-111111111111';

final _expectedListTenantUnitsParams = {
  'p_tenant_id': tenantId,
  'p_keyword': 'hộp',
  'p_limit': 50,
};

final _expectedListProductUnitsParams = {
  'p_tenant_id': tenantId,
  'p_product_id': productId,
  'p_include_inactive': true,
};

final _expectedSetProductBaseUnitExistingParams = {
  'p_tenant_id': tenantId,
  'p_product_id': productId,
  'p_tenant_unit_id': 'unit-existing-1',
  'p_new_unit_name': null,
};

final _expectedSetProductBaseUnitNewParams = {
  'p_tenant_id': tenantId,
  'p_product_id': productId,
  'p_tenant_unit_id': null,
  'p_new_unit_name': 'Chai',
};

final _expectedAddConversionUnitParams = {
  'p_tenant_id': tenantId,
  'p_product_id': productId,
  'p_unit_name': 'Vỉ 10 viên',
  'p_conversion_rate_to_base': 10.0,
};

final _expectedDeactivateConversionUnitParams = {
  'p_tenant_id': tenantId,
  'p_product_id': productId,
  'p_product_unit_id': 'pu-1',
};

final _expectedReactivateConversionUnitParams = {
  'p_tenant_id': tenantId,
  'p_product_id': productId,
  'p_product_unit_id': 'pu-1',
};

final _expectedDeleteConversionUnitParams = {
  'p_tenant_id': tenantId,
  'p_product_id': productId,
  'p_product_unit_id': 'pu-1',
};

final _expectedListCustomFieldConfigParams = {
  'p_tenant_id': tenantId,
};

final _expectedInitializeCustomFieldTemplateParams = {
  'p_tenant_id': tenantId,
  'p_template_id': null,
};

final _expectedUpsertCustomFieldGroupParams = {
  'p_tenant_id': tenantId,
  'p_group_id': 'group-1',
  'p_name': 'Nhóm thuốc',
  'p_icon_key': 'pill',
  'p_is_active': true,
};

final _expectedReorderCustomFieldGroupsParams = {
  'p_tenant_id': tenantId,
  'p_ordered_group_ids': ['g-1', 'g-2'],
};

final _expectedUpsertCustomFieldParams = {
  'p_tenant_id': tenantId,
  'p_group_id': 'group-1',
  'p_field_id': 'field-1',
  'p_name': 'Dạng bào chế',
  'p_field_type': 'singleSelect',
  'p_options': [
    {
      'option_id': 'opt-1',
      'label': 'Viên nén',
      'sort_order': 0,
      'is_active': true,
    },
    {
      'option_id': 'opt-2',
      'label': 'Siro',
      'sort_order': 1,
      'is_active': true,
    },
  ],
  'p_is_active': true,
};

final _expectedConfigureCustomFieldAttributesParams = {
  'p_tenant_id': tenantId,
  'p_field_id': 'field-1',
  'p_is_required': true,
  'p_is_searchable': true,
  'p_is_filterable': false,
  'p_display_on_list': true,
};

final _expectedReorderCustomFieldsParams = {
  'p_tenant_id': tenantId,
  'p_group_id': 'group-1',
  'p_ordered_field_ids': ['f-1', 'f-2'],
};

final _expectedGetProductCustomFieldValuesParams = {
  'p_tenant_id': tenantId,
  'p_product_id': productId,
  'p_include_inactive_values': true,
};

final _expectedUpsertProductCustomFieldValuesParams = {
  'p_tenant_id': tenantId,
  'p_product_id': productId,
  'p_values': [
    {'field_id': 'f-text', 'text_value': 'Text val'},
    {'field_id': 'f-num', 'number_value': 123.45},
    {'field_id': 'f-date', 'date_value': '2026-11-03'},
    {'field_id': 'f-bool', 'boolean_value': true},
    {'field_id': 'f-opt', 'option_id': 'opt-1'},
    {'field_id': 'f-empty'},
  ],
};

final _expectedSetManualBasePriceParams = {
  'p_tenant_id': tenantId,
  'p_product_id': productId,
  'p_mode': 'manual',
  'p_base_price_after_vat': 50000.0,
  'p_currency': 'VND',
};

final _expectedListProductUnitPriceBandsParams = {
  'p_tenant_id': tenantId,
  'p_product_id': productId,
};

final _expectedGetPriceBandSnapshotParams = {
  'p_tenant_id': tenantId,
  'p_items': [
    {'product_id': 'p-1', 'product_unit_id': 'u-1'},
    {'product_id': 'p-2', 'product_unit_id': 'u-2'},
  ],
};

final _expectedSetProductUnitPriceBandManualWithFloorParams = {
  'p_tenant_id': tenantId,
  'p_product_id': productId,
  'p_product_unit_id': 'pu-1',
  'p_list_price_before_vat': 10000,
  'p_floor_price_before_vat': 8000,
  'p_list_price_after_vat': 11000,
  'p_floor_price_after_vat': 8800,
  'p_effective_from': '2026-11-03T00:00:00.000Z',
  'p_effective_to': '2026-12-31T00:00:00.000Z',
  'p_status': 'active',
  'p_source_type': 'manual',
  'p_store_price_rule_id': null,
  'p_list_markup_ratio': null,
  'p_floor_markup_ratio': null,
};

final _expectedSetProductUnitPriceBandManualWithoutFloorParams = {
  'p_tenant_id': tenantId,
  'p_product_id': productId,
  'p_product_unit_id': 'pu-1',
  'p_list_price_before_vat': 10000,
  'p_list_price_after_vat': 11000,
  'p_source_type': 'manual',
  'p_store_price_rule_id': null,
  'p_list_markup_ratio': null,
  'p_floor_markup_ratio': null,
};

final _expectedSetProductUnitPriceBandCustomConfigNewParams = {
  'p_tenant_id': tenantId,
  'p_product_id': productId,
  'p_product_unit_id': 'pu-1',
  'p_list_price_before_vat': null,
  'p_list_price_after_vat': null,
  'p_source_type': 'customConfig',
  'p_store_price_rule_id': null,
  'p_list_markup_ratio': 0.2,
  'p_floor_markup_ratio': 0.1,
};

final _expectedSuggestProductUnitPriceParams = {
  'p_tenant_id': tenantId,
  'p_product_id': productId,
  'p_product_unit_id': 'pu-1',
};

final _expectedApplyStorePriceRuleParams = {
  'p_tenant_id': tenantId,
  'p_product_id': productId,
  'p_product_unit_id': 'pu-1',
  'p_store_price_rule_id': null,
  'p_confirm_overwrite': true,
  'p_base_price_version': 42,
};

final _expectedGetStorePriceRuleParams = {
  'p_tenant_id': tenantId,
};

final _expectedSetStorePriceRuleParams = {
  'p_tenant_id': tenantId,
  'p_name': 'Quy tắc chuẩn',
  'p_list_markup_ratio': 0.3,
  'p_floor_markup_ratio': 0.1,
  'p_status': 'active',
};

final _expectedGetStorePriceRuleChangeHistoryParams = {
  'p_tenant_id': tenantId,
  'p_limit': 50,
  'p_offset': 0,
};

void main() {
  group('catalog_unit_field_price_rpc_parity', () {
    group('new (repositories)', () {
      late _RecordingRpc rpc;
      late MeasurementUnitRepository unitRepo;
      late CustomFieldRepository fieldRepo;
      late ProductPriceRepository priceRepo;

      setUp(() {
        rpc = _RecordingRpc();
        unitRepo = MeasurementUnitRepository(
          rpc: rpc,
          tenantId: () async => tenantId,
        );
        fieldRepo = CustomFieldRepository(
          rpc: rpc,
          tenantId: () async => tenantId,
        );
        priceRepo = ProductPriceRepository(
          rpc: rpc,
          tenantId: () async => tenantId,
        );
      });

      // ==========================================
      // MeasurementUnitRepository
      // ==========================================
      group('MeasurementUnitRepository', () {
        test('H1 1: listTenantUnits params and result', () async {
          rpc.nextRowsResult = [
            {'id': 'u-1', 'name': 'Hộp', 'is_active': true},
          ];
          final res = await unitRepo.listTenantUnits(keyword: 'hộp', limit: 50);
          expect(rpc.calls.length, 1);
          final call = rpc.calls.single;
          expect(call.schema, 'catalog');
          expect(call.rpc, 'list_tenant_measurement_units');
          expect(call.params, _expectedListTenantUnitsParams);
          expect(call.isCall, isFalse);

          expect(res.length, 1);
          expect(res.first.id, 'u-1');
          expect(res.first.name, 'Hộp');
          expect(res.first.isActive, isTrue);
        });

        test('H1 2: listProductUnits params and result', () async {
          rpc.nextRowsResult = [
            {
              'id': 'pu-1',
              'name': 'Viên',
              'conversion_rate_to_base': 1.0,
              'is_base_unit': true,
              'is_active': true,
            },
            {
              'id': 'pu-2',
              'name': 'Hộp',
              'conversion_rate_to_base': 10.0,
              'is_base_unit': false,
              'is_active': true,
            },
          ];
          final res = await unitRepo.listProductUnits(productId, includeInactive: true);
          expect(rpc.calls.length, 1);
          final call = rpc.calls.single;
          expect(call.schema, 'catalog');
          expect(call.rpc, 'list_product_units');
          expect(call.params, _expectedListProductUnitsParams);
          expect(call.isCall, isFalse);

          expect(res.productId, productId);
          expect(res.baseUnitName, 'Viên');
          expect(res.units.length, 2);
          expect(res.units[1].name, 'Hộp');
          expect(res.units[1].conversionRateToBase, 10.0);
        });

        test('H1 3: setBaseUnit existing params', () async {
          rpc.nextCallResult = {'product_id': productId, 'base_unit_name': 'Hộp'};
          await unitRepo.setBaseUnit(
            productId,
            const app_in.ExistingTenantUnit('unit-existing-1'),
          );
          expect(rpc.calls.length, 1);
          final call = rpc.calls.single;
          expect(call.schema, 'catalog');
          expect(call.rpc, 'set_product_base_unit');
          expect(call.params, _expectedSetProductBaseUnitExistingParams);
          expect(call.isCall, isTrue);
        });

        test('H1 4: setBaseUnit new params', () async {
          rpc.nextCallResult = {'product_id': productId, 'base_unit_name': 'Chai'};
          await unitRepo.setBaseUnit(
            productId,
            const app_in.NewTenantUnit('Chai'),
          );
          expect(rpc.calls.length, 1);
          final call = rpc.calls.single;
          expect(call.schema, 'catalog');
          expect(call.rpc, 'set_product_base_unit');
          expect(call.params, _expectedSetProductBaseUnitNewParams);
          expect(call.isCall, isTrue);
        });

        test('H2: setBaseUnit empty checks (null and {})', () async {
          rpc.nextCallResult = null;
          await expectLater(
            unitRepo.setBaseUnit(productId, const app_in.ExistingTenantUnit('u1')),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.unknown)
                  .having((e) => e.serverMessage, 'serverMessage', 'Set base unit did not return a result.'),
            ),
          );

          rpc.calls.clear();
          rpc.nextCallResult = <String, dynamic>{};
          await expectLater(
            unitRepo.setBaseUnit(productId, const app_in.ExistingTenantUnit('u1')),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.unknown)
                  .having((e) => e.serverMessage, 'serverMessage', 'Set base unit did not return a result.'),
            ),
          );
        });

        test('H1 5 & H4: addConversionUnit calls 1 RPC with params', () async {
          rpc.nextCallResult = {'product_id': productId};
          await unitRepo.addConversionUnit(
            productId: productId,
            unitName: 'Vỉ 10 viên',
            conversionRateToBase: 10.0,
          );
          expect(rpc.calls.length, 1);
          final call = rpc.calls.single;
          expect(call.schema, 'catalog');
          expect(call.rpc, 'add_product_conversion_unit');
          expect(call.params, _expectedAddConversionUnitParams);
          expect(call.isCall, isTrue);
        });

        test('H1 6 & Q8: deactivateConversionUnit calls RPC without client id validation', () async {
          rpc.nextCallResult = {'product_id': productId};
          await unitRepo.deactivateConversionUnit(
            productId: productId,
            productUnitId: 'pu-1',
          );
          expect(rpc.calls.length, 1);
          final call = rpc.calls.single;
          expect(call.schema, 'catalog');
          expect(call.rpc, 'deactivate_product_conversion_unit');
          expect(call.params, _expectedDeactivateConversionUnitParams);

          // Q8 intentional change: empty productUnitId calls RPC instead of throwing in client
          rpc.calls.clear();
          await unitRepo.deactivateConversionUnit(productId: productId, productUnitId: '');
          expect(rpc.calls.length, 1);
          expect(rpc.calls.single.params?['p_product_unit_id'], '');
        });

        test('H1 7 & Q8: reactivateConversionUnit calls RPC', () async {
          rpc.nextCallResult = {'product_id': productId};
          await unitRepo.reactivateConversionUnit(
            productId: productId,
            productUnitId: 'pu-1',
          );
          expect(rpc.calls.length, 1);
          final call = rpc.calls.single;
          expect(call.schema, 'catalog');
          expect(call.rpc, 'reactivate_product_conversion_unit');
          expect(call.params, _expectedReactivateConversionUnitParams);
        });

        test('H1 8 & Q8: deleteConversionUnit calls RPC via rows', () async {
          rpc.nextRowsResult = [];
          await unitRepo.deleteConversionUnit(
            productId: productId,
            productUnitId: 'pu-1',
          );
          expect(rpc.calls.length, 1);
          final call = rpc.calls.single;
          expect(call.schema, 'catalog');
          expect(call.rpc, 'delete_product_conversion_unit');
          expect(call.params, _expectedDeleteConversionUnitParams);
          expect(call.isCall, isFalse);
        });
      });

      // ==========================================
      // CustomFieldRepository
      // ==========================================
      group('CustomFieldRepository', () {
        test('H1 9 & H2: listConfig params and result', () async {
          rpc.nextCallResult = {
            'groups': [
              {
                'group_id': 'g-1',
                'name': 'thông tin chung',
                'icon_key': 'box',
                'sort_order': 1,
                'status': 'active',
                'field_count': 1,
                'required_field_count': 1,
                'fields': [
                  {
                    'field_id': 'f-1',
                    'group_id': 'g-1',
                    'name': 'Hoạt chất',
                    'field_type': 'text',
                    'options': <Map<String, dynamic>>[],
                    'is_required': true,
                    'is_searchable': true,
                    'is_filterable': false,
                    'display_on_list': true,
                    'sort_order': 0,
                    'status': 'active',
                    'has_product_values': false,
                  },
                ],
              },
            ],
          };
          final res = await fieldRepo.listConfig();
          expect(rpc.calls.length, 1);
          final call = rpc.calls.single;
          expect(call.schema, 'catalog');
          expect(call.rpc, 'list_custom_field_config');
          expect(call.params, _expectedListCustomFieldConfigParams);
          expect(call.isCall, isTrue);

          expect(res.groups.length, 1);
          expect(res.groups.first.name, 'Thông tin chung');
          expect(res.groups.first.fields.first.fieldType, app_cf.CustomFieldType.text);
        });

        test('R1-1: listConfig returns empty config when RPC returns null', () async {
          rpc.nextCallResult = null;
          final res = await fieldRepo.listConfig();
          expect(res.groups, isEmpty);
        });

        test('H1 10: initializeTemplate params with p_template_id: null', () async {
          rpc.nextCallResult = {'groups_created': 2};
          await fieldRepo.initializeTemplate();
          expect(rpc.calls.length, 1);
          final call = rpc.calls.single;
          expect(call.schema, 'catalog');
          expect(call.rpc, 'initialize_custom_field_template');
          expect(call.params, _expectedInitializeCustomFieldTemplateParams);
          expect(call.params?['p_template_id'], isNull);
        });

        test('H1 11: upsertGroup params and empty checks', () async {
          rpc.nextCallResult = {'group_id': 'group-1'};
          await fieldRepo.upsertGroup(
            groupId: 'group-1',
            name: 'Nhóm thuốc',
            iconKey: 'pill',
            isActive: true,
          );
          expect(rpc.calls.length, 1);
          final call = rpc.calls.single;
          expect(call.schema, 'catalog');
          expect(call.rpc, 'upsert_custom_field_group');
          expect(call.params, _expectedUpsertCustomFieldGroupParams);

          rpc.calls.clear();
          rpc.nextCallResult = null;
          await expectLater(
            fieldRepo.upsertGroup(name: 'Group A'),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.unknown)
                  .having((e) => e.serverMessage, 'serverMessage', 'Upsert custom field group did not return a result.'),
            ),
          );

          rpc.calls.clear();
          rpc.nextCallResult = <String, dynamic>{};
          await expectLater(
            fieldRepo.upsertGroup(name: 'Group A'),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.unknown)
                  .having((e) => e.serverMessage, 'serverMessage', 'Upsert custom field group did not return a result.'),
            ),
          );
        });

        test('H1 12: reorderGroups params', () async {
          rpc.nextCallResult = {'success': true};
          await fieldRepo.reorderGroups(const ['g-1', 'g-2']);
          expect(rpc.calls.length, 1);
          final call = rpc.calls.single;
          expect(call.schema, 'catalog');
          expect(call.rpc, 'reorder_custom_field_groups');
          expect(call.params, _expectedReorderCustomFieldGroupsParams);
        });

        test('H1 13: upsertField params and empty checks', () async {
          rpc.nextCallResult = {
            'field_id': 'field-1',
            'group_id': 'group-1',
            'name': 'Dạng bào chế',
            'field_type': 'singleSelect',
            'options': [
              {'option_id': 'opt-1', 'label': 'Viên nén', 'sort_order': 0, 'is_active': true},
              {'option_id': 'opt-2', 'label': 'Siro', 'sort_order': 1, 'is_active': true},
            ],
            'is_required': false,
            'is_searchable': false,
            'is_filterable': false,
            'display_on_list': false,
            'sort_order': 0,
            'status': 'active',
            'has_product_values': false,
          };
          final res = await fieldRepo.upsertField(
            groupId: 'group-1',
            fieldId: 'field-1',
            name: 'Dạng bào chế',
            fieldType: app_cf.CustomFieldType.singleSelect,
            options: const [
              app_cfo.CustomFieldSelectOptionDto(
                optionId: 'opt-1',
                label: 'Viên nén',
                sortOrder: 0,
                isActive: true,
              ),
              app_cfo.CustomFieldSelectOptionDto(
                optionId: 'opt-2',
                label: 'Siro',
                sortOrder: 1,
                isActive: true,
              ),
            ],
            isActive: true,
          );
          expect(rpc.calls.length, 1);
          final call = rpc.calls.single;
          expect(call.schema, 'catalog');
          expect(call.rpc, 'upsert_custom_field');
          expect(call.params, _expectedUpsertCustomFieldParams);
          expect(res.fieldId, 'field-1');
          expect(res.name, 'Dạng bào chế');

          rpc.calls.clear();
          rpc.nextCallResult = null;
          await expectLater(
            fieldRepo.upsertField(
              groupId: 'group-1',
              name: 'Field A',
              fieldType: app_cf.CustomFieldType.text,
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.unknown)
                  .having((e) => e.serverMessage, 'serverMessage', 'Upsert custom field did not return a result.'),
            ),
          );

          rpc.calls.clear();
          rpc.nextCallResult = <String, dynamic>{};
          await expectLater(
            fieldRepo.upsertField(
              groupId: 'group-1',
              name: 'Field A',
              fieldType: app_cf.CustomFieldType.text,
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.unknown)
                  .having((e) => e.serverMessage, 'serverMessage', 'Upsert custom field did not return a result.'),
            ),
          );
        });

        test('H1 14 & Q8: configureAttributes params without client fieldId validation', () async {
          rpc.nextCallResult = {'success': true};
          await fieldRepo.configureAttributes(
            fieldId: 'field-1',
            isRequired: true,
            isSearchable: true,
            isFilterable: false,
            displayOnList: true,
          );
          expect(rpc.calls.length, 1);
          final call = rpc.calls.single;
          expect(call.schema, 'catalog');
          expect(call.rpc, 'configure_custom_field_attributes');
          expect(call.params, _expectedConfigureCustomFieldAttributesParams);

          // Q8 intentional change: empty fieldId calls RPC
          rpc.calls.clear();
          await fieldRepo.configureAttributes(
            fieldId: '',
            isRequired: true,
            isSearchable: true,
            isFilterable: false,
            displayOnList: true,
          );
          expect(rpc.calls.length, 1);
          expect(rpc.calls.single.params?['p_field_id'], '');
        });

        test('H1 15 & Q8: reorderFields params without client groupId validation', () async {
          rpc.nextCallResult = {'success': true};
          await fieldRepo.reorderFields(
            groupId: 'group-1',
            orderedFieldIds: const ['f-1', 'f-2'],
          );
          expect(rpc.calls.length, 1);
          final call = rpc.calls.single;
          expect(call.schema, 'catalog');
          expect(call.rpc, 'reorder_custom_fields');
          expect(call.params, _expectedReorderCustomFieldsParams);

          // Q8 intentional change: empty groupId calls RPC
          rpc.calls.clear();
          await fieldRepo.reorderFields(
            groupId: '',
            orderedFieldIds: const ['f-1', 'f-2'],
          );
          expect(rpc.calls.length, 1);
          expect(rpc.calls.single.params?['p_group_id'], '');
        });

        test('H1 16: getProductValues params and PRODUCT_NOT_FOUND on empty', () async {
          rpc.nextCallResult = {
            'product_id': productId,
            'groups': [
              {
                'group_id': 'g-1',
                'name': 'nhóm 1',
                'icon_key': 'icon',
                'sort_order': 1,
                'fields': [
                  {
                    'field_id': 'f-1',
                    'group_id': 'g-1',
                    'name': 'F1',
                    'field_type': 'text',
                    'options': <Map<String, dynamic>>[],
                    'is_required': true,
                    'is_missing': false,
                    'sort_order': 0,
                    'display_value': 'disp',
                    'text_value': 'txt',
                    'number_value': 10,
                    'date_value': '2026-11-03',
                    'boolean_value': true,
                    'option_id': 'opt-1',
                    'is_active': true,
                  },
                ],
              },
            ],
          };
          final res = await fieldRepo.getProductValues(productId, includeInactiveValues: true);
          expect(rpc.calls.length, 1);
          final call = rpc.calls.single;
          expect(call.schema, 'catalog');
          expect(call.rpc, 'get_product_custom_field_values');
          expect(call.params, _expectedGetProductCustomFieldValuesParams);
          expect(res.productId, productId);
          expect(res.groups.length, 1);
          expect(res.groups.first.name, 'Nhóm 1');

          // Empty check -> PRODUCT_NOT_FOUND
          rpc.calls.clear();
          rpc.nextCallResult = null;
          await expectLater(
            fieldRepo.getProductValues(productId),
            throwsA(
              isA<AppException>().having((e) => e.code, 'code', CatalogErrorCodes.productNotFound),
            ),
          );

          rpc.calls.clear();
          rpc.nextCallResult = <String, dynamic>{};
          await expectLater(
            fieldRepo.getProductValues(productId),
            throwsA(
              isA<AppException>().having((e) => e.code, 'code', CatalogErrorCodes.productNotFound),
            ),
          );
        });

        test('H1 17: upsertProductValues params and empty checks', () async {
          rpc.nextCallResult = {'success': true};
          await fieldRepo.upsertProductValues(
            productId: productId,
            values: [
              const app_in.ProductCustomFieldValueInput(fieldId: 'f-text', textValue: 'Text val'),
              const app_in.ProductCustomFieldValueInput(fieldId: 'f-num', numberValue: 123.45),
              app_in.ProductCustomFieldValueInput(
                fieldId: 'f-date',
                dateValue: DateTime.utc(2026, 11, 3, 23),
              ),
              const app_in.ProductCustomFieldValueInput(fieldId: 'f-bool', booleanValue: true),
              const app_in.ProductCustomFieldValueInput(fieldId: 'f-opt', optionId: 'opt-1'),
              const app_in.ProductCustomFieldValueInput(fieldId: 'f-empty'),
            ],
          );
          expect(rpc.calls.length, 1);
          final call = rpc.calls.single;
          expect(call.schema, 'catalog');
          expect(call.rpc, 'upsert_product_custom_field_values');
          expect(call.params, _expectedUpsertProductCustomFieldValuesParams);

          final emptyItem = (call.params!['p_values'] as List).last as Map<String, dynamic>;
          expect(emptyItem.containsKey('text_value'), isFalse);
          expect(emptyItem.containsKey('number_value'), isFalse);
          expect(emptyItem.containsKey('date_value'), isFalse);
          expect(emptyItem.containsKey('boolean_value'), isFalse);
          expect(emptyItem.containsKey('option_id'), isFalse);

          rpc.calls.clear();
          rpc.nextCallResult = null;
          await expectLater(
            fieldRepo.upsertProductValues(
              productId: productId,
              values: [const app_in.ProductCustomFieldValueInput(fieldId: 'f1', textValue: 'v')],
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.unknown)
                  .having((e) => e.serverMessage, 'serverMessage', 'Upsert product custom field values did not return a result.'),
            ),
          );

          rpc.calls.clear();
          rpc.nextCallResult = <String, dynamic>{};
          await expectLater(
            fieldRepo.upsertProductValues(
              productId: productId,
              values: [const app_in.ProductCustomFieldValueInput(fieldId: 'f1', textValue: 'v')],
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.unknown)
                  .having((e) => e.serverMessage, 'serverMessage', 'Upsert product custom field values did not return a result.'),
            ),
          );
        });

        group('G9 timezone-independent date format', () {
          test('g9_local_midnight_keeps_day', () async {
            rpc.calls.clear();
            rpc.nextCallResult = {'success': true};
            await fieldRepo.upsertProductValues(
              productId: productId,
              values: [
                app_in.ProductCustomFieldValueInput(
                  fieldId: 'f-date',
                  dateValue: DateTime(2026, 7, 10),
                ),
              ],
            );
            final values = rpc.calls.single.params!['p_values'] as List;
            final dateVal = (values.first as Map)['date_value'];
            expect(dateVal, '2026-07-10');
          });

          test('g9_utc_midnight_keeps_day', () async {
            rpc.calls.clear();
            rpc.nextCallResult = {'success': true};
            await fieldRepo.upsertProductValues(
              productId: productId,
              values: [
                app_in.ProductCustomFieldValueInput(
                  fieldId: 'f-date',
                  dateValue: DateTime.utc(2026, 7, 10, 0, 0),
                ),
              ],
            );
            final values = rpc.calls.single.params!['p_values'] as List;
            final dateVal = (values.first as Map)['date_value'];
            expect(dateVal, '2026-07-10');
          });

          test('g9_utc_late_keeps_day', () async {
            rpc.calls.clear();
            rpc.nextCallResult = {'success': true};
            await fieldRepo.upsertProductValues(
              productId: productId,
              values: [
                app_in.ProductCustomFieldValueInput(
                  fieldId: 'f-date',
                  dateValue: DateTime.utc(2026, 7, 10, 23, 59),
                ),
              ],
            );
            final values = rpc.calls.single.params!['p_values'] as List;
            final dateVal = (values.first as Map)['date_value'];
            expect(dateVal, '2026-07-10');
          });
        });
      });

      // ==========================================
      // ProductPriceRepository
      // ==========================================
      group('ProductPriceRepository', () {
        test('H1 18 & H4: setManualBasePrice calls 1 RPC with params and maps missing base unit exception', () async {
          rpc.nextCallResult = {'product_id': productId};
          await priceRepo.setManualBasePrice(
            productId: productId,
            basePrice: 50000.0,
            currency: 'VND',
          );
          expect(rpc.calls.length, 1);
          final call = rpc.calls.single;
          expect(call.schema, 'catalog');
          expect(call.rpc, 'set_manual_base_price');
          expect(call.params, _expectedSetManualBasePriceParams);
          expect(call.isCall, isTrue);

          // H4: PostgrestException missing base unit -> MISSING_BASE_UNIT
          rpc.calls.clear();
          rpc.errorToThrow = const PostgrestException(message: 'missing base unit');
          await expectLater(
            priceRepo.setManualBasePrice(productId: productId, basePrice: 50000.0),
            throwsA(
              isA<AppException>().having((e) => e.code, 'code', CatalogErrorCodes.missingBaseUnit),
            ),
          );
        });

        test('H1 19 & H2: listUnitPriceBands params, results (with basePrice and fallback), and empty check', () async {
          rpc.nextRowsResult = [
            {
              'product_id': productId,
              'base_unit_name': 'Hộp',
              'currency': 'VND',
              'base_price_amount': 50000.0,
              'product_unit_id': 'pu-1',
              'unit_name': 'Hộp',
              'is_base_unit': true,
              'is_active': true,
              'list_price_before_vat': 60000,
              'list_price_after_vat': 66000,
              'floor_price_before_vat': 55000,
              'floor_price_after_vat': 60500,
              'source_type': 'manual',
              'status': 'active',
            },
          ];
          final res1 = await priceRepo.listUnitPriceBands(productId);
          expect(rpc.calls.length, 1);
          final call = rpc.calls.single;
          expect(call.schema, 'catalog');
          expect(call.rpc, 'list_product_unit_price_bands');
          expect(call.params, _expectedListProductUnitPriceBandsParams);
          expect(call.isCall, isFalse);

          expect(res1.productId, productId);
          expect(res1.basePrice, 50000.0);
          expect(res1.rows.first.listBeforeVat, 60000);

          // Fallback basePricePerBaseUnit
          rpc.calls.clear();
          rpc.nextRowsResult = [
            {
              'product_id': productId,
              'base_unit_name': 'Hộp',
              'currency': 'VND',
              'product_unit_id': 'pu-1',
              'unit_name': 'Hộp',
              'is_base_unit': true,
              'is_active': true,
              'base_price': 40000.0,
              'list_price_before_vat': 50000,
              'list_price_after_vat': 55000,
            },
          ];
          final res2 = await priceRepo.listUnitPriceBands(productId);
          expect(res2.basePrice, 40000.0);

          // Empty check
          rpc.calls.clear();
          rpc.nextRowsResult = [];
          await expectLater(
            priceRepo.listUnitPriceBands(productId),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.unknown)
                  .having((e) => e.serverMessage, 'serverMessage', 'Product unit price bands did not return a result.'),
            ),
          );
        });

        test('H1 20 & H2: getPriceBandSnapshot params, result with common capturedAt', () async {
          rpc.nextCallResult = {
            'items': [
              {
                'product_id': 'p-1',
                'product_unit_id': 'u-1',
                'unit_name': 'Hộp',
                'currency': 'VND',
                'list_price_before_vat': 10000,
                'list_price_after_vat': 11000,
                'floor_price_before_vat': 8000,
                'floor_price_after_vat': 8800,
                'is_unit_active': true,
                'product_business_status': 'active',
              },
              {
                'product_id': 'p-2',
                'product_unit_id': 'u-2',
                'unit_name': 'Chai',
                'currency': 'VND',
                'list_price_before_vat': 20000,
                'list_price_after_vat': 22000,
                'floor_price_before_vat': 16000,
                'floor_price_after_vat': 17600,
                'is_unit_active': true,
                'product_business_status': 'active',
              },
            ],
          };

          final beforeCall = DateTime.now().toUtc();
          final snapshot = await priceRepo.getPriceBandSnapshot(const [
            app_pb.ProductPriceBandSnapshotRequest(productId: 'p-1', productUnitId: 'u-1'),
            app_pb.ProductPriceBandSnapshotRequest(productId: 'p-2', productUnitId: 'u-2'),
          ]);
          final afterCall = DateTime.now().toUtc();

          expect(rpc.calls.length, 1);
          final call = rpc.calls.single;
          expect(call.schema, 'catalog');
          expect(call.rpc, 'get_product_price_band_snapshot');
          expect(call.params, _expectedGetPriceBandSnapshotParams);
          expect(call.isCall, isTrue);

          expect(snapshot.items.length, 2);
          final item1 = snapshot.items[0];
          final item2 = snapshot.items[1];
          expect(item1.capturedAt, item2.capturedAt);
          expect(
            item1.capturedAt.isAfter(beforeCall) || item1.capturedAt.isAtSameMomentAs(beforeCall),
            isTrue,
          );
          expect(
            item1.capturedAt.isBefore(afterCall) || item1.capturedAt.isAtSameMomentAs(afterCall),
            isTrue,
          );
        });

        test('R1-1: getPriceBandSnapshot returns empty snapshot when RPC returns null', () async {
          rpc.nextCallResult = null;
          final snapshot = await priceRepo.getPriceBandSnapshot(const [
            app_pb.ProductPriceBandSnapshotRequest(productId: 'p-1', productUnitId: 'u-1'),
          ]);
          expect(snapshot.items, isEmpty);
        });

        test('H1 21: setUnitPriceBand manual with floor params', () async {
          rpc.nextRowsResult = [];
          await priceRepo.setUnitPriceBand(
            productId: productId,
            productUnitId: 'pu-1',
            sourceType: app_enum.PriceBandSourceType.manual,
            listBeforeVat: 10000,
            floorBeforeVat: 8000,
            listAfterVat: 11000,
            floorAfterVat: 8800,
            effectiveFrom: DateTime.utc(2026, 11, 3),
            effectiveTo: DateTime.utc(2026, 12, 31),
            status: app_enum.ProductPriceBandStatus.active,
          );
          expect(rpc.calls.length, 1);
          final call = rpc.calls.single;
          expect(call.schema, 'catalog');
          expect(call.rpc, 'set_product_unit_price_band');
          expect(call.params, _expectedSetProductUnitPriceBandManualWithFloorParams);
        });

        test('H1 22: setUnitPriceBand manual without floor params', () async {
          rpc.nextRowsResult = [];
          await priceRepo.setUnitPriceBand(
            productId: productId,
            productUnitId: 'pu-1',
            sourceType: app_enum.PriceBandSourceType.manual,
            listBeforeVat: 10000,
            listAfterVat: 11000,
          );
          expect(rpc.calls.length, 1);
          final call = rpc.calls.single;
          expect(call.schema, 'catalog');
          expect(call.rpc, 'set_product_unit_price_band');
          expect(call.params, _expectedSetProductUnitPriceBandManualWithoutFloorParams);
          expect(call.params!.containsKey('p_floor_price_before_vat'), isFalse);
          expect(call.params!.containsKey('p_floor_price_after_vat'), isFalse);
          expect(call.params!.containsKey('p_effective_from'), isFalse);
          expect(call.params!.containsKey('p_effective_to'), isFalse);
          expect(call.params!.containsKey('p_status'), isFalse);
        });

        test('H1 23 & H5: setUnitPriceBand customConfig sends null prices and omits floor keys (intentional change Q7)', () async {
          rpc.nextRowsResult = [];
          await priceRepo.setUnitPriceBand(
            productId: productId,
            productUnitId: 'pu-1',
            sourceType: app_enum.PriceBandSourceType.customConfig,
            listMarkupRatio: 0.2,
            floorMarkupRatio: 0.1,
          );
          expect(rpc.calls.length, 1);
          final call = rpc.calls.single;
          expect(call.schema, 'catalog');
          expect(call.rpc, 'set_product_unit_price_band');
          expect(call.params, _expectedSetProductUnitPriceBandCustomConfigNewParams);
          expect(call.params!['p_list_price_before_vat'], isNull);
          expect(call.params!['p_list_price_after_vat'], isNull);
          expect(call.params!.containsKey('p_floor_price_before_vat'), isFalse);
          expect(call.params!.containsKey('p_floor_price_after_vat'), isFalse);
        });

        test('H5: setUnitPriceBand with productUnitId null sends p_product_unit_id: null (intentional change Q9)', () async {
          rpc.nextRowsResult = [];
          await priceRepo.setUnitPriceBand(
            productId: productId,
            productUnitId: null,
            sourceType: app_enum.PriceBandSourceType.manual,
            listBeforeVat: 10000,
            listAfterVat: 11000,
          );
          expect(rpc.calls.length, 1);
          final call = rpc.calls.single;
          expect(call.params!['p_product_unit_id'], isNull);
        });

        test('H4: setUnitPriceBand maps inactive_product_unit error to INACTIVE_PRODUCT_UNIT', () async {
          rpc.errorToThrow = const PostgrestException(message: 'inactive_product_unit');
          await expectLater(
            priceRepo.setUnitPriceBand(
              productId: productId,
              productUnitId: 'pu-1',
              sourceType: app_enum.PriceBandSourceType.manual,
              listBeforeVat: 10000,
              listAfterVat: 11000,
            ),
            throwsA(
              isA<AppException>().having((e) => e.code, 'code', CatalogErrorCodes.inactiveProductUnit),
            ),
          );
        });

        test('H1 24 & H2: suggestUnitPrice params, result, and empty check', () async {
          rpc.nextRowsResult = [
            {
              'product_id': productId,
              'product_unit_id': 'pu-1',
              'unit_name': 'Hộp',
              'base_price': 50000.0,
              'currency': 'VND',
              'suggested_list_price_before_vat': 60000,
              'suggested_floor_price_before_vat': 55000,
              'store_price_rule_id': 'r-1',
              'store_price_rule_name': 'Standard',
              'base_price_version': 1,
              'can_suggest': true,
            },
          ];
          final res = await priceRepo.suggestUnitPrice(productId: productId, productUnitId: 'pu-1');
          expect(rpc.calls.length, 1);
          final call = rpc.calls.single;
          expect(call.schema, 'catalog');
          expect(call.rpc, 'suggest_product_unit_price');
          expect(call.params, _expectedSuggestProductUnitPriceParams);
          expect(res.productId, productId);
          expect(res.suggestedListBeforeVat, 60000);

          rpc.calls.clear();
          rpc.nextRowsResult = [];
          await expectLater(
            priceRepo.suggestUnitPrice(productId: productId),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.unknown)
                  .having((e) => e.serverMessage, 'serverMessage', 'Suggest product unit price did not return a result.'),
            ),
          );
        });

        test('H1 25 & H2: applyStorePriceRule params and empty check', () async {
          rpc.nextRowsResult = [
            {'product_id': productId},
          ];
          await priceRepo.applyStorePriceRule(
            productId: productId,
            productUnitId: 'pu-1',
            storePriceRuleId: null,
            confirmOverwrite: true,
            basePriceVersion: 42,
          );
          expect(rpc.calls.length, 1);
          final call = rpc.calls.single;
          expect(call.schema, 'catalog');
          expect(call.rpc, 'apply_store_price_rule');
          expect(call.params, _expectedApplyStorePriceRuleParams);

          rpc.calls.clear();
          rpc.nextRowsResult = [];
          await expectLater(
            priceRepo.applyStorePriceRule(productId: productId),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.unknown)
                  .having((e) => e.serverMessage, 'serverMessage', 'Apply store price rule did not return a result.'),
            ),
          );
        });

        test('H1 26 & H2: getStorePriceRule params, result and null on empty', () async {
          rpc.nextRowsResult = [
            {
              'id': 'rule-1',
              'tenant_id': tenantId,
              'name': 'Rule standard',
              'status': 'active',
              'list_markup_ratio': 0.2,
              'floor_markup_ratio': 0.1,
              'updated_at': '2026-11-03T10:00:00Z',
            },
          ];
          final rule = await priceRepo.getStorePriceRule();
          expect(rpc.calls.length, 1);
          final call = rpc.calls.single;
          expect(call.schema, 'catalog');
          expect(call.rpc, 'get_store_price_rule');
          expect(call.params, _expectedGetStorePriceRuleParams);
          expect(rule, isNotNull);
          expect(rule!.name, 'Rule standard');

          rpc.calls.clear();
          rpc.nextRowsResult = [];
          final emptyRule = await priceRepo.getStorePriceRule();
          expect(emptyRule, isNull);
        });

        test('H1 27 & H2: setStorePriceRule params, result, and invalid/empty checks', () async {
          rpc.nextRowsResult = [
            {
              'id': 'rule-1',
              'tenant_id': tenantId,
              'name': 'Quy tắc chuẩn',
              'status': 'active',
              'list_markup_ratio': 0.3,
              'floor_markup_ratio': 0.1,
              'updated_at': '2026-11-03T10:00:00Z',
            },
          ];
          final rule = await priceRepo.setStorePriceRule(
            name: 'Quy tắc chuẩn',
            listMarkupRatio: 0.3,
            floorMarkupRatio: 0.1,
            status: app_spr.StorePriceRuleStatus.active,
          );
          expect(rpc.calls.length, 1);
          final call = rpc.calls.single;
          expect(call.schema, 'catalog');
          expect(call.rpc, 'set_store_price_rule');
          expect(call.params, _expectedSetStorePriceRuleParams);
          expect(rule.name, 'Quy tắc chuẩn');

          // Empty rows check
          rpc.calls.clear();
          rpc.nextRowsResult = [];
          await expectLater(
            priceRepo.setStorePriceRule(
              name: 'Rule',
              listMarkupRatio: 0.3,
              floorMarkupRatio: 0.1,
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.unknown)
                  .having((e) => e.serverMessage, 'serverMessage', 'Set store price rule did not return a result.'),
            ),
          );

          // Invalid row check (missing id)
          rpc.calls.clear();
          rpc.nextRowsResult = [
            {'id': ''},
          ];
          await expectLater(
            priceRepo.setStorePriceRule(
              name: 'Rule',
              listMarkupRatio: 0.3,
              floorMarkupRatio: 0.1,
            ),
            throwsA(
              isA<AppException>()
                  .having((e) => e.code, 'code', AppErrorCode.unknown)
                  .having((e) => e.serverMessage, 'serverMessage', 'Set store price rule returned invalid data.'),
            ),
          );
        });

        test('H1 28 & H2: getStorePriceRuleHistory params and result', () async {
          rpc.nextCallResult = {
            'items': [
              {
                'id': 'h-1',
                'occurred_at': '2026-11-03T10:00:00Z',
                'actor_display_name': 'Admin',
                'summary': 'Updated markup',
                'list_markup_before': 0.2,
                'list_markup_after': 0.3,
                'floor_markup_before': 0.1,
                'floor_markup_after': 0.15,
                'is_current': true,
              },
            ],
            'total_count': 1,
          };
          final res = await priceRepo.getStorePriceRuleHistory(limit: 50, offset: 0);
          expect(rpc.calls.length, 1);
          final call = rpc.calls.single;
          expect(call.schema, 'catalog');
          expect(call.rpc, 'get_store_price_rule_change_history');
          expect(call.params, _expectedGetStorePriceRuleChangeHistoryParams);
          expect(res.items.length, 1);
          expect(res.items.first.summary, 'Updated markup');
          expect(res.totalCount, 1);
        });

        test('R1-1: getStorePriceRuleHistory returns empty result when RPC returns null', () async {
          rpc.nextCallResult = null;
          final res = await priceRepo.getStorePriceRuleHistory(limit: 50, offset: 0);
          expect(res.items, isEmpty);
          expect(res.totalCount, 0);
        });
      });
    });
  });
}

class _RpcCall {
  _RpcCall(this.schema, this.rpc, this.params, this.isCall);
  final String schema;
  final String rpc;
  final Map<String, dynamic>? params;
  final bool isCall;
}

class _RecordingRpc implements SupabaseRpc {
  final calls = <_RpcCall>[];
  Object? nextCallResult;
  List<Map<String, dynamic>> nextRowsResult = [];
  Object? errorToThrow;

  @override
  Future<dynamic> call(String schema, String rpc, {Map<String, dynamic>? params}) async {
    calls.add(_RpcCall(schema, rpc, params, true));
    if (errorToThrow != null) {
      if (errorToThrow is AppException) {
        throw errorToThrow!;
      }
      throw AppException.from(errorToThrow!);
    }
    return nextCallResult;
  }

  @override
  Future<List<Map<String, dynamic>>> rows(String schema, String rpc, {Map<String, dynamic>? params}) async {
    calls.add(_RpcCall(schema, rpc, params, false));
    if (errorToThrow != null) {
      if (errorToThrow is AppException) {
        throw errorToThrow!;
      }
      throw AppException.from(errorToThrow!);
    }
    return nextRowsResult;
  }

  @override
  Future<Map<String, dynamic>> firstRow(String schema, String rpc, {Map<String, dynamic>? params}) async {
    final r = await rows(schema, rpc, params: params);
    if (r.isEmpty) {
      throw const AppException(AppErrorCode.unknown, serverMessage: 'No rows returned');
    }
    return r.first;
  }
}

