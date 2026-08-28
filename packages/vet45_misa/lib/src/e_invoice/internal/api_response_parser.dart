import 'dart:convert';

import '../models/me_invoice_result.dart';
import '../models/responses/api_response.dart';
import '../models/responses/publish_invoice_result.dart';
import 'error_mapper.dart';
import 'json_helpers.dart';

/// Parses MISA HTTP JSON into [MeInvoiceApiResponse] and validates errors.
abstract final class MeInvoiceApiResponseParser {
  static MeInvoiceResult<MeInvoiceApiResponse> parse(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return MeInvoiceResult.failed(
          'meinvoice_invalid_response: not a JSON object',
        );
      }
      final map = Map<String, dynamic>.from(decoded);
      final envelope = MeInvoiceApiResponse.fromJson(map);
      if (!envelope.success) {
        return MeInvoiceErrorMapper.fromVendorPayload(map);
      }
      if (envelope.errorCode != null && envelope.errorCode!.isNotEmpty) {
        return MeInvoiceErrorMapper.fromVendorPayload(map);
      }
      return MeInvoiceResult.ok(envelope);
    } on Object catch (e) {
      return MeInvoiceResult.failed('meinvoice_invalid_response: $e');
    }
  }

  static String? _firstPublishError(
    List<MeInvoicePublishInvoiceResultItem>? items,
  ) {
    if (items == null) {
      return null;
    }
    for (final item in items) {
      if (!item.isSuccess) {
        final code = item.errorCode ?? 'publish_item_error';
        final desc = item.descriptionErrorCode;
        if (desc != null && desc.isNotEmpty) {
          return '$code: $desc';
        }
        return code;
      }
    }
    return null;
  }

  /// Returns the first publish-item error string, if any.
  static String? firstPublishItemError(
    List<MeInvoicePublishInvoiceResultItem>? items,
  ) =>
      _firstPublishError(items);

  static List<T> parseDataList<T>(
    Object? data,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    return MeInvoiceJsonHelpers.asList(data)
        .map(MeInvoiceJsonHelpers.asMap)
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList();
  }

  static String? parseDataString(Object? data) {
    if (data == null) {
      return null;
    }
    if (data is String) {
      return data.isEmpty ? null : data;
    }
    return data.toString();
  }
}
