import '../../internal/json_helpers.dart';

/// §13.4 OriginalInvoiceDetail — dòng hàng hóa/dịch vụ.
final class MeInvoiceOriginalInvoiceDetail {
  const MeInvoiceOriginalInvoiceDetail({
    this.itemType,
    this.sortOrder,
    this.lineNumber,
    this.itemCode,
    this.itemName,
    this.unitName,
    this.expiryDate,
    this.chassisNumber,
    this.engineNumber,
    this.lotNo,
    this.quantity,
    this.unitPrice,
    this.amountOc,
    this.amount,
    this.discountRate,
    this.discountAmountOc,
    this.discountAmount,
    this.amountWithoutVatOc,
    this.amountWithoutVat,
    this.vatRateName,
    this.vatAmountOc,
    this.vatAmount,
    this.wageAmount,
    this.wageAmountOc,
    this.wagePriceAmount,
    this.wagePriceDiscountAmount,
    this.wageDiscountAmountOc,
    this.inWard,
    this.exciseTaxAmountOc,
    this.exciseTaxAmount,
    this.exciseTaxRate,
    this.unitPriceAfterExciseVat,
    this.amountAfterExciseTaxOc,
    this.amountAfterExciseTax,
    this.serviceAmountOc,
    this.serviceAmount,
    this.serviceFeeRate,
    this.typicalItem,
    this.fieldName,
    this.fieldValue,
  });

  final int? itemType;
  final int? sortOrder;
  final int? lineNumber;
  final String? itemCode;
  final String? itemName;
  final String? unitName;
  final DateTime? expiryDate;
  final String? chassisNumber;
  final String? engineNumber;
  final String? lotNo;
  final double? quantity;
  final double? unitPrice;
  final double? amountOc;
  final double? amount;
  final double? discountRate;
  final double? discountAmountOc;
  final double? discountAmount;
  final double? amountWithoutVatOc;
  final double? amountWithoutVat;
  final String? vatRateName;
  final double? vatAmountOc;
  final double? vatAmount;
  final double? wageAmount;
  final double? wageAmountOc;
  final double? wagePriceAmount;
  final double? wagePriceDiscountAmount;
  final double? wageDiscountAmountOc;
  final double? inWard;
  final double? exciseTaxAmountOc;
  final double? exciseTaxAmount;
  final double? exciseTaxRate;
  final double? unitPriceAfterExciseVat;
  final double? amountAfterExciseTaxOc;
  final double? amountAfterExciseTax;
  final double? serviceAmountOc;
  final double? serviceAmount;
  final double? serviceFeeRate;
  final int? typicalItem;
  final String? fieldName;
  final String? fieldValue;

