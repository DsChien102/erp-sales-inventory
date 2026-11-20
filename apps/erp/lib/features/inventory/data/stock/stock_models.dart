import 'package:equatable/equatable.dart';
import 'package:erp/features/inventory/data/models/lot_date.dart';

/// Dựng [LotDate] từ `expiry_date` (ISO YYYY-MM-DD) và `expiry_precision` ('DAY' | 'MONTH' | 'YEAR').
LotDate? lotDateFromJson(String? expiryDate, String? expiryPrecision) {
  if (expiryDate == null || expiryDate.trim().isEmpty) return null;
  final parsed = DateTime.tryParse(expiryDate.trim());
  if (parsed == null) return null;

  final p = (expiryPrecision ?? 'DAY').trim().toUpperCase();
  return switch (p) {
    'YEAR' => LotDate(year: parsed.year),
    'MONTH' => LotDate(year: parsed.year, month: parsed.month),
    _ => LotDate(year: parsed.year, month: parsed.month, day: parsed.day),
  };
}

class StockOverviewItem extends Equatable {
  final String productId;
  final String name;
  final String code;
  final String barcode;
  final String uom;
  final bool isLotTracked;
  final num physical;
  final num available;
  final bool hasExpired;
  final bool hasNearExpiry;
  final num? threshold;

  const StockOverviewItem({
    required this.productId,
    required this.name,
    required this.code,
    this.barcode = '',
    required this.uom,
    required this.isLotTracked,
    required this.physical,
    required this.available,
    this.hasExpired = false,
    this.hasNearExpiry = false,
    this.threshold,
  });

  factory StockOverviewItem.fromJson(Map<String, dynamic> json) {
    return StockOverviewItem(
      productId: json['product_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      uom: json['base_uom'] as String? ?? '',
      isLotTracked: json['is_lot_tracked'] as bool? ?? false,
      physical: (json['physical'] as num?) ?? 0,
      available: (json['available'] as num?) ?? 0,
      hasExpired: json['has_expired'] as bool? ?? false,
      hasNearExpiry: json['has_near_expiry'] as bool? ?? false,
      threshold: json['reorder_threshold'] as num?,
    );
  }

  @override
  List<Object?> get props => [
        productId,
        name,
        code,
        barcode,
        uom,
        isLotTracked,
        physical,
        available,
        hasExpired,
        hasNearExpiry,
        threshold,
      ];
}

class StockOverview extends Equatable {
  final DateTime asOf;
  final String warehouseName;
  final List<StockOverviewItem> products;

  const StockOverview({
    required this.asOf,
    required this.warehouseName,
    required this.products,
  });

