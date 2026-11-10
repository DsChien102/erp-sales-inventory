// Mô hình dữ liệu cho chương trình nhà cung cấp (T7-G5-2b).

enum ProgramKind {
  tierDiscount('TIER_DISCOUNT'),
  buyXGetY('BUY_X_GET_Y'),
  volumeRebate('VOLUME_REBATE');

  final String wire;
  const ProgramKind(this.wire);

  static ProgramKind fromJson(String? raw) {
    return switch (raw) {
      'TIER_DISCOUNT' => ProgramKind.tierDiscount,
      'BUY_X_GET_Y' => ProgramKind.buyXGetY,
      'VOLUME_REBATE' => ProgramKind.volumeRebate,
      _ => ProgramKind.tierDiscount,
    };
  }
}

enum ProgramStatus {
  active('ACTIVE'),
  reached('REACHED'),
  recorded('RECORDED'),
  ended('ENDED');

  final String wire;
  const ProgramStatus(this.wire);

  static ProgramStatus fromJson(String? raw) {
    return switch (raw) {
      'ACTIVE' => ProgramStatus.active,
      'REACHED' => ProgramStatus.reached,
      'RECORDED' => ProgramStatus.recorded,
      'ENDED' => ProgramStatus.ended,
      _ => ProgramStatus.active,
    };
  }
}

class ProgramTier {
  final num minQty;
  final num discountPercent;

  const ProgramTier({
    required this.minQty,
    required this.discountPercent,
  });

