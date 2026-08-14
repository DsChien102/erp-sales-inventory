import '../../internal/json_helpers.dart';

/// §13.7 FeeInfo — phí khác.
final class MeInvoiceFeeInfo {
  const MeInvoiceFeeInfo({this.feeName, this.feeAmountOc});

  final String? feeName;
  final double? feeAmountOc;

  factory MeInvoiceFeeInfo.fromJson(Map<String, dynamic> json) {
    return MeInvoiceFeeInfo(
      feeName: MeInvoiceJsonHelpers.readString(json, 'FeeName'),
      feeAmountOc: MeInvoiceJsonHelpers.readDouble(json, 'FeeAmountOC'),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'FeeName', feeName);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'FeeAmountOC', feeAmountOc);
    return map;
  }
}
