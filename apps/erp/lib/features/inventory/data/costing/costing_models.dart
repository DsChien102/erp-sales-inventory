import 'package:equatable/equatable.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';

enum CostRunKind {
  midPeriod('MID_PERIOD'),
  periodClose('PERIOD_CLOSE');

  const CostRunKind(this.wire);
  final String wire;

  static CostRunKind fromWire(String? raw) {
    return switch ((raw ?? '').toUpperCase()) {
      'PERIOD_CLOSE' => CostRunKind.periodClose,
      _ => CostRunKind.midPeriod,
    };
  }
}

enum CostRunStatus {
  readyForReview('READY_FOR_REVIEW'),
  blocked('BLOCKED'),
  stale('STALE'),
  published('PUBLISHED'),
  superseded('SUPERSEDED');

  const CostRunStatus(this.wire);
  final String wire;

  static CostRunStatus fromWire(String? raw) {
    return switch ((raw ?? '').toUpperCase()) {
      'BLOCKED' => CostRunStatus.blocked,
      'STALE' => CostRunStatus.stale,
      'PUBLISHED' => CostRunStatus.published,
      'SUPERSEDED' => CostRunStatus.superseded,
      _ => CostRunStatus.readyForReview,
    };
  }
}

CostMethod costMethodFromWire(String? raw) {
  return (raw ?? '').toUpperCase() == 'PERIODIC'
      ? CostMethod.periodic
      : CostMethod.moving;
}

String costMethodToWire(CostMethod m) {
  return m == CostMethod.periodic ? 'PERIODIC' : 'MOVING';
}

DateTime? _parseDateTime(dynamic v) {
  if (v is! String || v.trim().isEmpty) return null;
  return DateTime.tryParse(v.trim())?.toLocal();
}

DateTime _parseDateOnly(dynamic v) {
  if (v is String && v.trim().isNotEmpty) {
    final parsed = DateTime.tryParse(v.trim());
    if (parsed != null) return DateTime(parsed.year, parsed.month, parsed.day);
  }
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
}

DateTime? _parseDateOnlyNullable(dynamic v) {
  if (v is! String || v.trim().isEmpty) return null;
  final parsed = DateTime.tryParse(v.trim());
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}

class CostBlocker extends Equatable {
  const CostBlocker({
    required this.code,
    this.periodMonth,
    this.productCount,
    this.pendingRunId,
  });

  final String code;
  final DateTime? periodMonth;
  final int? productCount;
  final String? pendingRunId;

  factory CostBlocker.fromJson(Map<String, dynamic> json) {
    return CostBlocker(
      code: json['code'] as String? ?? '',
      periodMonth: _parseDateOnlyNullable(json['period_month']),
      productCount: (json['product_count'] as num?)?.toInt(),
      pendingRunId: json['pending_run_id'] as String?,
    );
  }

  @override
  List<Object?> get props => [code, periodMonth, productCount, pendingRunId];
}

class CostRunRow extends Equatable {
  const CostRunRow({
    required this.runId,
    required this.code,
    required this.kind,
    required this.periodMonth,
    required this.status,
    required this.productCount,
    required this.blockerCount,
    this.valueAdjustVnd,
    this.publishedAt,
    required this.createdAt,
  });

  final String runId;
  final String code;
  final CostRunKind kind;
  final DateTime periodMonth;
  final CostRunStatus status;
  final int productCount;
  final int blockerCount;
  final int? valueAdjustVnd;
  final DateTime? publishedAt;
  final DateTime createdAt;

