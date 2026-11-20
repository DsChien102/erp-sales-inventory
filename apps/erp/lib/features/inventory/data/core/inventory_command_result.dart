final class InventoryStockChange {
  const InventoryStockChange({
    required this.productId,
    required this.productName,
    required this.baseUom,
    required this.before,
    required this.after,
  });

  factory InventoryStockChange.fromJson(Map<String, dynamic> json) {
    return InventoryStockChange(
      productId: json['product_id'] as String? ?? json['productId'] as String? ?? '',
      productName: json['product_name'] as String? ?? json['productName'] as String? ?? '',
      baseUom: json['base_uom'] as String? ?? json['baseUom'] as String? ?? '',
      before: (json['before'] as num?) ?? 0,
      after: (json['after'] as num?) ?? 0,
    );
  }

  final String productId;
  final String productName;
  final String baseUom;
  final num before;
  final num after;
}

final class InventoryPostedLine {
  const InventoryPostedLine({
    required this.lineId,
    required this.movementId,
    required this.valueMovementId,
    this.unitCost,
    this.amountVnd,
    this.costVersionId,
    required this.isProvisional,
  });

  factory InventoryPostedLine.fromJson(Map<String, dynamic> json) {
    return InventoryPostedLine(
      lineId: json['line_id'] as String? ?? json['lineId'] as String? ?? '',
      movementId: json['movement_id'] as String? ?? json['movementId'] as String? ?? '',
      valueMovementId: json['value_movement_id'] as String? ?? json['valueMovementId'] as String? ?? '',
      unitCost: json['unit_cost'] as num? ?? json['unitCost'] as num?,
      amountVnd: (json['amount_vnd'] as num?)?.toInt() ?? (json['amountVnd'] as num?)?.toInt(),
      costVersionId: json['cost_version_id'] as String? ?? json['costVersionId'] as String?,
      isProvisional: json['is_provisional'] as bool? ?? json['isProvisional'] as bool? ?? false,
    );
  }

  final String lineId;
  final String movementId;
  final String valueMovementId;
  final num? unitCost;
  final int? amountVnd;
  final String? costVersionId;
  final bool isProvisional;
}

final class InventoryCommandResult {
  const InventoryCommandResult({
    required this.movementIds,
    required this.lines,
    required this.stockChanges,
  });

  factory InventoryCommandResult.fromJson(Map<String, dynamic> json) {
    final rawMovements = json['movement_ids'] ?? json['movementIds'];
    final movements = rawMovements is List
        ? rawMovements.map((e) => e.toString()).toList(growable: false)
        : const <String>[];

    final rawLines = json['lines'];
    final lines = rawLines is List
        ? rawLines
            .whereType<Map>()
            .map((e) => InventoryPostedLine.fromJson(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : const <InventoryPostedLine>[];

    final rawChanges = json['stock_changes'] ?? json['stockChanges'];
    final changes = rawChanges is List
        ? rawChanges
            .whereType<Map>()
            .map((e) => InventoryStockChange.fromJson(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : const <InventoryStockChange>[];

    return InventoryCommandResult(
      movementIds: movements,
      lines: lines,
      stockChanges: changes,
    );
  }

  final List<String> movementIds;
  final List<InventoryPostedLine> lines;
  final List<InventoryStockChange> stockChanges;
}