  factory MeInvoiceOriginalInvoiceDetail.fromJson(Map<String, dynamic> json) {
    return MeInvoiceOriginalInvoiceDetail(
      itemType: MeInvoiceJsonHelpers.readInt(json, 'ItemType'),
      sortOrder: MeInvoiceJsonHelpers.readInt(json, 'SortOrder'),
      lineNumber: MeInvoiceJsonHelpers.readInt(json, 'LineNumber'),
      itemCode: MeInvoiceJsonHelpers.readString(json, 'ItemCode'),
      itemName: MeInvoiceJsonHelpers.readString(json, 'ItemName'),
      unitName: MeInvoiceJsonHelpers.readString(json, 'UnitName'),
      expiryDate: MeInvoiceJsonHelpers.readDateTime(json, 'ExpiryDate'),
      chassisNumber: MeInvoiceJsonHelpers.readString(json, 'ChassisNumber'),
      engineNumber: MeInvoiceJsonHelpers.readString(json, 'EngineNumber'),
      lotNo: MeInvoiceJsonHelpers.readString(json, 'LotNo'),
      quantity: MeInvoiceJsonHelpers.readDouble(json, 'Quantity'),
      unitPrice: MeInvoiceJsonHelpers.readDouble(json, 'UnitPrice'),
      amountOc: MeInvoiceJsonHelpers.readDouble(json, 'AmountOC'),
      amount: MeInvoiceJsonHelpers.readDouble(json, 'Amount'),
      discountRate: MeInvoiceJsonHelpers.readDouble(json, 'DiscountRate'),
      discountAmountOc: MeInvoiceJsonHelpers.readDouble(
        json,
        'DiscountAmountOC',
      ),
      discountAmount: MeInvoiceJsonHelpers.readDouble(json, 'DiscountAmount'),
      amountWithoutVatOc: MeInvoiceJsonHelpers.readDouble(
        json,
        'AmountWithoutVATOC',
      ),
      amountWithoutVat: MeInvoiceJsonHelpers.readDouble(
        json,
        'AmountWithoutVAT',
      ),
      vatRateName: MeInvoiceJsonHelpers.readString(json, 'VATRateName'),
      vatAmountOc: MeInvoiceJsonHelpers.readDouble(json, 'VATAmountOC'),
      vatAmount: MeInvoiceJsonHelpers.readDouble(json, 'VATAmount'),
      wageAmount: MeInvoiceJsonHelpers.readDouble(json, 'WageAmount'),
      wageAmountOc: MeInvoiceJsonHelpers.readDouble(json, 'WageAmountOC'),
      wagePriceAmount: MeInvoiceJsonHelpers.readDouble(
        json,
        'WagePriceAmount',
      ),
      wagePriceDiscountAmount: MeInvoiceJsonHelpers.readDouble(
        json,
        'WagePriceDiscountAmount',
      ),
      wageDiscountAmountOc: MeInvoiceJsonHelpers.readDouble(
        json,
        'WageDiscountAmountOC',
      ),
      inWard: MeInvoiceJsonHelpers.readDouble(json, 'InWard'),
      exciseTaxAmountOc: MeInvoiceJsonHelpers.readDouble(
        json,
        'ExciseTaxAmountOC',
      ),
      exciseTaxAmount: MeInvoiceJsonHelpers.readDouble(json, 'ExciseTaxAmount'),
      exciseTaxRate: MeInvoiceJsonHelpers.readDouble(json, 'ExciseTaxRate'),
      unitPriceAfterExciseVat: MeInvoiceJsonHelpers.readDouble(
        json,
        'UnitPriceAfterExciseVAT',
      ),
      amountAfterExciseTaxOc: MeInvoiceJsonHelpers.readDouble(
        json,
        'AmountAfterExciseTaxOC',
      ),
      amountAfterExciseTax: MeInvoiceJsonHelpers.readDouble(
        json,
        'AmountAfterExciseTax',
      ),
      serviceAmountOc: MeInvoiceJsonHelpers.readDouble(
        json,
        'ServiceAmountOC',
      ),
      serviceAmount: MeInvoiceJsonHelpers.readDouble(json, 'ServiceAmount'),
      serviceFeeRate: MeInvoiceJsonHelpers.readDouble(json, 'ServiceFeeRate'),
      typicalItem: MeInvoiceJsonHelpers.readInt(json, 'TypicalItem'),
      fieldName: MeInvoiceJsonHelpers.readString(json, 'FieldName'),
      fieldValue: MeInvoiceJsonHelpers.readString(json, 'FieldValue'),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    MeInvoiceJsonHelpers.writeIfPresent(map, 'ItemType', itemType);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'SortOrder', sortOrder);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'LineNumber', lineNumber);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'ItemCode', itemCode);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'ItemName', itemName);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'UnitName', unitName);
    MeInvoiceJsonHelpers.writeIfPresent(
      map,
      'ExpiryDate',
      expiryDate?.toUtc().toIso8601String(),
    );
    MeInvoiceJsonHelpers.writeStringIfPresent(
      map,
      'ChassisNumber',
      chassisNumber,
    );
    MeInvoiceJsonHelpers.writeStringIfPresent(
      map,
      'EngineNumber',
      engineNumber,
    );
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'LotNo', lotNo);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'Quantity', quantity);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'UnitPrice', unitPrice);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'AmountOC', amountOc);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'Amount', amount);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'DiscountRate', discountRate);
    MeInvoiceJsonHelpers.writeIfPresent(
      map,
      'DiscountAmountOC',
      discountAmountOc,
    );
    MeInvoiceJsonHelpers.writeIfPresent(map, 'DiscountAmount', discountAmount);
    MeInvoiceJsonHelpers.writeIfPresent(
      map,
      'AmountWithoutVATOC',
      amountWithoutVatOc,
    );
    MeInvoiceJsonHelpers.writeIfPresent(
      map,
      'AmountWithoutVAT',
      amountWithoutVat,
    );
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'VATRateName', vatRateName);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'VATAmountOC', vatAmountOc);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'VATAmount', vatAmount);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'WageAmount', wageAmount);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'WageAmountOC', wageAmountOc);
    MeInvoiceJsonHelpers.writeIfPresent(
      map,
      'WagePriceAmount',
      wagePriceAmount,
    );
    MeInvoiceJsonHelpers.writeIfPresent(
      map,
      'WagePriceDiscountAmount',
      wagePriceDiscountAmount,
    );
    MeInvoiceJsonHelpers.writeIfPresent(
      map,
      'WageDiscountAmountOC',
      wageDiscountAmountOc,
    );
    MeInvoiceJsonHelpers.writeIfPresent(map, 'InWard', inWard);
    MeInvoiceJsonHelpers.writeIfPresent(
      map,
      'ExciseTaxAmountOC',
      exciseTaxAmountOc,
    );
    MeInvoiceJsonHelpers.writeIfPresent(map, 'ExciseTaxAmount', exciseTaxAmount);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'ExciseTaxRate', exciseTaxRate);
    MeInvoiceJsonHelpers.writeIfPresent(
      map,
      'UnitPriceAfterExciseVAT',
      unitPriceAfterExciseVat,
    );
    MeInvoiceJsonHelpers.writeIfPresent(
      map,
      'AmountAfterExciseTaxOC',
      amountAfterExciseTaxOc,
    );
    MeInvoiceJsonHelpers.writeIfPresent(
      map,
      'AmountAfterExciseTax',
      amountAfterExciseTax,
    );
    MeInvoiceJsonHelpers.writeIfPresent(map, 'ServiceAmountOC', serviceAmountOc);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'ServiceAmount', serviceAmount);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'ServiceFeeRate', serviceFeeRate);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'TypicalItem', typicalItem);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'FieldName', fieldName);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'FieldValue', fieldValue);
    return map;
  }
}