  factory StockOverview.fromJson(Map<String, dynamic> json) {
    final rawAsOf = json['as_of'] as String?;
    final parsedAsOf =
        rawAsOf != null ? DateTime.parse(rawAsOf).toLocal() : DateTime.now();
    final rawProducts = (json['products'] as List?) ?? const [];

    return StockOverview(
      asOf: parsedAsOf,
      warehouseName: json['warehouse_name'] as String? ?? '',
      products: rawProducts
          .map(
            (e) => StockOverviewItem.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }

  @override
  List<Object?> get props => [asOf, warehouseName, products];
}

class StockLot extends Equatable {
  final String lotId;
  final String code;
  final LotDate? expiry;
  final num physical;
  final bool isExpired;
  final bool isNearExpiry;
  final int? daysToExpiry;

  const StockLot({
    required this.lotId,
    required this.code,
    this.expiry,
    required this.physical,
    this.isExpired = false,
    this.isNearExpiry = false,
    this.daysToExpiry,
  });

  factory StockLot.fromJson(Map<String, dynamic> json) {
    return StockLot(
      lotId: json['lot_id'] as String? ?? '',
      code: json['lot_code'] as String? ?? '',
      expiry: lotDateFromJson(
        json['expiry_date'] as String?,
        json['expiry_precision'] as String?,
      ),
      physical: (json['physical'] as num?) ?? 0,
      isExpired: json['is_expired'] as bool? ?? false,
      isNearExpiry: json['is_near_expiry'] as bool? ?? false,
      daysToExpiry: (json['days_to_expiry'] as num?)?.toInt(),
    );
  }

  @override
  List<Object?> get props => [
        lotId,
        code,
        expiry,
        physical,
        isExpired,
        isNearExpiry,
        daysToExpiry,
      ];
}

class StockLatestMovement extends Equatable {
  final String kind;
  final String intentType;
  final String intentId;
  final num delta;
  final DateTime businessDate;

  const StockLatestMovement({
    required this.kind,
    required this.intentType,
    required this.intentId,
    required this.delta,
    required this.businessDate,
  });

  String get label => switch (kind) {
        'RECEIPT' => 'Nhận hàng',
        'SALE' => 'Xuất bán',
        'SALE_REVERSAL' => 'Huỷ bán',
        'RETURN_IN' => 'Khách trả',
        'COUNT_GAIN' || 'COUNT_LOSS' => 'Kiểm kê',
        'WRITE_OFF' => 'Điều chỉnh giảm',
        _ => 'Biến động',
      };

  factory StockLatestMovement.fromJson(Map<String, dynamic> json) {
    final rawDate = json['business_date'] as String?;
    final parsedDate =
        rawDate != null ? DateTime.parse(rawDate) : DateTime.now();

    return StockLatestMovement(
      kind: json['movement_kind'] as String? ?? '',
      intentType: json['intent_type'] as String? ?? '',
      intentId: json['intent_id'] as String? ?? '',
      delta: (json['quantity_delta'] as num?) ?? 0,
      businessDate: parsedDate,
    );
  }

  @override
  List<Object?> get props => [kind, intentType, intentId, delta, businessDate];
}

enum CostMethod { moving, periodic }

class StockCost extends Equatable {
  final CostMethod method;
  final num? officialUnitCost;
  final num? movingAvgCost;
  final int ledgerValueVnd;

  const StockCost({
    required this.method,
    this.officialUnitCost,
    this.movingAvgCost,
    required this.ledgerValueVnd,
  });

  bool get provisional =>
      method == CostMethod.periodic && officialUnitCost == null;

  factory StockCost.fromJson(Map<String, dynamic> json) {
    final rawMethod = (json['method'] as String? ?? 'MOVING').toUpperCase();
    return StockCost(
      method:
          rawMethod == 'PERIODIC' ? CostMethod.periodic : CostMethod.moving,
      officialUnitCost: json['official_unit_cost'] as num?,
      movingAvgCost: json['moving_avg_cost'] as num?,
      ledgerValueVnd: (json['ledger_value_vnd'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        method,
        officialUnitCost,
        movingAvgCost,
        ledgerValueVnd,
      ];
}

class StockDetail extends Equatable {
  final DateTime asOf;
  final String warehouseName;
  final bool isOwner;
  final String productId;
  final String name;
  final String code;
  final String uom;
  final bool isLotTracked;
  final num physical;
  final num available;
  final num expiredQuantity;
  final num? threshold;
  final num? target;
  final List<StockLot> lots;
  final StockLatestMovement? latestMovement;
  final StockCost? cost;

  const StockDetail({
    required this.asOf,
    required this.warehouseName,
    required this.isOwner,
    required this.productId,
    required this.name,
    required this.code,
    required this.uom,
    required this.isLotTracked,
    required this.physical,
    required this.available,
    required this.expiredQuantity,
    this.threshold,
    this.target,
    this.lots = const [],
    this.latestMovement,
    this.cost,
  });

  factory StockDetail.fromJson(Map<String, dynamic> json) {
    final rawAsOf = json['as_of'] as String?;
    final parsedAsOf =
        rawAsOf != null ? DateTime.parse(rawAsOf).toLocal() : DateTime.now();

    final productMap = json['product'] is Map
        ? Map<String, dynamic>.from(json['product'] as Map)
        : json;

    final rawLots = (json['lots'] as List?) ?? const [];
    final rawMovement = json['latest_movement'];
    final rawCost = json['cost'];
    final masked = json['financial_masked'] as bool? ?? false;

    return StockDetail(
      asOf: parsedAsOf,
      warehouseName: json['warehouse_name'] as String? ?? '',
      isOwner: json['is_owner'] as bool? ?? false,
      productId: productMap['product_id'] as String? ?? '',
      name: productMap['name'] as String? ?? '',
      code: productMap['code'] as String? ?? '',
      uom: productMap['base_uom'] as String? ?? '',
      isLotTracked: productMap['is_lot_tracked'] as bool? ?? false,
      physical: (json['physical'] as num?) ?? 0,
      available: (json['available'] as num?) ?? 0,
      expiredQuantity: (json['expired_quantity'] as num?) ?? 0,
      threshold: json['reorder_threshold'] as num?,
      target: json['target_level'] as num?,
      lots: rawLots
          .map((e) => StockLot.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      latestMovement: rawMovement is Map
          ? StockLatestMovement.fromJson(Map<String, dynamic>.from(rawMovement))
          : null,
      cost: (!masked && rawCost is Map)
          ? StockCost.fromJson(Map<String, dynamic>.from(rawCost))
          : null,
    );
  }

  @override
  List<Object?> get props => [
        asOf,
        warehouseName,
        isOwner,
        productId,
        name,
        code,
        uom,
        isLotTracked,
        physical,
        available,
        expiredQuantity,
        threshold,
        target,
        lots,
        latestMovement,
        cost,
      ];
}

