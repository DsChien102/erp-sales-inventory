import 'package:vet45_pricing_application/application.dart';

abstract final class CustomerPriceRuleImportRpcMapper {
  static Map<String, dynamic> createParams({
    required String tenantId,
    required String templateVersion,
    required String originalFileName,
    required CustomerPriceRuleImportMode importMode,
    required CustomerPriceRuleImportParseResult parseResult,
  }) => <String, dynamic>{
    'p_tenant_id': tenantId,
    'p_template_version': templateVersion,
    'p_original_file_name': originalFileName,
    'p_import_mode': _importModeWire(importMode),
    'p_parse_result': _parseResultWire(parseResult),
  };

  static Map<String, dynamic> getParams({
    required String tenantId,
    required String importId,
    required CustomerPriceRuleImportRowStatus? rowStatus,
    required String? cursor,
    required int limit,
  }) => <String, dynamic>{
    'p_tenant_id': tenantId,
    'p_import_id': importId,
    'p_row_status': rowStatus == null ? null : _rowStatusWire(rowStatus),
    'p_cursor': cursor,
    'p_limit': limit,
  };

  static Map<String, dynamic> confirmParams({
    required String tenantId,
    required String importId,
    required int expectedVersion,
    required DateTime businessDate,
    required bool acknowledgeWarningRows,
  }) => <String, dynamic>{
    'p_tenant_id': tenantId,
    'p_import_id': importId,
    'p_expected_version': expectedVersion,
    'p_business_date': _date(businessDate),
    'p_acknowledge_warning_rows': acknowledgeWarningRows,
  };

  static Map<String, dynamic> cancelParams({
    required String tenantId,
    required String importId,
    required int expectedVersion,
  }) => <String, dynamic>{
    'p_tenant_id': tenantId,
    'p_import_id': importId,
    'p_expected_version': expectedVersion,
  };

  static CustomerPriceRuleImportDetailDto detailFromJson(
    Map<String, dynamic> json,
  ) => CustomerPriceRuleImportDetailDto(
    batch: batchFromJson(_map(json['batch'])),
    rows: _rowsPageFromJson(_map(json['rows'])),
  );

  static CustomerPriceRuleImportResultDto resultFromJson(
    Map<String, dynamic> json,
  ) => CustomerPriceRuleImportResultDto(
    batch: batchFromJson(_map(json['batch'])),
    processedAt: _dateTime(json['processed_at']),
    isReplay: json['is_replay'] as bool? ?? false,
  );

  static CustomerPriceRuleImportDto batchFromJson(Map<String, dynamic> json) =>
      CustomerPriceRuleImportDto(
        id: _string(json, 'id'),
        templateVersion: _string(json, 'template_version'),
        originalFileName: _string(json, 'original_file_name'),
        importMode: _importModeFromWire(_string(json, 'import_mode')),
        status: _batchStatusFromWire(_string(json, 'status')),
        version: _requiredInt(json['version']),
        totalRows: _requiredInt(json['total_rows']),
        validRows: _requiredInt(json['valid_rows']),
        warningRows: _requiredInt(json['warning_rows']),
        errorRows: _requiredInt(json['error_rows']),
        importedRows: _requiredInt(json['imported_rows']),
        skippedRows: _requiredInt(json['skipped_rows']),
        failedRows: _requiredInt(json['failed_rows']),
        fileErrorCodes: _stringList(json['file_error_codes']),
        createdAt: _dateTime(json['created_at']),
        confirmedAt: _optionalDateTime(json['confirmed_at']),
        canceledAt: _optionalDateTime(json['canceled_at']),
      );

  static Map<String, dynamic> _parseResultWire(
    CustomerPriceRuleImportParseResult parseResult,
  ) {
    if (!parseResult.isParsed) {
      return <String, dynamic>{
        'kind': 'failed',
        'file_error_codes': parseResult.fileErrorCodes,
      };
    }
    return <String, dynamic>{
      'kind': 'parsed',
      'rows': parseResult.rows
          .map(
            (row) => <String, dynamic>{
              'row_number': row.rowNumber,
              'rule_id': row.ruleId,
              'customer_id': row.customerId,
              'product_id': row.productId,
              'product_unit_id': row.productUnitId,
              'price': row.price,
              'effective_from': row.effectiveFrom,
              'effective_to': row.effectiveTo,
              'note': row.note,
            },
          )
          .toList(growable: false),
    };
  }

  static CursorPageDto<CustomerPriceRuleImportRowPreviewDto> _rowsPageFromJson(
    Map<String, dynamic> json,
  ) => CursorPageDto(
    items: _rowList(json['items']),
    nextCursor: json['next_cursor'] as String?,
    hasMore: json['has_more'] as bool? ?? false,
  );

