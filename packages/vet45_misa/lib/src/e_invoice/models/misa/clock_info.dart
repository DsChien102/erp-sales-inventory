import '../../internal/json_helpers.dart';

/// §13.8 ClockInfo — thông tin đồng hồ nước/điện.
final class MeInvoiceClockInfo {
  const MeInvoiceClockInfo({
    this.clockOrder,
    this.clockCode,
    this.clockSeri,
    this.lastIndex,
    this.firstIndex,
    this.coefficient,
    this.refuelerNo,
    this.lotNo,
    this.startMeter,
    this.endMeter,
    this.temperature,
    this.density,
    this.gallon,
    this.liters,
    this.clockStatus,
    this.clockCodeOld,
    this.clockSeriOld,
    this.lastIndexOld,
    this.firstIndexOld,
    this.coefficientOld,
  });

  final int? clockOrder;
  final String? clockCode;
  final String? clockSeri;
  final double? lastIndex;
  final double? firstIndex;
  final double? coefficient;
  final String? refuelerNo;
  final String? lotNo;
  final double? startMeter;
  final double? endMeter;
  final double? temperature;
  final double? density;
  final double? gallon;
  final double? liters;
  final int? clockStatus;
  final String? clockCodeOld;
  final String? clockSeriOld;
  final double? lastIndexOld;
  final double? firstIndexOld;
  final double? coefficientOld;

  factory MeInvoiceClockInfo.fromJson(Map<String, dynamic> json) {
    return MeInvoiceClockInfo(
      clockOrder: MeInvoiceJsonHelpers.readInt(json, 'ClockOrder'),
      clockCode: MeInvoiceJsonHelpers.readString(json, 'ClockCode'),
      clockSeri: MeInvoiceJsonHelpers.readString(json, 'ClockSeri'),
      lastIndex: MeInvoiceJsonHelpers.readDouble(json, 'LastIndex'),
      firstIndex: MeInvoiceJsonHelpers.readDouble(json, 'FirstIndex'),
      coefficient: MeInvoiceJsonHelpers.readDouble(json, 'Coefficient'),
      refuelerNo: MeInvoiceJsonHelpers.readString(json, 'RefuelerNo'),
      lotNo: MeInvoiceJsonHelpers.readString(json, 'LotNo'),
      startMeter: MeInvoiceJsonHelpers.readDouble(json, 'StartMeter'),
      endMeter: MeInvoiceJsonHelpers.readDouble(json, 'EndMeter'),
      temperature: MeInvoiceJsonHelpers.readDouble(json, 'Temperature'),
      density: MeInvoiceJsonHelpers.readDouble(json, 'Density'),
      gallon: MeInvoiceJsonHelpers.readDouble(json, 'Gallon'),
      liters: MeInvoiceJsonHelpers.readDouble(json, 'Liters'),
      clockStatus: MeInvoiceJsonHelpers.readInt(json, 'ClockStatus'),
      clockCodeOld: MeInvoiceJsonHelpers.readString(json, 'ClockCodeOld'),
      clockSeriOld: MeInvoiceJsonHelpers.readString(json, 'ClockSeriOld'),
      lastIndexOld: MeInvoiceJsonHelpers.readDouble(json, 'LastIndexOld'),
      firstIndexOld: MeInvoiceJsonHelpers.readDouble(json, 'FirstIndexOld'),
      coefficientOld: MeInvoiceJsonHelpers.readDouble(json, 'CoefficientOld'),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    MeInvoiceJsonHelpers.writeIfPresent(map, 'ClockOrder', clockOrder);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'ClockCode', clockCode);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'ClockSeri', clockSeri);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'LastIndex', lastIndex);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'FirstIndex', firstIndex);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'Coefficient', coefficient);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'RefuelerNo', refuelerNo);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'LotNo', lotNo);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'StartMeter', startMeter);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'EndMeter', endMeter);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'Temperature', temperature);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'Density', density);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'Gallon', gallon);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'Liters', liters);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'ClockStatus', clockStatus);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'ClockCodeOld', clockCodeOld);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'ClockSeriOld', clockSeriOld);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'LastIndexOld', lastIndexOld);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'FirstIndexOld', firstIndexOld);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'CoefficientOld', coefficientOld);
    return map;
  }
}
