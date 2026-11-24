// Mô hình dữ liệu cho chiết khấu nhà cung cấp và so sánh nhà cung cấp (T7-G5-5b).

import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';

class RebateAllocation {
  final String productId;
  final String name;
  final String uom;
  final num paidQty;
  final int? purchaseAmountVnd;
  final int? rebatePartVnd;
  final num onHandQty;
  final int? inventoryPartVnd;
  final int? cogsPartVnd;
  final num? avgCostBefore;
  final num? avgCostAfter;

  const RebateAllocation({
    required this.productId,
    required this.name,
    required this.uom,
    required this.paidQty,
    this.purchaseAmountVnd,
    this.rebatePartVnd,
    required this.onHandQty,
    this.inventoryPartVnd,
    this.cogsPartVnd,
    this.avgCostBefore,
    this.avgCostAfter,
  });

  factory RebateAllocation.fromJson(Map<String, dynamic> json) {
    return RebateAllocation(
      productId: json['product_id'] as String,
      name: json['name'] as String? ?? '',
      uom: json['uom'] as String? ?? '',
      paidQty: (json['paid_qty'] as num?) ?? 0,
      purchaseAmountVnd: (json['purchase_amount_vnd'] as num?)?.toInt(),
      rebatePartVnd: (json['rebate_part_vnd'] as num?)?.toInt(),
      onHandQty: (json['on_hand_qty'] as num?) ?? 0,
      inventoryPartVnd: (json['inventory_part_vnd'] as num?)?.toInt(),
      cogsPartVnd: (json['cogs_part_vnd'] as num?)?.toInt(),
      avgCostBefore: json['avg_cost_before'] as num?,
      avgCostAfter: json['avg_cost_after'] as num?,
    );
  }
}

class RebatePreview {
  final String programId;
  final String programName;
  final String supplierName;
  final num targetQty;
  final num progressQty;
  final num rebatePercent;
  final String? uom;
  final int baseAmountVnd;
  final int proposedAmountVnd;
  final int amountVnd;
  final List<RebateAllocation> allocations;
  final int inventoryPartTotal;
  final int cogsPartTotal;

  const RebatePreview({
    required this.programId,
    required this.programName,
    required this.supplierName,
    required this.targetQty,
    required this.progressQty,
    required this.rebatePercent,
    this.uom,
    required this.baseAmountVnd,
    required this.proposedAmountVnd,
    required this.amountVnd,
    required this.allocations,
    required this.inventoryPartTotal,
    required this.cogsPartTotal,
  });

  factory RebatePreview.fromJson(Map<String, dynamic> json) {
    return RebatePreview(
      programId: json['program_id'] as String,
      programName: json['program_name'] as String? ?? '',
      supplierName: json['supplier_name'] as String? ?? '',
      targetQty: (json['target_qty'] as num?) ?? 0,
      progressQty: (json['progress_qty'] as num?) ?? 0,
      rebatePercent: (json['rebate_percent'] as num?) ?? 0,
      uom: json['uom'] as String?,
      baseAmountVnd: (json['base_amount_vnd'] as num?)?.toInt() ?? 0,
      proposedAmountVnd: (json['proposed_amount_vnd'] as num?)?.toInt() ?? 0,
      amountVnd: (json['amount_vnd'] as num?)?.toInt() ?? 0,
      allocations: ((json['allocations'] as List?) ?? const [])
          .map(
            (e) =>
                RebateAllocation.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      inventoryPartTotal: (json['inventory_part_total'] as num?)?.toInt() ?? 0,
      cogsPartTotal: (json['cogs_part_total'] as num?)?.toInt() ?? 0,
    );
  }
}

class RebateRecordResult extends RebatePreview {
  final String rebateId;

  const RebateRecordResult({
    required this.rebateId,
    required super.programId,
    required super.programName,
    required super.supplierName,
    required super.targetQty,
    required super.progressQty,
    required super.rebatePercent,
    super.uom,
    required super.baseAmountVnd,
    required super.proposedAmountVnd,
    required super.amountVnd,
    required super.allocations,
    required super.inventoryPartTotal,
    required super.cogsPartTotal,
  });

  factory RebateRecordResult.fromJson(Map<String, dynamic> json) {
    final preview = RebatePreview.fromJson(json);
    return RebateRecordResult(
      rebateId: json['rebate_id'] as String,
      programId: preview.programId,
      programName: preview.programName,
      supplierName: preview.supplierName,
      targetQty: preview.targetQty,
      progressQty: preview.progressQty,
      rebatePercent: preview.rebatePercent,
      uom: preview.uom,
      baseAmountVnd: preview.baseAmountVnd,
      proposedAmountVnd: preview.proposedAmountVnd,
      amountVnd: preview.amountVnd,
      allocations: preview.allocations,
      inventoryPartTotal: preview.inventoryPartTotal,
      cogsPartTotal: preview.cogsPartTotal,
    );
  }
}

class RecordedRebate {
  final String rebateId;
  final String documentNo;
  final DateTime documentDate;
  final int? baseAmountVnd;
  final int? proposedAmountVnd;
  final int? rebateAmountVnd;
  final String? overrideReason;
  final int? inventoryPartVnd;
  final int? cogsPartVnd;
  final DateTime recordedAt;
  final String recordedByName;
  final List<RebateAllocation> allocations;

  const RecordedRebate({
    required this.rebateId,
    required this.documentNo,
    required this.documentDate,
    this.baseAmountVnd,
    this.proposedAmountVnd,
    this.rebateAmountVnd,
    this.overrideReason,
    this.inventoryPartVnd,
    this.cogsPartVnd,
    required this.recordedAt,
    required this.recordedByName,
    required this.allocations,
  });

