import 'package:vet45_catalog_domain/domain.dart';

/// Base price card on Product Control Center (EPIC-06/US-01).
final class ProductBasePriceCardDto {
  const ProductBasePriceCardDto({
    required this.mode,
    required this.sourceLabel,
    this.amount,
    this.currency = 'VND',
    this.baseUnitName,
    this.canEdit = false,
    this.isPendingExternal = false,
    this.isMissing = false,
    this.missingMessage,
  });

  final BasePriceMode mode;
  final String sourceLabel;
  final double? amount;
  final String currency;
  final String? baseUnitName;
  final bool canEdit;
  final bool isPendingExternal;
  final bool isMissing;
  final String? missingMessage;

  static String sourceLabelFor(BasePriceMode mode) => switch (mode) {
    BasePriceMode.manual => 'Nhập thủ công',
    BasePriceMode.costingModule => 'Từ module Giá vốn',
  };
}
