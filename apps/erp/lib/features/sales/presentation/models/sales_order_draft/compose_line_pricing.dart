import 'package:equatable/equatable.dart';
import 'package:erp/features/sales/data/models.dart';

import '../shared/sales_pricing_models.dart';

/// Số tiền authoritative sau pricing preview — một bộ duy nhất, không fallback.
final class ComposePricedAmounts extends Equatable {
  const ComposePricedAmounts({
    required this.listUnitPrice,
    required this.appliedUnitPrice,
    required this.unitDiscount,
    required this.lineTotal,
    this.floorUnitPrice,
  });

  final MoneyDto listUnitPrice;
  final MoneyDto appliedUnitPrice;
  final MoneyDto unitDiscount;
  final MoneyDto lineTotal;
  final MoneyDto? floorUnitPrice;

  factory ComposePricedAmounts.fromPreviewLine(SalesPricingLineResult line) {
    return ComposePricedAmounts(
      listUnitPrice: line.listUnitPrice ?? line.appliedUnitPrice,
      appliedUnitPrice: line.appliedUnitPrice,
      unitDiscount: line.discount,
      lineTotal: line.lineTotal,
      floorUnitPrice: line.floorUnitPrice,
    );
  }

  factory ComposePricedAmounts.fromDraftLine({
    required SalesOrderDraftLineDto saved,
    required MoneyDto catalogUnitPrice,
  }) {
    return ComposePricedAmounts(
      listUnitPrice: saved.listUnitPrice ?? catalogUnitPrice,
      appliedUnitPrice: saved.appliedUnitPrice,
      unitDiscount: MoneyDto(
        amountMinor: _unitDiscountFromDraft(saved),
        currencyCode: saved.appliedUnitPrice.currencyCode,
      ),
      lineTotal: saved.lineTotal,
      floorUnitPrice: null,
    );
  }

  static int _unitDiscountFromDraft(SalesOrderDraftLineDto saved) {
    final list = saved.listUnitPrice?.amountMinor ?? saved.appliedUnitPrice.amountMinor;
    final delta = list - saved.appliedUnitPrice.amountMinor;
    if (delta > 0) return delta;
    return 0;
  }

  @override
  List<Object?> get props => [
    listUnitPrice.amountMinor,
    appliedUnitPrice.amountMinor,
    unitDiscount.amountMinor,
    lineTotal.amountMinor,
    floorUnitPrice?.amountMinor,
  ];
}

/// Metadata pricing từ preview — nguồn, blockers, warnings.
final class ComposePricingMeta extends Equatable {
  const ComposePricingMeta({
    this.sourceCode,
    this.blockingCodes = const [],
    this.warningCodes = const [],
  });

  final String? sourceCode;
  final List<String> blockingCodes;
  final List<String> warningCodes;

  factory ComposePricingMeta.fromPreviewLine(SalesPricingLineResult line) {
    return ComposePricingMeta(
      sourceCode: line.sourceCode,
      blockingCodes: line.blockingCodes,
      warningCodes: line.warningCodes,
    );
  }

  ComposePricingMeta mergeBlockers(Iterable<String> extra) {
    if (extra.isEmpty) return this;
    return ComposePricingMeta(
      sourceCode: sourceCode,
      blockingCodes: [...blockingCodes, ...extra].toList(growable: false),
      warningCodes: warningCodes,
    );
  }

  ComposePricingMeta copyWith({
    String? sourceCode,
    List<String>? blockingCodes,
    List<String>? warningCodes,
  }) {
    return ComposePricingMeta(
      sourceCode: sourceCode ?? this.sourceCode,
      blockingCodes: blockingCodes ?? this.blockingCodes,
      warningCodes: warningCodes ?? this.warningCodes,
    );
  }

  @override
  List<Object?> get props => [sourceCode, blockingCodes, warningCodes];
}

/// Trạng thái pricing của dòng — sealed thay cho nullable rải rác.
sealed class ComposeLinePricing extends Equatable {
  const ComposeLinePricing();

  bool get isReady => this is ComposeLinePricingReady;

  ComposeLinePricingReady? get asReady =>
      switch (this) {
        ComposeLinePricingReady ready => ready,
        _ => null,
      };

  int get contextVersion => switch (this) {
    ComposeLinePricingReady(:final contextVersion) => contextVersion,
    _ => -1,
  };

  MoneyDto get appliedUnitPrice => switch (this) {
    ComposeLinePricingReady(:final amounts) => amounts.appliedUnitPrice,
    ComposeLinePricingNotReady(:final provisionalAppliedUnitPrice) =>
      provisionalAppliedUnitPrice,
  };

  MoneyDto? get listUnitPrice => switch (this) {
    ComposeLinePricingReady(:final amounts) => amounts.listUnitPrice,
    ComposeLinePricingNotReady(:final provisionalListUnitPrice) => provisionalListUnitPrice,
  };

  MoneyDto? get floorUnitPrice => switch (this) {
    ComposeLinePricingReady(:final amounts) => amounts.floorUnitPrice,
    ComposeLinePricingNotReady(:final provisionalFloorUnitPrice) => provisionalFloorUnitPrice,
  };

  MoneyDto? get lineTotal => switch (this) {
    ComposeLinePricingReady(:final amounts) => amounts.lineTotal,
    _ => null,
  };

  MoneyDto? get unitDiscount => switch (this) {
    ComposeLinePricingReady(:final amounts) => amounts.unitDiscount,
    _ => null,
  };

  String? get sourceCode => switch (this) {
    ComposeLinePricingReady(:final meta) => meta.sourceCode,
    _ => null,
  };

  List<String> get blockingCodes => switch (this) {
    ComposeLinePricingReady(:final meta) => meta.blockingCodes,
    _ => const [],
  };

  List<String> get warningCodes => switch (this) {
    ComposeLinePricingReady(:final meta) => meta.warningCodes,
    _ => const [],
  };
}

/// Chưa có preview khớp context — hiển thị provisional từ catalog/selection.
final class ComposeLinePricingNotReady extends ComposeLinePricing {
  const ComposeLinePricingNotReady({
    required this.provisionalAppliedUnitPrice,
    this.provisionalListUnitPrice,
    this.provisionalFloorUnitPrice,
  });

  final MoneyDto provisionalAppliedUnitPrice;
  final MoneyDto? provisionalListUnitPrice;
  final MoneyDto? provisionalFloorUnitPrice;

  @override
  List<Object?> get props => [
    provisionalAppliedUnitPrice.amountMinor,
    provisionalListUnitPrice?.amountMinor,
    provisionalFloorUnitPrice?.amountMinor,
  ];
}

/// Preview authoritative — single source of truth cho tiền dòng.
final class ComposeLinePricingReady extends ComposeLinePricing {
  const ComposeLinePricingReady({
    required this.contextVersion,
    required this.amounts,
    required this.meta,
  });

  @override
  final int contextVersion;

  final ComposePricedAmounts amounts;
  final ComposePricingMeta meta;

  ComposeLinePricingReady copyWith({
    int? contextVersion,
    ComposePricedAmounts? amounts,
    ComposePricingMeta? meta,
  }) {
    return ComposeLinePricingReady(
      contextVersion: contextVersion ?? this.contextVersion,
      amounts: amounts ?? this.amounts,
      meta: meta ?? this.meta,
    );
  }

  @override
  List<Object?> get props => [contextVersion, amounts, meta];
}