  factory RecordedRebate.fromJson(Map<String, dynamic> json) {
    final rawReason = json['override_reason'] as String?;
    return RecordedRebate(
      rebateId: json['rebate_id'] as String,
      documentNo: json['document_no'] as String? ?? '',
      documentDate: DateTime.tryParse(json['document_date'] as String? ?? '') ??
          DateTime.now(),
      baseAmountVnd: (json['base_amount_vnd'] as num?)?.toInt(),
      proposedAmountVnd: (json['proposed_amount_vnd'] as num?)?.toInt(),
      rebateAmountVnd: (json['rebate_amount_vnd'] as num?)?.toInt(),
      overrideReason:
          (rawReason == null || rawReason.trim().isEmpty) ? null : rawReason,
      inventoryPartVnd: (json['inventory_part_vnd'] as num?)?.toInt(),
      cogsPartVnd: (json['cogs_part_vnd'] as num?)?.toInt(),
      recordedAt: DateTime.tryParse(json['recorded_at'] as String? ?? '') ??
          DateTime.now(),
      recordedByName: json['recorded_by_name'] as String? ?? '',
      allocations: ((json['allocations'] as List?) ?? const [])
          .map(
            (e) =>
                RebateAllocation.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }
}

class ProjectedCost {
  final String productId;
  final String uom;
  final num progressQty;
  final num targetQty;
  final num missingQty;
  final bool? reachesTarget;
  final int? rebateEstimate;
  final num? avgNow;
  final num? avgProjected;
  final int? defaultUnitPrice;
  final bool financialMasked;

  const ProjectedCost({
    required this.productId,
    required this.uom,
    required this.progressQty,
    required this.targetQty,
    required this.missingQty,
    this.reachesTarget,
    this.rebateEstimate,
    this.avgNow,
    this.avgProjected,
    this.defaultUnitPrice,
    required this.financialMasked,
  });

  factory ProjectedCost.fromJson(Map<String, dynamic> json) {
    return ProjectedCost(
      productId: json['product_id'] as String,
      uom: json['uom'] as String? ?? '',
      progressQty: (json['progress_qty'] as num?) ?? 0,
      targetQty: (json['target_qty'] as num?) ?? 0,
      missingQty: (json['missing_qty'] as num?) ?? 0,
      reachesTarget: json['reaches_target'] as bool?,
      rebateEstimate: (json['rebate_estimate'] as num?)?.toInt(),
      avgNow: json['avg_now'] as num?,
      avgProjected: json['avg_projected'] as num?,
      defaultUnitPrice: (json['default_unit_price'] as num?)?.toInt(),
      financialMasked: json['financial_masked'] as bool? ?? false,
    );
  }
}

class SupplierCompareRow {
  final String partnerId;
  final String name;
  final bool isSystem;
  final num? lastLandedUnitCost;
  final DateTime? lastReceivedOn;
  final num? avgLandedUnitCost;
  final int receiptCount;
  final num paidQty;
  final num freeQty;
  final ProgramRow? program;
  final ({String id, String name})? otherProgram;

  const SupplierCompareRow({
    required this.partnerId,
    required this.name,
    required this.isSystem,
    this.lastLandedUnitCost,
    this.lastReceivedOn,
    this.avgLandedUnitCost,
    required this.receiptCount,
    required this.paidQty,
    required this.freeQty,
    this.program,
    this.otherProgram,
  });

  factory SupplierCompareRow.fromJson(Map<String, dynamic> json) {
    final partnerId = json['partner_id'] as String;
    final name = json['name'] as String? ?? '';

    ProgramRow? program;
    final rawProg = json['program'];
    if (rawProg is Map) {
      program = ProgramRow.fromJson(<String, dynamic>{
        'supplier_id': partnerId,
        'supplier_name': name,
        ...Map<String, dynamic>.from(rawProg),
      });
    }

    ({String id, String name})? otherProgram;
    final rawOther = json['other_program'];
    if (rawOther is Map) {
      final m = Map<String, dynamic>.from(rawOther);
      final id = m['program_id'] as String?;
      final progName = m['name'] as String?;
      if (id != null && progName != null) {
        otherProgram = (id: id, name: progName);
      }
    }

    return SupplierCompareRow(
      partnerId: partnerId,
      name: name,
      isSystem: json['is_system'] as bool? ?? false,
      lastLandedUnitCost: json['last_landed_unit_cost'] as num?,
      lastReceivedOn: json['last_received_on'] != null
          ? DateTime.tryParse(json['last_received_on'] as String)
          : null,
      avgLandedUnitCost: json['avg_landed_unit_cost'] as num?,
      receiptCount: (json['receipt_count'] as num?)?.toInt() ?? 0,
      paidQty: (json['paid_qty'] as num?) ?? 0,
      freeQty: (json['free_qty'] as num?) ?? 0,
      program: program,
      otherProgram: otherProgram,
    );
  }
}

class SupplierCompare {
  final String productId;
  final String name;
  final String code;
  final String uom;
  final bool financialMasked;
  final List<SupplierCompareRow> suppliers;

  const SupplierCompare({
    required this.productId,
    required this.name,
    required this.code,
    required this.uom,
    required this.financialMasked,
    required this.suppliers,
  });

  factory SupplierCompare.fromJson(Map<String, dynamic> json) {
    final prod = json['product'] is Map
        ? Map<String, dynamic>.from(json['product'] as Map)
        : const <String, dynamic>{};
    return SupplierCompare(
      productId: prod['product_id'] as String? ?? '',
      name: prod['name'] as String? ?? '',
      code: prod['code'] as String? ?? '',
      uom: prod['uom'] as String? ?? '',
      financialMasked: json['financial_masked'] as bool? ?? false,
      suppliers: ((json['suppliers'] as List?) ?? const [])
          .map(
            (e) =>
                SupplierCompareRow.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }
}