  factory ProgramTier.fromJson(Map<String, dynamic> json) {
    return ProgramTier(
      minQty: (json['min_qty'] as num?) ?? 0,
      discountPercent: (json['discount_percent'] as num?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'min_qty': minQty,
        'discount_percent': discountPercent,
      };
}

class ProgramRow {
  final String id;
  final String name;
  final String supplierId;
  final String supplierName;
  final ProgramKind kind;
  final ProgramStatus status;
  final DateTime startedOn;
  final List<String> productIds;
  final int productCount;
  final String? commonUom;
  final List<ProgramTier> tiers;
  final num? buyQty;
  final num? freeQty;
  final num? targetQty;
  final num? rebatePercent;
  final num progressQty;

  const ProgramRow({
    required this.id,
    required this.name,
    required this.supplierId,
    required this.supplierName,
    required this.kind,
    required this.status,
    required this.startedOn,
    required this.productIds,
    required this.productCount,
    this.commonUom,
    required this.tiers,
    this.buyQty,
    this.freeQty,
    this.targetQty,
    this.rebatePercent,
    required this.progressQty,
  });

  factory ProgramRow.fromJson(Map<String, dynamic> json) {
    return ProgramRow(
      id: json['program_id'] as String,
      name: json['name'] as String? ?? '',
      supplierId: json['supplier_id'] as String? ?? '',
      supplierName: json['supplier_name'] as String? ?? '',
      kind: ProgramKind.fromJson(json['kind'] as String?),
      status: ProgramStatus.fromJson(json['status'] as String?),
      startedOn: DateTime.tryParse(json['started_on'] as String? ?? '') ??
          DateTime.now(),
      productIds: ((json['product_ids'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      productCount: (json['product_count'] as num?)?.toInt() ?? 0,
      commonUom: json['common_uom'] as String?,
      tiers: ((json['tiers'] as List?) ?? const [])
          .map((e) => ProgramTier.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      buyQty: json['buy_qty'] as num?,
      freeQty: json['free_qty'] as num?,
      targetQty: json['target_qty'] as num?,
      rebatePercent: json['rebate_percent'] as num?,
      progressQty: (json['progress_qty'] as num?) ?? 0,
    );
  }
}

class ProgramProduct {
  final String productId;
  final String name;
  final String code;
  final String baseUom;

  const ProgramProduct({
    required this.productId,
    required this.name,
    required this.code,
    required this.baseUom,
  });

  factory ProgramProduct.fromJson(Map<String, dynamic> json) {
    return ProgramProduct(
      productId: json['product_id'] as String,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      baseUom: json['base_uom'] as String? ?? '',
    );
  }
}

class ProgramReceipt {
  final String receiptLineId;
  final num paidQty;
  final int purchaseAmountVnd;
  final DateTime createdAt;

  const ProgramReceipt({
    required this.receiptLineId,
    required this.paidQty,
    required this.purchaseAmountVnd,
    required this.createdAt,
  });

  factory ProgramReceipt.fromJson(Map<String, dynamic> json) {
    return ProgramReceipt(
      receiptLineId: json['receipt_line_id'] as String,
      paidQty: (json['paid_qty'] as num?) ?? 0,
      purchaseAmountVnd: (json['purchase_amount_vnd'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class ProgramDetail {
  final ProgramRow row;
  final String? note;
  final int revision;
  final bool isLocked;
  final DateTime? reachedAt;
  final DateTime? endedAt;
  final List<ProgramProduct> products;
  final List<ProgramReceipt> receipts;
  final int baseAmountVnd;

  const ProgramDetail({
    required this.row,
    this.note,
    required this.revision,
    required this.isLocked,
    this.reachedAt,
    this.endedAt,
    required this.products,
    required this.receipts,
    required this.baseAmountVnd,
  });

  factory ProgramDetail.fromJson(Map<String, dynamic> json) {
    final programJson = Map<String, dynamic>.from(json['program'] as Map);
    final rawNote = programJson['note'] as String?;
    return ProgramDetail(
      row: ProgramRow.fromJson(programJson),
      note: (rawNote == null || rawNote.trim().isEmpty) ? null : rawNote,
      revision: (programJson['revision'] as num?)?.toInt() ?? 1,
      isLocked: programJson['is_locked'] as bool? ?? false,
      reachedAt: programJson['reached_at'] != null
          ? DateTime.tryParse(programJson['reached_at'] as String)
          : null,
      endedAt: programJson['ended_at'] != null
          ? DateTime.tryParse(programJson['ended_at'] as String)
          : null,
      products: ((json['products'] as List?) ?? const [])
          .map(
            (e) =>
                ProgramProduct.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      receipts: ((json['receipts'] as List?) ?? const [])
          .map(
            (e) =>
                ProgramReceipt.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      baseAmountVnd: (json['base_amount_vnd'] as num?)?.toInt() ?? 0,
    );
  }
}

class SupplierOption {
  final String partnerId;
  final String displayName;
  final ({String id, String name})? activeProgram;

  const SupplierOption({
    required this.partnerId,
    required this.displayName,
    this.activeProgram,
  });

  factory SupplierOption.fromJson(Map<String, dynamic> json) {
    final activeRaw = json['active_program'];
    ({String id, String name})? active;
    if (activeRaw is Map) {
      final m = Map<String, dynamic>.from(activeRaw);
      final id = m['program_id'] as String?;
      final name = m['name'] as String?;
      if (id != null && name != null) {
        active = (id: id, name: name);
      }
    }
    return SupplierOption(
      partnerId: json['partner_id'] as String,
      displayName: json['display_name'] as String? ?? '',
      activeProgram: active,
    );
  }
}

class ProductOption {
  final String productId;
  final String name;
  final String code;
  final String baseUnitId;
  final String baseUom;

  const ProductOption({
    required this.productId,
    required this.name,
    required this.code,
    required this.baseUnitId,
    required this.baseUom,
  });

  factory ProductOption.fromJson(Map<String, dynamic> json) {
    return ProductOption(
      productId: json['product_id'] as String,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      baseUnitId: json['base_unit_id'] as String? ?? '',
      baseUom: json['base_uom'] as String? ?? '',
    );
  }
}

class ProgramFormOptions {
  final List<SupplierOption> suppliers;
  final List<ProductOption> products;

  const ProgramFormOptions({
    required this.suppliers,
    required this.products,
  });

  factory ProgramFormOptions.fromJson(Map<String, dynamic> json) {
    return ProgramFormOptions(
      suppliers: ((json['suppliers'] as List?) ?? const [])
          .map(
            (e) =>
                SupplierOption.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      products: ((json['products'] as List?) ?? const [])
          .map(
            (e) => ProductOption.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }
}

class ProgramHint {
  final String programId;
  final String programName;
  final ProgramKind kind;
  final ({num minQty, num percent, int discountVnd})? tier;
  final ({num minQty, num percent, num missingQty})? nextTier;
  final num? buyQty;
  final num? freeQty;
  final num? suggestedFreeQty;
  final ({num progress, num target, bool wouldReach})? rebate;

  const ProgramHint({
    required this.programId,
    required this.programName,
    required this.kind,
    this.tier,
    this.nextTier,
    this.buyQty,
    this.freeQty,
    this.suggestedFreeQty,
    this.rebate,
  });

  factory ProgramHint.fromJson(Map<String, dynamic> json) {
    final tierRaw = json['tier'];
    ({num minQty, num percent, int discountVnd})? tier;
    if (tierRaw is Map) {
      final m = Map<String, dynamic>.from(tierRaw);
      tier = (
        minQty: (m['min_qty'] as num?) ?? 0,
        percent: (m['discount_percent'] as num?) ?? 0,
        discountVnd: (m['discount_vnd'] as num?)?.toInt() ?? 0,
      );
    }

    final nextRaw = json['next_tier'];
    ({num minQty, num percent, num missingQty})? nextTier;
    if (nextRaw is Map) {
      final m = Map<String, dynamic>.from(nextRaw);
      nextTier = (
        minQty: (m['min_qty'] as num?) ?? 0,
        percent: (m['discount_percent'] as num?) ?? 0,
        missingQty: (m['missing_qty'] as num?) ?? 0,
      );
    }

    final rebateRaw = json['rebate'];
    ({num progress, num target, bool wouldReach})? rebate;
    if (rebateRaw is Map) {
      final m = Map<String, dynamic>.from(rebateRaw);
      rebate = (
        progress: (m['progress_qty'] as num?) ?? 0,
        target: (m['target_qty'] as num?) ?? 0,
        wouldReach: m['would_reach'] as bool? ?? false,
      );
    }

    return ProgramHint(
      programId: json['program_id'] as String,
      programName: json['program_name'] as String? ?? '',
      kind: ProgramKind.fromJson(json['kind'] as String?),
      tier: tier,
      nextTier: nextTier,
      buyQty: json['buy_qty'] as num?,
      freeQty: json['free_qty'] as num?,
      suggestedFreeQty: json['suggested_free_qty'] as num?,
      rebate: rebate,
    );
  }
}

class ProgramPayload {
  final String? supplierId;
  final ProgramKind? kind;
  final String name;
  final DateTime startedOn;
  final String? note;
  final List<String> productIds;
  final List<ProgramTier> tiers;
  final num? buyQty;
  final num? freeQty;
  final num? targetQty;
  final num? rebatePercent;
  final ProgramKind effectiveKind;

  const ProgramPayload({
    this.supplierId,
    this.kind,
    required this.name,
    required this.startedOn,
    this.note,
    required this.productIds,
    this.tiers = const [],
    this.buyQty,
    this.freeQty,
    this.targetQty,
    this.rebatePercent,
    ProgramKind? effectiveKind,
  }) : effectiveKind = effectiveKind ?? kind ?? ProgramKind.tierDiscount;

  static String _formatDateIso(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Map<String, dynamic> toJson() {
    final out = <String, dynamic>{
      if (supplierId != null) 'supplier_id': supplierId,
      if (kind != null) 'kind': kind!.wire,
      'name': name.trim(),
      'started_on': _formatDateIso(startedOn),
      if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      'product_ids': productIds,
    };

    switch (effectiveKind) {
      case ProgramKind.tierDiscount:
        out['tiers'] = tiers.map((t) => t.toJson()).toList();
      case ProgramKind.buyXGetY:
        out['buy_qty'] = buyQty;
        out['free_qty'] = freeQty;
      case ProgramKind.volumeRebate:
        out['target_qty'] = targetQty;
        out['rebate_percent'] = rebatePercent;
    }

    return out;
  }
}

