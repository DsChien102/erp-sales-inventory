import 'package:equatable/equatable.dart';

num _num(dynamic v) {
  if (v is num) return v;
  if (v is String) return num.tryParse(v.trim()) ?? 0;
  return 0;
}

num? _numOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  if (v is String) return num.tryParse(v.trim());
  return null;
}

int _int(dynamic v) => _num(v).toInt();

int? _intOrNull(dynamic v) => _numOrNull(v)?.toInt();

String _str(dynamic v) => v is String ? v : '';

String? _strOrNull(dynamic v) => v is String && v.isNotEmpty ? v : null;

DateTime _date(dynamic v) {
  if (v is String && v.trim().isNotEmpty) {
    final parsed = DateTime.tryParse(v.trim());
    if (parsed != null) return DateTime(parsed.year, parsed.month, parsed.day);
  }
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime _dateTime(dynamic v) {
  if (v is String && v.trim().isNotEmpty) {
    final parsed = DateTime.tryParse(v.trim());
    if (parsed != null) return parsed.toLocal();
  }
  return DateTime.now();
}

List<Map<String, dynamic>> _list(dynamic v) {
  if (v is! List) return const [];
  return [
    for (final e in v)
      if (e is Map) Map<String, dynamic>.from(e),
  ];
}

Map<String, dynamic> _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : const <String, dynamic>{};

// ---------------------------------------------------------------------------
// SCR-055 báo cáo nhập – xuất – tồn
// ---------------------------------------------------------------------------

class StockReportRow extends Equatable {
  const StockReportRow({
    required this.productId,
    required this.name,
    required this.code,
    required this.uom,
    required this.openingQty,
    required this.inQty,
    required this.outQty,
    required this.closingQty,
    this.available,
    this.closingValue,
  });

  final String productId;
  final String name;
  final String code;
  final String uom;
  final num openingQty;
  final num inQty;
  final num outQty;
  final num closingQty;
  final num? available;
  final int? closingValue;

  factory StockReportRow.fromJson(Map<String, dynamic> json) {
    return StockReportRow(
      productId: _str(json['product_id']),
      name: _str(json['name']),
      code: _str(json['code']),
      uom: _str(json['uom']),
      openingQty: _num(json['opening_qty']),
      inQty: _num(json['in_qty']),
      outQty: _num(json['out_qty']),
      closingQty: _num(json['closing_qty']),
      available: _numOrNull(json['available']),
      closingValue: _intOrNull(json['closing_value']),
    );
  }

  @override
  List<Object?> get props => [
        productId,
        name,
        code,
        uom,
        openingQty,
        inQty,
        outQty,
        closingQty,
        available,
        closingValue,
      ];
}

class StockReport extends Equatable {
  const StockReport({
    required this.from,
    required this.to,
    required this.asOf,
    required this.showAvailable,
    required this.financialMasked,
    required this.rows,
    this.totalClosingValue,
  });

  final DateTime from;
  final DateTime to;
  final DateTime asOf;
  final bool showAvailable;
  final bool financialMasked;
  final List<StockReportRow> rows;
  final int? totalClosingValue;

  factory StockReport.fromJson(Map<String, dynamic> json) {
    return StockReport(
      from: _date(json['from']),
      to: _date(json['to']),
      asOf: _dateTime(json['as_of']),
      showAvailable: json['show_available'] as bool? ?? false,
      financialMasked: json['financial_masked'] as bool? ?? true,
      rows: _list(json['rows']).map(StockReportRow.fromJson).toList(),
      totalClosingValue: _intOrNull(json['total_closing_value']),
    );
  }

  @override
  List<Object?> get props => [
        from,
        to,
        asOf,
        showAvailable,
        financialMasked,
        rows,
        totalClosingValue,
      ];
}

// ---------------------------------------------------------------------------
// SCR-055 thẻ kho
// ---------------------------------------------------------------------------

class StockCardProduct extends Equatable {
  const StockCardProduct({
    required this.productId,
    required this.name,
    required this.code,
    required this.uom,
    required this.isLotTracked,
  });

  final String productId;
  final String name;
  final String code;
  final String uom;
  final bool isLotTracked;

  factory StockCardProduct.fromJson(Map<String, dynamic> json) {
    return StockCardProduct(
      productId: _str(json['product_id']),
      name: _str(json['name']),
      code: _str(json['code']),
      uom: _str(json['uom']),
      isLotTracked: json['is_lot_tracked'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [productId, name, code, uom, isLotTracked];
}

class StockCardLot extends Equatable {
  const StockCardLot({
    required this.lotId,
    required this.lotCode,
    required this.closingQty,
  });

  final String lotId;
  final String lotCode;
  final num closingQty;

  factory StockCardLot.fromJson(Map<String, dynamic> json) {
    return StockCardLot(
      lotId: _str(json['lot_id']),
      lotCode: _str(json['lot_code']),
      closingQty: _num(json['closing_qty']),
    );
  }

  @override
  List<Object?> get props => [lotId, lotCode, closingQty];
}

class StockCardSummary extends Equatable {
  const StockCardSummary({
    required this.openingQty,
    required this.inQty,
    required this.outQty,
    required this.closingQty,
  });

  final num openingQty;
  final num inQty;
  final num outQty;
  final num closingQty;

  factory StockCardSummary.fromJson(Map<String, dynamic> json) {
    return StockCardSummary(
      openingQty: _num(json['opening_qty']),
      inQty: _num(json['in_qty']),
      outQty: _num(json['out_qty']),
      closingQty: _num(json['closing_qty']),
    );
  }

  @override
  List<Object?> get props => [openingQty, inQty, outQty, closingQty];
}

class StockCardLine extends Equatable {
  const StockCardLine({
    required this.movementId,
    required this.businessDate,
    required this.recordedAt,
    required this.movementKind,
    this.reason,
    required this.intentType,
    required this.docCode,
    this.lotCode,
    required this.quantityDelta,
    required this.balanceAfter,
    required this.actorName,
  });

  final String movementId;
  final DateTime businessDate;
  final DateTime recordedAt;
  final String movementKind;
  final String? reason;
  final String intentType;
  final String docCode;
  final String? lotCode;
  final num quantityDelta;
  final num balanceAfter;
  final String actorName;

  factory StockCardLine.fromJson(Map<String, dynamic> json) {
    return StockCardLine(
      movementId: _str(json['movement_id']),
      businessDate: _date(json['business_date']),
      recordedAt: _dateTime(json['recorded_at']),
      movementKind: _str(json['movement_kind']),
      reason: _strOrNull(json['reason']),
      intentType: _str(json['intent_type']),
      docCode: _str(json['doc_code']),
      lotCode: _strOrNull(json['lot_code']),
      quantityDelta: _num(json['quantity_delta']),
      balanceAfter: _num(json['balance_after']),
      actorName: _str(json['actor_name']),
    );
  }

  @override
  List<Object?> get props => [
        movementId,
        businessDate,
        recordedAt,
        movementKind,
        reason,
        intentType,
        docCode,
        lotCode,
        quantityDelta,
        balanceAfter,
        actorName,
      ];
}

class StockCard extends Equatable {
  const StockCard({
    required this.product,
    required this.from,
    required this.to,
    required this.asOf,
    required this.financialMasked,
    required this.lots,
    required this.summary,
    this.closingValue,
    required this.rows,
  });

  final StockCardProduct product;
  final DateTime from;
  final DateTime to;
  final DateTime asOf;
  final bool financialMasked;
  final List<StockCardLot> lots;
  final StockCardSummary summary;
  final int? closingValue;
  final List<StockCardLine> rows;

  factory StockCard.fromJson(Map<String, dynamic> json) {
    return StockCard(
      product: StockCardProduct.fromJson(_map(json['product'])),
      from: _date(json['from']),
      to: _date(json['to']),
      asOf: _dateTime(json['as_of']),
      financialMasked: json['financial_masked'] as bool? ?? true,
      lots: _list(json['lots']).map(StockCardLot.fromJson).toList(),
      summary: StockCardSummary.fromJson(_map(json['summary'])),
      closingValue: _intOrNull(json['closing_value']),
      rows: _list(json['rows']).map(StockCardLine.fromJson).toList(),
    );
  }

  @override
  List<Object?> get props => [
        product,
        from,
        to,
        asOf,
        financialMasked,
        lots,
        summary,
        closingValue,
        rows,
      ];
}

// ---------------------------------------------------------------------------
// SCR-056 chi tiết biến động
// ---------------------------------------------------------------------------

class MovementSource extends Equatable {
  const MovementSource({
    required this.kind,
    required this.docCode,
    this.receiptId,
    this.orderId,
    this.returnId,
  });

  /// `RECEIPT` · `ORDER` · `CANCELLATION` · `RETURN_EXCHANGE` · `STOCKTAKE` · `OTHER`.
  final String kind;
  final String docCode;
  final String? receiptId;
  final String? orderId;
  final String? returnId;

  factory MovementSource.fromJson(Map<String, dynamic> json) {
    final target = _map(json['target']);
    return MovementSource(
      kind: _str(json['kind']).isEmpty ? 'OTHER' : _str(json['kind']),
      docCode: _str(json['doc_code']),
      receiptId: _strOrNull(target['receipt_id']),
      orderId: _strOrNull(target['order_id']),
      returnId: _strOrNull(target['return_id']),
    );
  }

  /// Q-7-5: chỉ nguồn có màn xem mới có đường dẫn; `STOCKTAKE` / `OTHER` ⇒ `null`.
  String? get route {
    switch (kind) {
      case 'RECEIPT':
        return receiptId == null ? null : '/warehouse/receipts/$receiptId';
      case 'ORDER':
      case 'CANCELLATION':
        return orderId == null ? null : '/sales/orders/$orderId';
      case 'RETURN_EXCHANGE':
        if (orderId == null || returnId == null) return null;
        return '/sales/orders/$orderId/returns/$returnId/detail';
      default:
        return null;
    }
  }

  @override
  List<Object?> get props => [kind, docCode, receiptId, orderId, returnId];
}

class MovementDetail extends Equatable {
  const MovementDetail({
    required this.movementId,
    required this.product,
    this.lotCode,
    required this.movementKind,
    this.reason,
    required this.intentType,
    required this.quantityDelta,
    required this.beforeQty,
    required this.afterQty,
    required this.businessDate,
    required this.recordedAt,
    required this.actorName,
    this.valueAmount,
    required this.source,
  });

  final String movementId;
  final StockCardProduct product;
  final String? lotCode;
  final String movementKind;
  final String? reason;
  final String intentType;
  final num quantityDelta;
  final num beforeQty;
  final num afterQty;
  final DateTime businessDate;
  final DateTime recordedAt;
  final String actorName;
  final int? valueAmount;
  final MovementSource source;

  factory MovementDetail.fromJson(Map<String, dynamic> json) {
    return MovementDetail(
      movementId: _str(json['movement_id']),
      product: StockCardProduct.fromJson(_map(json['product'])),
      lotCode: _strOrNull(json['lot_code']),
      movementKind: _str(json['movement_kind']),
      reason: _strOrNull(json['reason']),
      intentType: _str(json['intent_type']),
      quantityDelta: _num(json['quantity_delta']),
      beforeQty: _num(json['before_qty']),
      afterQty: _num(json['after_qty']),
      businessDate: _date(json['business_date']),
      recordedAt: _dateTime(json['recorded_at']),
      actorName: _str(json['actor_name']),
      valueAmount: _intOrNull(json['value_amount']),
      source: MovementSource.fromJson(_map(json['source'])),
    );
  }

  @override
  List<Object?> get props => [
        movementId,
        product,
        lotCode,
        movementKind,
        reason,
        intentType,
        quantityDelta,
        beforeQty,
        afterQty,
        businessDate,
        recordedAt,
        actorName,
        valueAmount,
        source,
      ];
}

// ---------------------------------------------------------------------------
// Lãi gộp
// ---------------------------------------------------------------------------

class GrossProfitRow extends Equatable {
  const GrossProfitRow({
    required this.productId,
    required this.name,
    required this.code,
    required this.uom,
    required this.revenueVnd,
    required this.deductionVnd,
    required this.netRevenueVnd,
    required this.cogsAtSaleVnd,
    required this.cogsAdjustVnd,
    required this.rebateVnd,
    required this.cogsAfterVnd,
    required this.grossProfitVnd,
    this.marginPct,
  });

  final String productId;
  final String name;
  final String code;
  final String uom;
  final int revenueVnd;
  final int deductionVnd;
  final int netRevenueVnd;
  final int cogsAtSaleVnd;
  final int cogsAdjustVnd;
  final int rebateVnd;
  final int cogsAfterVnd;
  final int grossProfitVnd;
  final num? marginPct;

  factory GrossProfitRow.fromJson(Map<String, dynamic> json) {
    return GrossProfitRow(
      productId: _str(json['product_id']),
      name: _str(json['name']),
      code: _str(json['code']),
      uom: _str(json['uom']),
      revenueVnd: _int(json['revenue_vnd']),
      deductionVnd: _int(json['deduction_vnd']),
      netRevenueVnd: _int(json['net_revenue_vnd']),
      cogsAtSaleVnd: _int(json['cogs_at_sale_vnd']),
      cogsAdjustVnd: _int(json['cogs_adjust_vnd']),
      rebateVnd: _int(json['rebate_vnd']),
      cogsAfterVnd: _int(json['cogs_after_vnd']),
      grossProfitVnd: _int(json['gross_profit_vnd']),
      marginPct: _numOrNull(json['margin_pct']),
    );
  }

  @override
  List<Object?> get props => [
        productId,
        name,
        code,
        uom,
        revenueVnd,
        deductionVnd,
        netRevenueVnd,
        cogsAtSaleVnd,
        cogsAdjustVnd,
        rebateVnd,
        cogsAfterVnd,
        grossProfitVnd,
        marginPct,
      ];
}

class GrossProfitTotals extends Equatable {
  const GrossProfitTotals({
    required this.revenue,
    required this.deduction,
    required this.netRevenue,
    required this.cogsAtSale,
    required this.cogsAdjust,
    required this.rebate,
    required this.cogsAfter,
    required this.grossProfit,
    this.marginPct,
    required this.loss,
    required this.profitAfterLoss,
  });

  final int revenue;
  final int deduction;
  final int netRevenue;
  final int cogsAtSale;
  final int cogsAdjust;
  final int rebate;
  final int cogsAfter;
  final int grossProfit;
  final num? marginPct;
  final int loss;
  final int profitAfterLoss;

  factory GrossProfitTotals.fromJson(Map<String, dynamic> json) {
    return GrossProfitTotals(
      revenue: _int(json['revenue']),
      deduction: _int(json['deduction']),
      netRevenue: _int(json['net_revenue']),
      cogsAtSale: _int(json['cogs_at_sale']),
      cogsAdjust: _int(json['cogs_adjust']),
      rebate: _int(json['rebate']),
      cogsAfter: _int(json['cogs_after']),
      grossProfit: _int(json['gross_profit']),
      marginPct: _numOrNull(json['margin_pct']),
      loss: _int(json['loss']),
      profitAfterLoss: _int(json['profit_after_loss']),
    );
  }

  @override
  List<Object?> get props => [
        revenue,
        deduction,
        netRevenue,
        cogsAtSale,
        cogsAdjust,
        rebate,
        cogsAfter,
        grossProfit,
        marginPct,
        loss,
        profitAfterLoss,
      ];
}

class GrossProfitByProduct extends Equatable {
  const GrossProfitByProduct({
    required this.from,
    required this.to,
    required this.asOf,
    required this.rows,
    required this.lossVnd,
    required this.totals,
  });

  final DateTime from;
  final DateTime to;
  final DateTime asOf;
  final List<GrossProfitRow> rows;
  final int lossVnd;
  final GrossProfitTotals totals;

  factory GrossProfitByProduct.fromJson(Map<String, dynamic> json) {
    return GrossProfitByProduct(
      from: _date(json['from']),
      to: _date(json['to']),
      asOf: _dateTime(json['as_of']),
      rows: _list(json['rows']).map(GrossProfitRow.fromJson).toList(),
      lossVnd: _int(json['loss_vnd']),
      totals: GrossProfitTotals.fromJson(_map(json['totals'])),
    );
  }

  @override
  List<Object?> get props => [from, to, asOf, rows, lossVnd, totals];
}

class GrossProfitOrderRow extends Equatable {
  const GrossProfitOrderRow({
    required this.orderId,
    required this.orderCode,
    required this.completedOn,
    required this.revenueVnd,
    required this.cogsVnd,
    required this.grossProfitVnd,
    this.marginPct,
    required this.hasProvisional,
  });

  final String orderId;
  final String orderCode;
  final DateTime completedOn;
  final int revenueVnd;
  final int cogsVnd;
  final int grossProfitVnd;
  final num? marginPct;
  final bool hasProvisional;

  factory GrossProfitOrderRow.fromJson(Map<String, dynamic> json) {
    return GrossProfitOrderRow(
      orderId: _str(json['order_id']),
      orderCode: _str(json['order_code']),
      completedOn: _date(json['completed_on']),
      revenueVnd: _int(json['revenue_vnd']),
      cogsVnd: _int(json['cogs_vnd']),
      grossProfitVnd: _int(json['gross_profit_vnd']),
      marginPct: _numOrNull(json['margin_pct']),
      hasProvisional: json['has_provisional'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        orderId,
        orderCode,
        completedOn,
        revenueVnd,
        cogsVnd,
        grossProfitVnd,
        marginPct,
        hasProvisional,
      ];
}

class GrossProfitOrderTotals extends Equatable {
  const GrossProfitOrderTotals({
    required this.revenue,
    required this.cogs,
    required this.grossProfit,
    this.marginPct,
  });

  final int revenue;
  final int cogs;
  final int grossProfit;
  final num? marginPct;

  factory GrossProfitOrderTotals.fromJson(Map<String, dynamic> json) {
    return GrossProfitOrderTotals(
      revenue: _int(json['revenue']),
      cogs: _int(json['cogs']),
      grossProfit: _int(json['gross_profit']),
      marginPct: _numOrNull(json['margin_pct']),
    );
  }

  @override
  List<Object?> get props => [revenue, cogs, grossProfit, marginPct];
}

class GrossProfitByOrder extends Equatable {
  const GrossProfitByOrder({
    required this.from,
    required this.to,
    required this.asOf,
    required this.rows,
    required this.totals,
  });

  final DateTime from;
  final DateTime to;
  final DateTime asOf;
  final List<GrossProfitOrderRow> rows;
  final GrossProfitOrderTotals totals;

  factory GrossProfitByOrder.fromJson(Map<String, dynamic> json) {
    return GrossProfitByOrder(
      from: _date(json['from']),
      to: _date(json['to']),
      asOf: _dateTime(json['as_of']),
      rows: _list(json['rows']).map(GrossProfitOrderRow.fromJson).toList(),
      totals: GrossProfitOrderTotals.fromJson(_map(json['totals'])),
    );
  }

  @override
  List<Object?> get props => [from, to, asOf, rows, totals];
}

// ---------------------------------------------------------------------------
// Nhập hàng theo NCC
// ---------------------------------------------------------------------------

class SupplierPurchaseProduct extends Equatable {
  const SupplierPurchaseProduct({
    required this.productId,
    required this.name,
    required this.code,
    required this.uom,
    required this.paidQty,
    required this.freeQty,
    required this.purchaseVnd,
    required this.landedVnd,
    this.avgLandedUnitCost,
  });

  final String productId;
  final String name;
  final String code;
  final String uom;
  final num paidQty;
  final num freeQty;
  final int purchaseVnd;
  final int landedVnd;
  final num? avgLandedUnitCost;

  factory SupplierPurchaseProduct.fromJson(Map<String, dynamic> json) {
    return SupplierPurchaseProduct(
      productId: _str(json['product_id']),
      name: _str(json['name']),
      code: _str(json['code']),
      uom: _str(json['uom']),
      paidQty: _num(json['paid_qty']),
      freeQty: _num(json['free_qty']),
      purchaseVnd: _int(json['purchase_vnd']),
      landedVnd: _int(json['landed_vnd']),
      avgLandedUnitCost: _numOrNull(json['avg_landed_unit_cost']),
    );
  }

  @override
  List<Object?> get props => [
        productId,
        name,
        code,
        uom,
        paidQty,
        freeQty,
        purchaseVnd,
        landedVnd,
        avgLandedUnitCost,
      ];
}

class SupplierPurchaseRow extends Equatable {
  const SupplierPurchaseRow({
    required this.supplierId,
    required this.name,
    required this.isSystem,
    required this.receiptCount,
    required this.purchaseVnd,
    required this.freightVnd,
    required this.tradeDiscountVnd,
    required this.landedVnd,
    required this.rebateVnd,
    required this.products,
  });

  final String supplierId;
  final String name;
  final bool isSystem;
  final int receiptCount;
  final int purchaseVnd;
  final int freightVnd;
  final int tradeDiscountVnd;
  final int landedVnd;
  final int rebateVnd;
  final List<SupplierPurchaseProduct> products;

  factory SupplierPurchaseRow.fromJson(Map<String, dynamic> json) {
    return SupplierPurchaseRow(
      supplierId: _str(json['supplier_id']),
      name: _str(json['name']),
      isSystem: json['is_system'] as bool? ?? false,
      receiptCount: _int(json['receipt_count']),
      purchaseVnd: _int(json['purchase_vnd']),
      freightVnd: _int(json['freight_vnd']),
      tradeDiscountVnd: _int(json['trade_discount_vnd']),
      landedVnd: _int(json['landed_vnd']),
      rebateVnd: _int(json['rebate_vnd']),
      products: _list(json['products'])
          .map(SupplierPurchaseProduct.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        supplierId,
        name,
        isSystem,
        receiptCount,
        purchaseVnd,
        freightVnd,
        tradeDiscountVnd,
        landedVnd,
        rebateVnd,
        products,
      ];
}

class SupplierPurchaseTotals extends Equatable {
  const SupplierPurchaseTotals({
    required this.purchase,
    required this.freight,
    required this.tradeDiscount,
    required this.landed,
    required this.rebate,
  });

  final int purchase;
  final int freight;
  final int tradeDiscount;
  final int landed;
  final int rebate;

  factory SupplierPurchaseTotals.fromJson(Map<String, dynamic> json) {
    return SupplierPurchaseTotals(
      purchase: _int(json['purchase']),
      freight: _int(json['freight']),
      tradeDiscount: _int(json['trade_discount']),
      landed: _int(json['landed']),
      rebate: _int(json['rebate']),
    );
  }

  @override
  List<Object?> get props => [purchase, freight, tradeDiscount, landed, rebate];
}

class SupplierPurchaseReport extends Equatable {
  const SupplierPurchaseReport({
    required this.from,
    required this.to,
    required this.asOf,
    required this.suppliers,
    required this.totals,
  });

  final DateTime from;
  final DateTime to;
  final DateTime asOf;
  final List<SupplierPurchaseRow> suppliers;
  final SupplierPurchaseTotals totals;

  factory SupplierPurchaseReport.fromJson(Map<String, dynamic> json) {
    return SupplierPurchaseReport(
      from: _date(json['from']),
      to: _date(json['to']),
      asOf: _dateTime(json['as_of']),
      suppliers:
          _list(json['suppliers']).map(SupplierPurchaseRow.fromJson).toList(),
      totals: SupplierPurchaseTotals.fromJson(_map(json['totals'])),
    );
  }

  @override
  List<Object?> get props => [from, to, asOf, suppliers, totals];
}