  static List<CustomerPriceRuleImportRowPreviewDto> _rowList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<Map>()
        .map((raw) => rowPreviewFromJson(raw.cast<String, dynamic>()))
        .toList(growable: false);
  }

  static CustomerPriceRuleImportRowPreviewDto rowPreviewFromJson(
    Map<String, dynamic> json,
  ) => CustomerPriceRuleImportRowPreviewDto(
    id: _string(json, 'id'),
    rowNumber: _requiredInt(json['row_number']),
    ruleId: json['rule_id'] as String?,
    customerId: json['customer_id'] as String?,
    productId: json['product_id'] as String?,
    productUnitId: json['product_unit_id'] as String?,
    price: json['price'] as String?,
    effectiveFrom: json['effective_from'] as String?,
    effectiveTo: json['effective_to'] as String?,
    note: json['note'] as String?,
    customerSnapshot: _optionalMap(json['customer_snapshot']),
    productSnapshot: _optionalMap(json['product_snapshot']),
    unitSnapshot: _optionalMap(json['unit_snapshot']),
    unitResolutionStrategy: _unitStrategyFromWire(
      json['unit_resolution_strategy'] as String?,
    ),
    normalizedPriceMinor: _optionalInt(json['normalized_price_minor']),
    normalizedEffectiveFrom: _optionalDateTime(
      json['normalized_effective_from'],
    ),
    normalizedEffectiveTo: _optionalDateTime(json['normalized_effective_to']),
    normalizedNote: json['normalized_note'] as String?,
    status: _rowStatusFromWire(_string(json, 'status')),
    action: _actionFromWire(_string(json, 'action')),
    errorCodes: _stringList(json['error_codes']),
    warningCodes: _stringList(json['warning_codes']),
    matchedRuleId: json['matched_rule_id'] as String?,
    matchedRuleVersion: _optionalInt(json['matched_rule_version']),
    affectedRuleId: json['affected_rule_id'] as String?,
  );

  static String _importModeWire(CustomerPriceRuleImportMode mode) =>
      switch (mode) {
        CustomerPriceRuleImportMode.createOnly => 'create_only',
        CustomerPriceRuleImportMode.updateOnly => 'update_only',
        CustomerPriceRuleImportMode.upsert => 'upsert',
      };

  static CustomerPriceRuleImportMode _importModeFromWire(String value) =>
      switch (value) {
        'create_only' => CustomerPriceRuleImportMode.createOnly,
        'update_only' => CustomerPriceRuleImportMode.updateOnly,
        'upsert' => CustomerPriceRuleImportMode.upsert,
        _ => throw FormatException('Unknown import mode wire value: $value'),
      };

  static String _rowStatusWire(CustomerPriceRuleImportRowStatus status) =>
      switch (status) {
        CustomerPriceRuleImportRowStatus.valid => 'valid',
        CustomerPriceRuleImportRowStatus.warning => 'warning',
        CustomerPriceRuleImportRowStatus.error => 'error',
        CustomerPriceRuleImportRowStatus.imported => 'imported',
        CustomerPriceRuleImportRowStatus.skipped => 'skipped',
        CustomerPriceRuleImportRowStatus.failed => 'failed',
      };

  static CustomerPriceRuleImportStatus _batchStatusFromWire(String value) =>
      switch (value) {
        'failed' => CustomerPriceRuleImportStatus.failed,
        'ready_to_import' => CustomerPriceRuleImportStatus.readyToImport,
        'completed' => CustomerPriceRuleImportStatus.completed,
        'completed_with_errors' =>
          CustomerPriceRuleImportStatus.completedWithErrors,
        'canceled' => CustomerPriceRuleImportStatus.canceled,
        _ => throw FormatException('Unknown import status wire value: $value'),
      };

  static CustomerPriceRuleImportRowStatus _rowStatusFromWire(String value) =>
      switch (value) {
        'valid' => CustomerPriceRuleImportRowStatus.valid,
        'warning' => CustomerPriceRuleImportRowStatus.warning,
        'error' => CustomerPriceRuleImportRowStatus.error,
        'imported' => CustomerPriceRuleImportRowStatus.imported,
        'skipped' => CustomerPriceRuleImportRowStatus.skipped,
        'failed' => CustomerPriceRuleImportRowStatus.failed,
        _ => throw FormatException('Unknown row status wire value: $value'),
      };

  static CustomerPriceRuleImportAction _actionFromWire(String value) =>
      switch (value) {
        'create' => CustomerPriceRuleImportAction.create,
        'update' => CustomerPriceRuleImportAction.update,
        'skip' => CustomerPriceRuleImportAction.skip,
        _ => throw FormatException('Unknown import action wire value: $value'),
      };

  static ProductUnitResolutionStrategy? _unitStrategyFromWire(String? value) =>
      switch (value) {
        null => null,
        'explicit_selection' => ProductUnitResolutionStrategy.explicitSelection,
        'default_selling_unit' =>
          ProductUnitResolutionStrategy.defaultSellingUnit,
        'ambiguous' => ProductUnitResolutionStrategy.ambiguous,
        'not_found' => ProductUnitResolutionStrategy.notFound,
        _ => throw FormatException(
          'Unknown unit resolution strategy wire value: $value',
        ),
      };

  static List<String> _stringList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<String>().toList(growable: false);
  }

  static Map<String, dynamic>? _optionalMap(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! Map) {
      throw const FormatException('Expected a JSON object.');
    }
    return Map.unmodifiable(value.cast<String, dynamic>());
  }

  static int _requiredInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num && value.isFinite && value == value.truncateToDouble()) {
      return value.toInt();
    }
    throw FormatException('Expected an integer value, got $value.');
  }

  static int? _optionalInt(Object? value) =>
      value == null ? null : _requiredInt(value);

  static Map<String, dynamic> _map(Object? value) =>
      value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};

  static String _string(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Expected required string field $key.');
    }
    return value;
  }

  static DateTime _dateTime(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Expected ISO timestamp, got $value.');
    }
    return DateTime.parse(value).toUtc();
  }

  static DateTime? _optionalDateTime(Object? value) =>
      value == null ? null : _dateTime(value);

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