  factory CostRunRow.fromJson(Map<String, dynamic> json) {
    return CostRunRow(
      runId: json['run_id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      kind: CostRunKind.fromWire(json['kind'] as String?),
      periodMonth: _parseDateOnly(json['period_month']),
      status: CostRunStatus.fromWire(json['status'] as String?),
      productCount: (json['product_count'] as num?)?.toInt() ?? 0,
      blockerCount: (json['blocker_count'] as num?)?.toInt() ?? 0,
      valueAdjustVnd: (json['value_adjust_vnd'] as num?)?.toInt(),
      publishedAt: _parseDateTime(json['published_at']),
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        runId,
        code,
        kind,
        periodMonth,
        status,
        productCount,
        blockerCount,
        valueAdjustVnd,
        publishedAt,
        createdAt,
      ];
}

class CostOverview extends Equatable {
  const CostOverview({
    required this.method,
    required this.methodLocked,
    this.openPeriod,
    this.periodToClose,
    required this.hasPendingRun,
    required this.runs,
  });

  final CostMethod method;
  final bool methodLocked;
  final DateTime? openPeriod;
  final DateTime? periodToClose;
  final bool hasPendingRun;
  final List<CostRunRow> runs;

  factory CostOverview.fromJson(Map<String, dynamic> json) {
    final rawRuns = json['runs'] as List<dynamic>? ?? const [];
    return CostOverview(
      method: costMethodFromWire(json['method'] as String?),
      methodLocked: json['method_locked'] as bool? ?? false,
      openPeriod: _parseDateOnlyNullable(json['open_period']),
      periodToClose: _parseDateOnlyNullable(json['period_to_close']),
      hasPendingRun: json['has_pending_run'] as bool? ?? false,
      runs: rawRuns
          .whereType<Map<String, dynamic>>()
          .map(CostRunRow.fromJson)
          .toList(growable: false),
    );
  }

  @override
  List<Object?> get props => [
        method,
        methodLocked,
        openPeriod,
        periodToClose,
        hasPendingRun,
        runs,
      ];
}

class CostTotals extends Equatable {
  const CostTotals({
    required this.closingValue,
    required this.cogsValue,
    required this.cogsAdjust,
    required this.valueAdjust,
    required this.balanceOk,
  });

  final int closingValue;
  final int cogsValue;
  final int cogsAdjust;
  final int valueAdjust;
  final bool balanceOk;

  factory CostTotals.fromJson(Map<String, dynamic> json) {
    return CostTotals(
      closingValue: (json['closing_value'] as num?)?.toInt() ?? 0,
      cogsValue: (json['cogs_value'] as num?)?.toInt() ?? 0,
      cogsAdjust: (json['cogs_adjust'] as num?)?.toInt() ?? 0,
      valueAdjust: (json['value_adjust'] as num?)?.toInt() ?? 0,
      balanceOk: json['balance_ok'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        closingValue,
        cogsValue,
        cogsAdjust,
        valueAdjust,
        balanceOk,
      ];
}

class CostAlt extends Equatable {
  const CostAlt({
    required this.method,
    required this.closingValue,
    required this.cogsValue,
  });

  final CostMethod method;
  final int closingValue;
  final int cogsValue;

  factory CostAlt.fromJson(Map<String, dynamic> json) {
    return CostAlt(
      method: costMethodFromWire(json['method'] as String?),
      closingValue: (json['closing_value'] as num?)?.toInt() ?? 0,
      cogsValue: (json['cogs_value'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [method, closingValue, cogsValue];
}

class CostRunLineView extends Equatable {
  const CostRunLineView({
    required this.productId,
    required this.name,
    required this.code,
    required this.uom,
    this.oldOfficialUnitCost,
    this.newUnitCost,
    required this.openingQty,
    required this.openingValue,
    required this.inboundQty,
    required this.inboundValue,
    required this.rebateValue,
    required this.saleQty,
    required this.saleValueRecorded,
    required this.lossQty,
    required this.lossValueRecorded,
    required this.closingQty,
    required this.movingAvgEnd,
    this.periodicAvg,
    required this.cogsTrueUp,
    required this.lossTrueUp,
    required this.roundingAdjust,
    required this.closingValueAfter,
    required this.lineAdjust,
    required this.balanceDiff,
  });

  final String productId;
  final String name;
  final String code;
  final String uom;
  final num? oldOfficialUnitCost;
  final num? newUnitCost;
  final num openingQty;
  final int openingValue;
  final num inboundQty;
  final int inboundValue;
  final int rebateValue;
  final num saleQty;
  final int saleValueRecorded;
  final num lossQty;
  final int lossValueRecorded;
  final num closingQty;
  final num movingAvgEnd;
  final num? periodicAvg;
  final int cogsTrueUp;
  final int lossTrueUp;
  final int roundingAdjust;
  final int closingValueAfter;
  final int lineAdjust;
  final int balanceDiff;

  bool get changed =>
      newUnitCost != null && newUnitCost != oldOfficialUnitCost;

  factory CostRunLineView.fromJson(Map<String, dynamic> json) {
    return CostRunLineView(
      productId: json['product_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      uom: json['uom'] as String? ?? '',
      oldOfficialUnitCost: json['old_official_unit_cost'] as num?,
      newUnitCost: json['new_unit_cost'] as num?,
      openingQty: (json['opening_qty'] as num?) ?? 0,
      openingValue: (json['opening_value'] as num?)?.toInt() ?? 0,
      inboundQty: (json['inbound_qty'] as num?) ?? 0,
      inboundValue: (json['inbound_value'] as num?)?.toInt() ?? 0,
      rebateValue: (json['rebate_value'] as num?)?.toInt() ?? 0,
      saleQty: (json['sale_qty'] as num?) ?? 0,
      saleValueRecorded: (json['sale_value_recorded'] as num?)?.toInt() ?? 0,
      lossQty: (json['loss_qty'] as num?) ?? 0,
      lossValueRecorded: (json['loss_value_recorded'] as num?)?.toInt() ?? 0,
      closingQty: (json['closing_qty'] as num?) ?? 0,
      movingAvgEnd: (json['moving_avg_end'] as num?) ?? 0,
      periodicAvg: json['periodic_avg'] as num?,
      cogsTrueUp: (json['cogs_true_up'] as num?)?.toInt() ?? 0,
      lossTrueUp: (json['loss_true_up'] as num?)?.toInt() ?? 0,
      roundingAdjust: (json['rounding_adjust'] as num?)?.toInt() ?? 0,
      closingValueAfter: (json['closing_value_after'] as num?)?.toInt() ?? 0,
      lineAdjust: (json['line_adjust'] as num?)?.toInt() ?? 0,
      balanceDiff: (json['balance_diff'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        productId,
        name,
        code,
        uom,
        oldOfficialUnitCost,
        newUnitCost,
        openingQty,
        openingValue,
        inboundQty,
        inboundValue,
        rebateValue,
        saleQty,
        saleValueRecorded,
        lossQty,
        lossValueRecorded,
        closingQty,
        movingAvgEnd,
        periodicAvg,
        cogsTrueUp,
        lossTrueUp,
        roundingAdjust,
        closingValueAfter,
        lineAdjust,
        balanceDiff,
      ];
}

class CostRunView extends Equatable {
  const CostRunView({
    required this.runId,
    required this.code,
    required this.kind,
    required this.periodMonth,
    required this.status,
    required this.method,
    required this.fromSequence,
    required this.cutOffSequence,
    required this.cutOffAt,
    required this.createdAt,
    this.publishedAt,
    required this.blockers,
    required this.productCount,
    required this.changedCount,
    required this.totals,
    required this.alt,
    required this.lines,
  });

  final String runId;
  final String code;
  final CostRunKind kind;
  final DateTime periodMonth;
  final CostRunStatus status;
  final CostMethod method;
  final int fromSequence;
  final int cutOffSequence;
  final DateTime cutOffAt;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final List<CostBlocker> blockers;
  final int productCount;
  final int changedCount;
  final CostTotals totals;
  final CostAlt alt;
  final List<CostRunLineView> lines;

  CostRunView copyWith({CostRunStatus? status}) {
    return CostRunView(
      runId: runId,
      code: code,
      kind: kind,
      periodMonth: periodMonth,
      status: status ?? this.status,
      method: method,
      fromSequence: fromSequence,
      cutOffSequence: cutOffSequence,
      cutOffAt: cutOffAt,
      createdAt: createdAt,
      publishedAt: publishedAt,
      blockers: blockers,
      productCount: productCount,
      changedCount: changedCount,
      totals: totals,
      alt: alt,
      lines: lines,
    );
  }

  factory CostRunView.fromJson(Map<String, dynamic> json) {
    final rawBlockers = json['blockers'] as List<dynamic>? ?? const [];
    final rawLines = json['lines'] as List<dynamic>? ?? const [];
    return CostRunView(
      runId: json['run_id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      kind: CostRunKind.fromWire(json['kind'] as String?),
      periodMonth: _parseDateOnly(json['period_month']),
      status: CostRunStatus.fromWire(json['status'] as String?),
      method: costMethodFromWire(json['method'] as String?),
      fromSequence: (json['from_sequence'] as num?)?.toInt() ?? 0,
      cutOffSequence: (json['cut_off_sequence'] as num?)?.toInt() ?? 0,
      cutOffAt: _parseDateTime(json['cut_off_at']) ?? DateTime.now(),
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      publishedAt: _parseDateTime(json['published_at']),
      blockers: rawBlockers
          .whereType<Map<String, dynamic>>()
          .map(CostBlocker.fromJson)
          .toList(growable: false),
      productCount: (json['product_count'] as num?)?.toInt() ?? 0,
      changedCount: (json['changed_count'] as num?)?.toInt() ?? 0,
      totals: CostTotals.fromJson(
        (json['totals'] as Map<String, dynamic>?) ?? const {},
      ),
      alt: CostAlt.fromJson(
        (json['alt'] as Map<String, dynamic>?) ?? const {},
      ),
      lines: rawLines
          .whereType<Map<String, dynamic>>()
          .map(CostRunLineView.fromJson)
          .toList(growable: false),
    );
  }

  @override
  List<Object?> get props => [
        runId,
        code,
        kind,
        periodMonth,
        status,
        method,
        fromSequence,
        cutOffSequence,
        cutOffAt,
        createdAt,
        publishedAt,
        blockers,
        productCount,
        changedCount,
        totals,
        alt,
        lines,
      ];
}

class CostVersion extends Equatable {
  const CostVersion({
    required this.versionId,
    required this.unitCost,
    required this.method,
    required this.runCode,
    required this.publishedAt,
  });

  final String versionId;
  final num unitCost;
  final CostMethod method;
  final String runCode;
  final DateTime publishedAt;

  factory CostVersion.fromJson(Map<String, dynamic> json) {
    return CostVersion(
      versionId: json['version_id'] as String? ?? '',
      unitCost: (json['unit_cost'] as num?) ?? 0,
      method: costMethodFromWire(json['method'] as String?),
      runCode: json['run_code'] as String? ?? '',
      publishedAt: _parseDateTime(json['published_at']) ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [versionId, unitCost, method, runCode, publishedAt];
}

class CostVersionList extends Equatable {
  const CostVersionList({
    required this.productId,
    required this.name,
    required this.uom,
    required this.versions,
  });

  final String productId;
  final String name;
  final String uom;
  final List<CostVersion> versions;

  factory CostVersionList.fromJson(Map<String, dynamic> json) {
    final raw = json['versions'] as List<dynamic>? ?? const [];
    return CostVersionList(
      productId: json['product_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      uom: json['uom'] as String? ?? '',
      versions: raw
          .whereType<Map<String, dynamic>>()
          .map(CostVersion.fromJson)
          .toList(growable: false),
    );
  }

  @override
  List<Object?> get props => [productId, name, uom, versions];
}

