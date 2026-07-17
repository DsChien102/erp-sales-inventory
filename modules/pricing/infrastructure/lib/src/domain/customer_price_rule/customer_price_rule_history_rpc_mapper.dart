import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';

abstract final class CustomerPriceRuleHistoryRpcMapper {
  static const _floorSensitiveKeys = {
    'floor_price_snapshot_minor',
    'floor_price_minor',
    'floor_price',
  };

  static Map<String, dynamic> params(GetCustomerPriceRuleHistoryQuery query) =>
      {
        'p_tenant_id': query.tenantId,
        'p_rule_id': query.ruleId,
        'p_cursor': query.cursor,
        'p_limit': query.limit,
      };

  static CursorPageDto<CustomerPriceRuleActivityDto> pageFromJson(
    Map<String, dynamic> json,
  ) {
    final items = json['items'];
    final hasMore = json['has_more'];
    final nextCursor = json['next_cursor'];
    if (items is! List ||
        hasMore is! bool ||
        (nextCursor != null && nextCursor is! String)) {
      throw const FormatException('Malformed pricing history page envelope.');
    }

    return CursorPageDto(
      items: List.unmodifiable(items.map(_item).toList(growable: false)),
      nextCursor: nextCursor as String?,
      hasMore: hasMore,
    );
  }

  static CustomerPriceRuleActivityDto _item(Object? value) {
    final json = _requiredMap(value, 'item');
    final actor = _requiredMap(json['actor'], 'actor');
    final sourceTrace = _requiredMap(json['source_trace'], 'source_trace');
    final sensitiveValuesHidden = _requiredBool(
      json,
      'sensitive_values_hidden',
    );
    final oldValue = _optionalSnapshot(json['old_value'], 'old_value');
    final newValue = _requiredSnapshot(json['new_value'], 'new_value');
    if (sensitiveValuesHidden) {
      _assertNoFloorLeak(oldValue);
      _assertNoFloorLeak(newValue);
    }

    return CustomerPriceRuleActivityDto(
      id: _requiredString(json, 'id'),
      activityType: _activityType(_requiredString(json, 'activity_type')),
      actor: CustomerPriceRuleActivityActorDto(
        actorId: _optionalString(actor['actor_id'], 'actor_id'),
        displayName: _requiredString(actor, 'display_name'),
        isSystemActor: _requiredBool(actor, 'is_system_actor'),
      ),
      sourceType: _source(_requiredString(json, 'source_type')),
      oldValue: oldValue,
      newValue: newValue,
      reason: _optionalString(json['reason'], 'reason'),
      sourceTrace: CustomerPriceRuleActivitySourceTraceDto(
        importId: _optionalString(sourceTrace['import_id'], 'import_id'),
        importRowId: _optionalString(
          sourceTrace['import_row_id'],
          'import_row_id',
        ),
        orderId: _optionalString(sourceTrace['order_id'], 'order_id'),
        orderLineId: _optionalString(
          sourceTrace['order_line_id'],
          'order_line_id',
        ),
        memoryRequestId: _optionalString(
          sourceTrace['memory_request_id'],
          'memory_request_id',
        ),
        soldAt: _optionalInstant(sourceTrace['sold_at']),
      ),
      sensitiveValuesHidden: sensitiveValuesHidden,
      createdAt: _instant(_requiredString(json, 'created_at')),
    );
  }

  static CustomerPriceRuleActivityType _activityType(String value) =>
      switch (value) {
        'created' => CustomerPriceRuleActivityType.created,
        'updated' => CustomerPriceRuleActivityType.updated,
        'disabled' => CustomerPriceRuleActivityType.disabled,
        'reenabled' => CustomerPriceRuleActivityType.reenabled,
        'import_created' => CustomerPriceRuleActivityType.importCreated,
        'import_updated' => CustomerPriceRuleActivityType.importUpdated,
        'memory_created' => CustomerPriceRuleActivityType.memoryCreated,
        'memory_updated' => CustomerPriceRuleActivityType.memoryUpdated,
        _ => throw FormatException('Unknown activity_type: $value'),
      };

  static CustomerPriceRuleSourceType _source(String value) => switch (value) {
    'manual' => CustomerPriceRuleSourceType.manual,
    'excel_import' => CustomerPriceRuleSourceType.excelImport,
    'sales_order' => CustomerPriceRuleSourceType.salesOrder,
    'migration' => CustomerPriceRuleSourceType.migration,
    _ => throw FormatException('Unknown source_type: $value'),
  };

  static Map<String, Object?>? _optionalSnapshot(Object? value, String field) {
    if (value == null) return null;
    return _requiredSnapshot(value, field);
  }

  static Map<String, Object?> _requiredSnapshot(Object? value, String field) {
    if (value is! Map) {
      throw FormatException('Expected object for $field.');
    }
    return _deepFreezeMap(value);
  }

  static void _assertNoFloorLeak(Map<String, Object?>? snapshot) {
    if (snapshot == null) return;
    for (final key in _floorSensitiveKeys) {
      if (snapshot.containsKey(key)) {
        throw FormatException(
          'Hidden floor-sensitive key leaked in snapshot: $key',
        );
      }
    }
  }

  static Map<String, Object?> _deepFreezeMap(Map<dynamic, dynamic> value) {
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw const FormatException('Snapshot keys must be strings.');
      }
      result[entry.key as String] = _deepFreezeValue(entry.value);
    }
    return Map.unmodifiable(result);
  }

  static Object? _deepFreezeValue(Object? value) {
    if (value is Map) {
      return _deepFreezeMap(value);
    }
    if (value is List) {
      return List.unmodifiable(
        value.map(_deepFreezeValue).toList(growable: false),
      );
    }
    return value;
  }

  static Map<String, dynamic> _requiredMap(Object? value, String field) {
    if (value is! Map) {
      throw FormatException('Expected object for $field.');
    }
    return value.cast<String, dynamic>();
  }

  static String _requiredString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is! String || value.isEmpty) {
      throw FormatException('Expected non-empty string for $field.');
    }
    return value;
  }

  static String? _optionalString(Object? value, String field) {
    if (value == null) return null;
    if (value is! String) {
      throw FormatException('Expected string or null for $field.');
    }
    return value;
  }

  static bool _requiredBool(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is! bool) {
      throw FormatException('Expected bool for $field.');
    }
    return value;
  }

  static DateTime _instant(String value) {
    final parsed = DateTime.parse(value);
    return parsed.isUtc ? parsed : parsed.toUtc();
  }

  static DateTime? _optionalInstant(Object? value) {
    if (value == null) return null;
    if (value is! String) {
      throw const FormatException('Expected string or null for sold_at.');
    }
    return _instant(value);
  }
}
