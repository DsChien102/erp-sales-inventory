import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';

import '../logic/catalog_rules.dart';
import 'catalog_errors.dart';
import 'models/custom_field_config.dart';
import 'models/custom_field_filter_option.dart';
import 'models/product_custom_field_values.dart';
import 'models/product_inputs.dart';

final class CustomFieldRepository {
  CustomFieldRepository({
    required SupabaseRpc rpc,
    required Future<String> Function() tenantId,
  })  : _rpc = rpc,
        _tenantId = tenantId;

  final SupabaseRpc _rpc;
  final Future<String> Function() _tenantId;

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on AppException catch (e) {
      throw catalogException(e);
    }
  }

  static String _dateOnly(DateTime dateTime) {
    final utc = dateTime.toUtc();
    final year = utc.year.toString().padLeft(4, '0');
    final month = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// 1. List tenant custom field configuration view (EPIC-03/US-01).
  Future<CustomFieldConfigViewDto> listConfig() async {
    final tid = await _tenantId();
    return _guard(() async {
      final result = await _rpc.call(
        'catalog',
        'list_custom_field_config',
        params: {
          'p_tenant_id': tid,
        },
      );
      final map = _asMap(result);
      return CustomFieldConfigViewDto.fromJson(map);
    });
  }

  /// 2. Initialize default custom field template (EPIC-03/US-01).
  Future<void> initializeTemplate({String? templateId}) async {
    final tid = await _tenantId();
    return _guard(() async {
      await _rpc.call(
        'catalog',
        'initialize_custom_field_template',
        params: {
          'p_tenant_id': tid,
          'p_template_id': templateId,
        },
      );
    });
  }

  /// 3. Upsert custom field group (EPIC-03/US-01).
  Future<void> upsertGroup({
    String? groupId,
    required String name,
    String? iconKey,
    bool isActive = true,
  }) async {
    checkUpsertCustomFieldGroup(name);
    final tid = await _tenantId();
    return _guard(() async {
      final result = await _rpc.call(
        'catalog',
        'upsert_custom_field_group',
        params: {
          'p_tenant_id': tid,
          'p_group_id': groupId,
          'p_name': name,
          'p_icon_key': iconKey,
          'p_is_active': isActive,
        },
      );
      if (result == null || (result is Map && result.isEmpty)) {
        throw const AppException(
          AppErrorCode.unknown,
          serverMessage: 'Upsert custom field group did not return a result.',
        );
      }
    });
  }

  /// 4. Reorder custom field groups (EPIC-03/US-01).
  Future<void> reorderGroups(List<String> orderedGroupIds) async {
    checkReorderGroups(orderedGroupIds);
    final tid = await _tenantId();
    return _guard(() async {
      await _rpc.call(
        'catalog',
        'reorder_custom_field_groups',
        params: {
          'p_tenant_id': tid,
          'p_ordered_group_ids': orderedGroupIds,
        },
      );
    });
  }

  /// 5. Upsert custom field definition (EPIC-03/US-01).
  Future<CustomFieldDefinitionDto> upsertField({
    required String groupId,
    String? fieldId,
    required String name,
    required CustomFieldType fieldType,
    List<CustomFieldSelectOptionDto> options = const [],
    bool isActive = true,
  }) async {
    checkUpsertCustomField(
      fieldId: fieldId,
      name: name,
      fieldType: fieldType,
      options: options,
    );
    final tid = await _tenantId();
    return _guard(() async {
      final result = await _rpc.call(
        'catalog',
        'upsert_custom_field',
        params: {
          'p_tenant_id': tid,
          'p_group_id': groupId,
          'p_field_id': fieldId,
          'p_name': name,
          'p_field_type': fieldType.name,
          'p_options': options
              .map(
                (option) => <String, dynamic>{
                  'option_id': option.optionId,
                  'label': option.label,
                  'sort_order': option.sortOrder,
                  'is_active': option.isActive,
                },
              )
              .toList(growable: false),
          'p_is_active': isActive,
        },
      );
      if (result == null || (result is Map && result.isEmpty)) {
        throw const AppException(
          AppErrorCode.unknown,
          serverMessage: 'Upsert custom field did not return a result.',
        );
      }
      final map = result is Map<String, dynamic>
          ? result
          : Map<String, dynamic>.from(result as Map);
      return CustomFieldDefinitionDto.fromJson(map);
    });
  }

  /// 6. Configure custom field attributes (EPIC-03/US-01).
  Future<void> configureAttributes({
    required String fieldId,
    required bool isRequired,
    required bool isSearchable,
    required bool isFilterable,
    required bool displayOnList,
  }) async {
    final tid = await _tenantId();
    return _guard(() async {
      await _rpc.call(
        'catalog',
        'configure_custom_field_attributes',
        params: {
          'p_tenant_id': tid,
          'p_field_id': fieldId,
          'p_is_required': isRequired,
          'p_is_searchable': isSearchable,
          'p_is_filterable': isFilterable,
          'p_display_on_list': displayOnList,
        },
      );
    });
  }

  /// 7. Reorder custom fields within group (EPIC-03/US-01).
  Future<void> reorderFields({
    required String groupId,
    required List<String> orderedFieldIds,
  }) async {
    checkReorderFields(orderedFieldIds);
    final tid = await _tenantId();
    return _guard(() async {
      await _rpc.call(
        'catalog',
        'reorder_custom_fields',
        params: {
          'p_tenant_id': tid,
          'p_group_id': groupId,
          'p_ordered_field_ids': orderedFieldIds,
        },
      );
    });
  }

  /// 8. Get custom field values for a product (EPIC-03/US-02).
  Future<ProductCustomFieldValuesDto> getProductValues(
    String productId, {
    bool includeInactiveValues = false,
  }) async {
    final tid = await _tenantId();
    return _guard(() async {
      final result = await _rpc.call(
        'catalog',
        'get_product_custom_field_values',
        params: {
          'p_tenant_id': tid,
          'p_product_id': productId,
          'p_include_inactive_values': includeInactiveValues,
        },
      );
      if (result == null || (result is Map && result.isEmpty)) {
        throw const AppException(CatalogErrorCodes.productNotFound);
      }
      final map = result is Map<String, dynamic>
          ? result
          : Map<String, dynamic>.from(result as Map);
      return ProductCustomFieldValuesDto.fromJson(map);
    });
  }

  /// 9. Upsert custom field values for a product (EPIC-03/US-02).
  Future<void> upsertProductValues({
    required String productId,
    required List<ProductCustomFieldValueInput> values,
  }) async {
    checkUpsertProductValues(values);
    final tid = await _tenantId();
    return _guard(() async {
      final result = await _rpc.call(
        'catalog',
        'upsert_product_custom_field_values',
        params: {
          'p_tenant_id': tid,
          'p_product_id': productId,
          'p_values': values.map((input) {
            final json = <String, dynamic>{'field_id': input.fieldId};
            if (input.textValue != null) {
              json['text_value'] = input.textValue;
            }
            if (input.numberValue != null) {
              json['number_value'] = input.numberValue;
            }
            if (input.dateValue != null) {
              json['date_value'] = _dateOnly(input.dateValue!);
            }
            if (input.booleanValue != null) {
              json['boolean_value'] = input.booleanValue;
            }
            if (input.optionId != null) {
              json['option_id'] = input.optionId;
            }
            return json;
          }).toList(growable: false),
        },
      );
      if (result == null || (result is Map && result.isEmpty)) {
        throw const AppException(
          AppErrorCode.unknown,
          serverMessage: 'Upsert product custom field values did not return a result.',
        );
      }
    });
  }
}

Map<String, dynamic> _asMap(Object? result) {
  if (result == null) return const <String, dynamic>{};
  if (result is Map<String, dynamic>) return result;
  if (result is Map) return Map<String, dynamic>.from(result);
  return const <String, dynamic>{};
}


