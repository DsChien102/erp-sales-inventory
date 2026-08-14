import '../../internal/json_helpers.dart';

/// §13.6 OtherInfo — thông tin khác.
final class MeInvoiceOtherInfo {
  const MeInvoiceOtherInfo({
    this.fieldName,
    this.dataType,
    this.fieldValue,
  });

  final String? fieldName;
  final String? dataType;
  final String? fieldValue;

  factory MeInvoiceOtherInfo.fromJson(Map<String, dynamic> json) {
    return MeInvoiceOtherInfo(
      fieldName: MeInvoiceJsonHelpers.readString(json, 'FieldName'),
      dataType: MeInvoiceJsonHelpers.readString(json, 'DataType'),
      fieldValue: MeInvoiceJsonHelpers.readString(json, 'FieldValue'),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'FieldName', fieldName);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'DataType', dataType);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'FieldValue', fieldValue);
    return map;
  }
}
