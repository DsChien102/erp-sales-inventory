import 'package:equatable/equatable.dart';
import 'package:vet45_sales_application/application.dart';

/// Một đơn vị bán hợp lệ thuộc sản phẩm (Catalog snapshot mirror cho FE shell).
final class SalesProductUnitVm extends Equatable {
  const SalesProductUnitVm({
    required this.productUnitId,
    required this.unitCode,
    required this.unitName,
    required this.unitPrice,
    this.isDefault = false,
    this.isBlocked = false,
    this.blockReason,
    this.stockQuantity,
    this.listUnitPrice,
    this.floorUnitPrice,
  });

  final String productUnitId;
  final String unitCode;
  final String unitName;
  final MoneyDto unitPrice;
  final bool isDefault;
  final bool isBlocked;
  final String? blockReason;

  /// Tồn theo đơn vị bán (ước lượng từ tồn cơ sở khi có conversion).
  final int? stockQuantity;
  final MoneyDto? listUnitPrice;
  final MoneyDto? floorUnitPrice;

  @override
  List<Object?> get props => [
    productUnitId,
    unitCode,
    unitName,
    unitPrice.amountMinor,
    isDefault,
    isBlocked,
    blockReason,
    stockQuantity,
    listUnitPrice?.amountMinor,
    floorUnitPrice?.amountMinor,
  ];
}

/// Row sản phẩm bán được trong SG-03 (không phải master Product UI).
final class SalesSellableProductVm extends Equatable {
  const SalesSellableProductVm({
    required this.productId,
    required this.sku,
    required this.displayName,
    required this.units,
    this.tradeName,
    this.barcode,
    this.isBlocked = false,
    this.blockReason,
    this.availabilityLabel,
    this.warningLabel,
    this.stockQuantity,
    this.packLabel,
  });

  final String productId;
  final String sku;
  final String displayName;
  final String? tradeName;
  final List<SalesProductUnitVm> units;
  final String? barcode;
  final bool isBlocked;
  final String? blockReason;
  final String? availabilityLabel;
  final String? warningLabel;

  /// Tồn đơn vị cơ sở (hiển thị trên search vcard — Hình 2).
  final int? stockQuantity;

  /// Quy cách ngắn cho subtitle vcard (vd. `Hộp 20 viên`).
  final String? packLabel;

  SalesProductUnitVm? get defaultUnit {
    for (final unit in units) {
      if (unit.isDefault && !unit.isBlocked) return unit;
    }
    for (final unit in units) {
      if (!unit.isBlocked) return unit;
    }
    return null;
  }

  List<SalesProductUnitVm> get selectableUnits =>
      units.where((u) => !u.isBlocked).toList(growable: false);

  bool get needsUnitPicker => selectableUnits.length > 1;

  /// Đơn vị cơ sở dùng trên search suggestion (Hình 2).
  SalesProductUnitVm? get baseUnitForSearch => defaultUnit;

  String get unitSummary {
    final base = baseUnitForSearch;
    if (base != null) return base.unitName;
    final selectable = selectableUnits;
    if (selectable.isEmpty) return 'Không có đơn vị bán';
    if (selectable.length == 1) return selectable.first.unitName;
    return '${selectable.length} đơn vị';
  }

  MoneyDto? get referencePrice => baseUnitForSearch?.unitPrice;

  SalesSellableProductVm copyWith({
    List<SalesProductUnitVm>? units,
    String? tradeName,
    int? stockQuantity,
    String? availabilityLabel,
    String? warningLabel,
    String? packLabel,
  }) {
    return SalesSellableProductVm(
      productId: productId,
      sku: sku,
      displayName: displayName,
      tradeName: tradeName ?? this.tradeName,
      units: units ?? this.units,
      barcode: barcode,
      isBlocked: isBlocked,
      blockReason: blockReason,
      availabilityLabel: availabilityLabel ?? this.availabilityLabel,
      warningLabel: warningLabel ?? this.warningLabel,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      packLabel: packLabel ?? this.packLabel,
    );
  }

  @override
  List<Object?> get props => [
    productId,
    sku,
    displayName,
    tradeName,
    units,
    barcode,
    isBlocked,
    blockReason,
    availabilityLabel,
    warningLabel,
    stockQuantity,
    packLabel,
  ];
}

/// Kết quả chọn ProductUnit trả về SG-02.
final class SalesProductSelection extends Equatable {
  const SalesProductSelection({
    required this.productId,
    required this.productUnitId,
    required this.productName,
    required this.sku,
    required this.unitLabel,
    required this.unitPrice,
    this.stockQuantity,
    this.listUnitPrice,
    this.floorUnitPrice,
  });

  final String productId;
  final String productUnitId;
  final String productName;
  final String sku;
  final String unitLabel;
  final MoneyDto unitPrice;

  /// Tồn theo đơn vị bán đã chọn.
  final int? stockQuantity;
  final MoneyDto? listUnitPrice;
  final MoneyDto? floorUnitPrice;

  factory SalesProductSelection.fromProductUnit({
    required SalesSellableProductVm product,
    required SalesProductUnitVm unit,
  }) {
    final unitPrice = unit.unitPrice;
    final list = unit.listUnitPrice ?? unitPrice;
    final floor =
        unit.floorUnitPrice ??
        MoneyDto(
          amountMinor: (unitPrice.amountMinor * 0.92).round(),
          currencyCode: unitPrice.currencyCode,
        );
    return SalesProductSelection(
      productId: product.productId,
      productUnitId: unit.productUnitId,
      productName: product.displayName,
      sku: product.sku,
      unitLabel: unit.unitName,
      unitPrice: unitPrice,
      stockQuantity: unit.stockQuantity ?? product.stockQuantity,
      listUnitPrice: list,
      floorUnitPrice: floor,
    );
  }

  @override
  List<Object?> get props => [
    productId,
    productUnitId,
    productName,
    sku,
    unitLabel,
    unitPrice.amountMinor,
    stockQuantity,
    listUnitPrice?.amountMinor,
    floorUnitPrice?.amountMinor,
  ];
}
