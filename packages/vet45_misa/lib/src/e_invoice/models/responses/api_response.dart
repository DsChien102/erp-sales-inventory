import '../../internal/json_helpers.dart';
import 'create_invoice_result.dart';
import 'publish_invoice_result.dart';

/// MISA API response envelope (§1.3 / §1.4).
final class MeInvoiceApiResponse {
  const MeInvoiceApiResponse({
    required this.success,
    this.errorCode,
    this.descriptionErrorCode,
    this.errors,
    this.data,
    this.customData,
    this.createInvoiceResult,
    this.publishInvoiceResult,
  });

  final bool success;
  final String? errorCode;
  final String? descriptionErrorCode;
  final Object? errors;
  final Object? data;
  final Object? customData;
  final List<MeInvoiceCreateInvoiceResultItem>? createInvoiceResult;
  final List<MeInvoicePublishInvoiceResultItem>? publishInvoiceResult;

  factory MeInvoiceApiResponse.fromJson(Map<String, dynamic> json) {
    return MeInvoiceApiResponse(
      success: MeInvoiceJsonHelpers.readSuccess(json) ?? false,
      errorCode: MeInvoiceJsonHelpers.readErrorCode(json),
      descriptionErrorCode: MeInvoiceJsonHelpers.readString(
        json,
        'descriptionErrorCode',
      ),
      errors: json['Errors'] ?? json['errors'],
      data: json['Data'] ?? json['data'],
      customData: json['CustomData'] ?? json['customData'],
      createInvoiceResult: _parseCreateResults(
        json['createInvoiceResult'],
      ),
      publishInvoiceResult: _parsePublishResults(
        json['publishInvoiceResult'],
      ),
    );
  }

  static List<MeInvoiceCreateInvoiceResultItem>? _parseCreateResults(
    Object? raw,
  ) {
    final list = MeInvoiceJsonHelpers.asList(raw);
    if (list.isEmpty) {
      return null;
    }
    return list
        .map(MeInvoiceJsonHelpers.asMap)
        .whereType<Map<String, dynamic>>()
        .map(MeInvoiceCreateInvoiceResultItem.fromJson)
        .toList();
  }

  static List<MeInvoicePublishInvoiceResultItem>? _parsePublishResults(
    Object? raw,
  ) {
    final list = MeInvoiceJsonHelpers.asList(raw);
    if (list.isEmpty) {
      return null;
    }
    return list
        .map(MeInvoiceJsonHelpers.asMap)
        .whereType<Map<String, dynamic>>()
        .map(MeInvoicePublishInvoiceResultItem.fromJson)
        .toList();
  }
}
