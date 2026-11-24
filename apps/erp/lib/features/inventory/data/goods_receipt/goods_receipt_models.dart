import 'package:equatable/equatable.dart';
import 'package:erp/features/inventory/data/models/lot_date.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';

/// Tuỳ chọn nạp sẵn cho form nhận hàng.
class ReceiptFormOptions extends Equatable {
  const ReceiptFormOptions({
    required this.warehouseName,
    required this.today,
    required this.suppliers,
    required this.products,
    required this.lots,
  });

  factory ReceiptFormOptions.fromJson(Map<String, dynamic> json) {
    return ReceiptFormOptions(
      warehouseName: json['warehouse_name'] as String? ?? '',
      today: json['today'] as String? ?? '',
      suppliers: (json['suppliers'] as List<dynamic>? ?? const [])
          .map((e) => ReceiptSupplierOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      products: (json['products'] as List<dynamic>? ?? const [])
          .map((e) => ReceiptProductOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      lots: (json['lots'] as List<dynamic>? ?? const [])
          .map((e) => KnownLot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String warehouseName;
  final String today;
  final List<ReceiptSupplierOption> suppliers;
  final List<ReceiptProductOption> products;
  final List<KnownLot> lots;

  @override
  List<Object?> get props => [warehouseName, today, suppliers, products, lots];
}

class ReceiptSupplierOption extends Equatable {
  const ReceiptSupplierOption({
    required this.id,
    required this.name,
    this.code,
    this.isSystem = false,
  });

  factory ReceiptSupplierOption.fromJson(Map<String, dynamic> json) {
    return ReceiptSupplierOption(
      id: json['partner_id'] as String,
      name: json['display_name'] as String,
      code: json['code'] as String?,
      isSystem: json['is_system'] as bool? ?? false,
    );
  }

  final String id;
  final String name;
  final String? code;
  final bool isSystem;

  @override
  List<Object?> get props => [id, name, code, isSystem];
}

class ReceiptProductOption extends Equatable {
  const ReceiptProductOption({
    required this.id,
    required this.name,
    required this.code,
    this.barcode,
    required this.baseUom,
    required this.isLotTracked,
    required this.expiryRequired,
    required this.units,
  });

  factory ReceiptProductOption.fromJson(Map<String, dynamic> json) {
    final trackingMode = json['tracking_mode'] as String? ?? 'none';
    return ReceiptProductOption(
      id: json['product_id'] as String,
      name: json['name'] as String,
      code: json['code'] as String? ?? '',
      barcode: json['barcode'] as String?,
      baseUom: json['base_uom'] as String? ?? '',
      isLotTracked: trackingMode == 'lot',
      expiryRequired: json['expiry_required'] as bool? ?? false,
      units: (json['units'] as List<dynamic>? ?? const [])
          .map((e) => ReceiptUnitOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String name;
  final String code;
  final String? barcode;
  final String baseUom;
  final bool isLotTracked;
  final bool expiryRequired;
  final List<ReceiptUnitOption> units;

  ReceiptUnitOption get baseUnit =>
      units.firstWhere((u) => u.isBase, orElse: () => units.first);

  @override
  List<Object?> get props => [id, name, code, barcode, baseUom, isLotTracked, expiryRequired, units];
}

class ReceiptUnitOption extends Equatable {
  const ReceiptUnitOption({
    required this.id,
    required this.name,
    required this.rate,
    required this.isBase,
  });

  factory ReceiptUnitOption.fromJson(Map<String, dynamic> json) {
    return ReceiptUnitOption(
      id: json['unit_id'] as String,
      name: json['name'] as String,
      rate: (json['rate'] as num).toDouble(),
      isBase: json['is_base'] as bool? ?? false,
    );
  }

  final String id;
  final String name;
  final double rate;
  final bool isBase;

  @override
  List<Object?> get props => [id, name, rate, isBase];
}

class KnownLot extends Equatable {
  const KnownLot({
    required this.productId,
    required this.code,
    this.expiry,
    this.manufacture,
  });

  factory KnownLot.fromJson(Map<String, dynamic> json) {
    final expStr = json['expiry_date'] as String?;
    final expPrecStr = json['expiry_precision'] as String?;
    LotDate? exp;
    if (expStr != null && expPrecStr != null) {
      final prec = switch (expPrecStr.toUpperCase()) {
        'DAY' => DatePrecision.day,
        'MONTH' => DatePrecision.month,
        'YEAR' => DatePrecision.year,
        _ => DatePrecision.day,
      };
      // Format YYYY-MM-DD -> convert to DD/MM/YYYY or MM/YYYY or YYYY
      final parts = expStr.split('-');
      if (parts.length == 3) {
        final year = int.tryParse(parts[0]) ?? 2000;
        final month = int.tryParse(parts[1]);
        final day = int.tryParse(parts[2]);
        exp = switch (prec) {
          DatePrecision.day => LotDate(year: year, month: month, day: day),
          DatePrecision.month => LotDate(year: year, month: month),
          DatePrecision.year => LotDate(year: year),
        };
      }
    }

    final mfgStr = json['manufacture_date'] as String?;
    final mfgPrecStr = json['manufacture_precision'] as String?;
    LotDate? mfg;
    if (mfgStr != null && mfgPrecStr != null) {
      final prec = switch (mfgPrecStr.toUpperCase()) {
        'DAY' => DatePrecision.day,
        'MONTH' => DatePrecision.month,
        'YEAR' => DatePrecision.year,
        _ => DatePrecision.day,
      };
      final parts = mfgStr.split('-');
      if (parts.length == 3) {
        final year = int.tryParse(parts[0]) ?? 2000;
        final month = int.tryParse(parts[1]);
        final day = int.tryParse(parts[2]);
        mfg = switch (prec) {
          DatePrecision.day => LotDate(year: year, month: month, day: day),
          DatePrecision.month => LotDate(year: year, month: month),
          DatePrecision.year => LotDate(year: year),
        };
      }
    }

    return KnownLot(
      productId: json['product_id'] as String,
      code: json['lot_code'] as String,
      expiry: exp,
      manufacture: mfg,
    );
  }

  final String productId;
  final String code;
  final LotDate? expiry;
  final LotDate? manufacture;

  @override
  List<Object?> get props => [productId, code, expiry, manufacture];
}

class RecordReceiptResult extends Equatable {
  const RecordReceiptResult({
    required this.receiptId,
    required this.receiptNo,
    required this.supplierName,
    this.supplierDocNo,
    required this.businessDate,
    required this.lineCount,
    required this.lotCount,
    required this.landedTotalVnd,
    required this.createdByName,
    required this.stockChanges,
    required this.reachedPrograms,
  });

  factory RecordReceiptResult.fromJson(Map<String, dynamic> json) {
    return RecordReceiptResult(
      receiptId: json['receipt_id'] as String,
      receiptNo: json['receipt_no'] as String,
      supplierName: json['supplier_name'] as String? ?? '',
      supplierDocNo: json['supplier_doc_no'] as String?,
      businessDate: json['business_date'] as String? ?? '',
      lineCount: json['line_count'] as int? ?? 0,
      lotCount: json['lot_count'] as int? ?? 0,
      landedTotalVnd: (json['landed_total_vnd'] as num?)?.toInt() ?? 0,
      createdByName: json['created_by_name'] as String? ?? '',
      stockChanges: (json['stock_changes'] as List<dynamic>? ?? const [])
          .map((e) => K4StockChangeData.fromJson(e as Map<String, dynamic>))
          .toList(),
      reachedPrograms: (json['reached_programs'] as List<dynamic>? ?? const [])
          .map((e) => ReceiptReachedProgram.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String receiptId;
  final String receiptNo;
  final String supplierName;
  final String? supplierDocNo;
  final String businessDate;
  final int lineCount;
  final int lotCount;
  final int landedTotalVnd;
  final String createdByName;
  final List<K4StockChangeData> stockChanges;
  final List<ReceiptReachedProgram> reachedPrograms;

  @override
  List<Object?> get props => [
        receiptId,
        receiptNo,
        supplierName,
        supplierDocNo,
        businessDate,
        lineCount,
        lotCount,
        landedTotalVnd,
        createdByName,
        stockChanges,
        reachedPrograms,
      ];
}

class K4StockChangeData extends Equatable {
  const K4StockChangeData({
    required this.productName,
    required this.baseUom,
    required this.before,
    required this.after,
  });

  factory K4StockChangeData.fromJson(Map<String, dynamic> json) {
    return K4StockChangeData(
      productName: json['product_name'] as String,
      baseUom: json['base_uom'] as String,
      before: (json['before'] as num).toDouble(),
      after: (json['after'] as num).toDouble(),
    );
  }

  final String productName;
  final String baseUom;
  final double before;
  final double after;

  @override
  List<Object?> get props => [productName, baseUom, before, after];
}

class ReceiptReachedProgram extends Equatable {
  const ReceiptReachedProgram({
    required this.programId,
    required this.name,
  });

  factory ReceiptReachedProgram.fromJson(Map<String, dynamic> json) {
    return ReceiptReachedProgram(
      programId: json['program_id'] as String,
      name: json['name'] as String,
    );
  }

  final String programId;
  final String name;

  @override
  List<Object?> get props => [programId, name];
}

class ReceiptListRow extends Equatable {
  const ReceiptListRow({
    required this.receiptId,
    required this.receiptNo,
    required this.supplierId,
    required this.supplierName,
    required this.supplierIsSystem,
    this.supplierDocNo,
    required this.businessDate,
    required this.lineCount,
    required this.lotCount,
    required this.landedTotalVnd,
    required this.createdByName,
    required this.createdAt,
  });

  factory ReceiptListRow.fromJson(Map<String, dynamic> json) {
    return ReceiptListRow(
      receiptId: json['receipt_id'] as String,
      receiptNo: json['receipt_no'] as String,
      supplierId: json['supplier_id'] as String,
      supplierName: json['supplier_name'] as String? ?? '',
      supplierIsSystem: json['supplier_is_system'] as bool? ?? false,
      supplierDocNo: json['supplier_doc_no'] as String?,
      businessDate: json['business_date'] as String? ?? '',
      lineCount: json['line_count'] as int? ?? 0,
      lotCount: json['lot_count'] as int? ?? 0,
      landedTotalVnd: (json['landed_total_vnd'] as num?)?.toInt() ?? 0,
      createdByName: json['created_by_name'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  final String receiptId;
  final String receiptNo;
  final String supplierId;
  final String supplierName;
  final bool supplierIsSystem;
  final String? supplierDocNo;
  final String businessDate;
  final int lineCount;
  final int lotCount;
  final int landedTotalVnd;
  final String createdByName;
  final String createdAt;

  @override
  List<Object?> get props => [
        receiptId,
        receiptNo,
        supplierId,
        supplierName,
        supplierIsSystem,
        supplierDocNo,
        businessDate,
        lineCount,
        lotCount,
        landedTotalVnd,
        createdByName,
        createdAt,
      ];
}

class ReceiptDetail extends Equatable {
  const ReceiptDetail({
    required this.header,
    required this.lines,
  });

  factory ReceiptDetail.fromJson(Map<String, dynamic> json) {
    return ReceiptDetail(
      header: ReceiptHeader.fromJson(json['receipt'] as Map<String, dynamic>),
      lines: (json['lines'] as List<dynamic>? ?? const [])
          .map((e) => ReceiptDetailLine.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final ReceiptHeader header;
  final List<ReceiptDetailLine> lines;

  @override
  List<Object?> get props => [header, lines];
}

class ReceiptHeader extends Equatable {
  const ReceiptHeader({
    required this.receiptId,
    required this.receiptNo,
    required this.supplierId,
    required this.supplierName,
    required this.supplierIsSystem,
    this.supplierDocNo,
    required this.businessDate,
    required this.warehouseName,
    required this.freightCostVnd,
    required this.tradeDiscountVnd,
    required this.purchaseTotalVnd,
    required this.landedTotalVnd,
    required this.lineCount,
    required this.lotCount,
    required this.createdByName,
    required this.createdAt,
  });

  factory ReceiptHeader.fromJson(Map<String, dynamic> json) {
    return ReceiptHeader(
      receiptId: json['receipt_id'] as String,
      receiptNo: json['receipt_no'] as String,
      supplierId: json['supplier_id'] as String,
      supplierName: json['supplier_name'] as String? ?? '',
      supplierIsSystem: json['supplier_is_system'] as bool? ?? false,
      supplierDocNo: json['supplier_doc_no'] as String?,
      businessDate: json['business_date'] as String? ?? '',
      warehouseName: json['warehouse_name'] as String? ?? '',
      freightCostVnd: (json['freight_cost_vnd'] as num?)?.toInt() ?? 0,
      tradeDiscountVnd: (json['trade_discount_vnd'] as num?)?.toInt() ?? 0,
      purchaseTotalVnd: (json['purchase_total_vnd'] as num?)?.toInt() ?? 0,
      landedTotalVnd: (json['landed_total_vnd'] as num?)?.toInt() ?? 0,
      lineCount: json['line_count'] as int? ?? 0,
      lotCount: json['lot_count'] as int? ?? 0,
      createdByName: json['created_by_name'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  final String receiptId;
  final String receiptNo;
  final String supplierId;
  final String supplierName;
  final bool supplierIsSystem;
  final String? supplierDocNo;
  final String businessDate;
  final String warehouseName;
  final int freightCostVnd;
  final int tradeDiscountVnd;
  final int purchaseTotalVnd;
  final int landedTotalVnd;
  final int lineCount;
  final int lotCount;
  final String createdByName;
  final String createdAt;

  @override
  List<Object?> get props => [
        receiptId,
        receiptNo,
        supplierId,
        supplierName,
        supplierIsSystem,
        supplierDocNo,
        businessDate,
        warehouseName,
        freightCostVnd,
        tradeDiscountVnd,
        purchaseTotalVnd,
        landedTotalVnd,
        lineCount,
        lotCount,
        createdByName,
        createdAt,
      ];
}

class ReceiptDetailLine extends Equatable {
  const ReceiptDetailLine({
    required this.lineId,
    required this.lineNo,
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.baseUom,
    required this.unitName,
    required this.conversionRate,
    required this.paidQty,
    required this.freeQty,
    required this.unitPriceVnd,
    required this.grossAmountVnd,
    this.programId,
    this.programName,
    this.programKind,
    this.tierDiscountPercent,
    required this.tierDiscountVnd,
    required this.purchaseAmountVnd,
    required this.allocatedFreightVnd,
    required this.allocatedDiscountVnd,
    required this.landedAmountVnd,
    required this.landedUnitCost,
    required this.lots,
  });

  factory ReceiptDetailLine.fromJson(Map<String, dynamic> json) {
    ProgramKind? kind;
    final kindStr = json['program_kind'] as String?;
    if (kindStr != null) {
      kind = switch (kindStr) {
        'BUY_X_GET_Y' => ProgramKind.buyXGetY,
        'TIER_DISCOUNT' => ProgramKind.tierDiscount,
        'VOLUME_REBATE' => ProgramKind.volumeRebate,
        _ => null,
      };
    }

    return ReceiptDetailLine(
      lineId: json['line_id'] as String,
      lineNo: json['line_no'] as int,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String? ?? '',
      productCode: json['product_code'] as String? ?? '',
      baseUom: json['base_uom'] as String? ?? '',
      unitName: json['unit_name'] as String? ?? '',
      conversionRate: (json['conversion_rate'] as num).toDouble(),
      paidQty: (json['paid_qty'] as num).toDouble(),
      freeQty: (json['free_qty'] as num).toDouble(),
      unitPriceVnd: (json['unit_price_vnd'] as num).toInt(),
      grossAmountVnd: (json['gross_amount_vnd'] as num).toInt(),
      programId: json['program_id'] as String?,
      programName: json['program_name'] as String?,
      programKind: kind,
      tierDiscountPercent: (json['tier_discount_percent'] as num?)?.toDouble(),
      tierDiscountVnd: (json['tier_discount_vnd'] as num?)?.toInt() ?? 0,
      purchaseAmountVnd: (json['purchase_amount_vnd'] as num).toInt(),
      allocatedFreightVnd: (json['allocated_freight_vnd'] as num?)?.toInt() ?? 0,
      allocatedDiscountVnd: (json['allocated_discount_vnd'] as num?)?.toInt() ?? 0,
      landedAmountVnd: (json['landed_amount_vnd'] as num).toInt(),
      landedUnitCost: (json['landed_unit_cost'] as num).toDouble(),
      lots: (json['lots'] as List<dynamic>? ?? const [])
          .map((e) => ReceiptDetailLot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String lineId;
  final int lineNo;
  final String productId;
  final String productName;
  final String productCode;
  final String baseUom;
  final String unitName;
  final double conversionRate;
  final double paidQty;
  final double freeQty;
  final int unitPriceVnd;
  final int grossAmountVnd;
  final String? programId;
  final String? programName;
  final ProgramKind? programKind;
  final double? tierDiscountPercent;
  final int tierDiscountVnd;
  final int purchaseAmountVnd;
  final int allocatedFreightVnd;
  final int allocatedDiscountVnd;
  final int landedAmountVnd;
  final double landedUnitCost;
  final List<ReceiptDetailLot> lots;

  @override
  List<Object?> get props => [
        lineId,
        lineNo,
        productId,
        productName,
        productCode,
        baseUom,
        unitName,
        conversionRate,
        paidQty,
        freeQty,
        unitPriceVnd,
        grossAmountVnd,
        programId,
        programName,
        programKind,
        tierDiscountPercent,
        tierDiscountVnd,
        purchaseAmountVnd,
        allocatedFreightVnd,
        allocatedDiscountVnd,
        landedAmountVnd,
        landedUnitCost,
        lots,
      ];
}

class ReceiptDetailLot extends Equatable {
  const ReceiptDetailLot({
    this.lotCode,
    this.expiryDate,
    this.manufactureDate,
    required this.quantity,
    this.allocatedLandedCostVnd,
  });

  factory ReceiptDetailLot.fromJson(Map<String, dynamic> json) {
    return ReceiptDetailLot(
      lotCode: json['lot_code'] as String?,
      expiryDate: json['expiry_date'] as String?,
      manufactureDate: json['manufacture_date'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      allocatedLandedCostVnd: (json['allocated_landed_cost_vnd'] as num?)?.toInt(),
    );
  }

  final String? lotCode;
  final String? expiryDate;
  final String? manufactureDate;
  final double quantity;
  final int? allocatedLandedCostVnd;

  @override
  List<Object?> get props => [lotCode, expiryDate, manufactureDate, quantity, allocatedLandedCostVnd];
}

