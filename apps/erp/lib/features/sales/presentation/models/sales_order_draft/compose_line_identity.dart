import 'package:equatable/equatable.dart';
import 'package:vet45_sales_application/application.dart';

/// Identity + catalog anchor cho một dòng compose — không đổi sau khi thêm SP.
final class ComposeLineIdentity extends Equatable {
  const ComposeLineIdentity({
    required this.lineId,
    required this.productId,
    required this.productUnitId,
    required this.productName,
    required this.unitLabel,
    required this.catalogUnitPrice,
  });

  final String lineId;
  final String productId;
  final String productUnitId;
  final String productName;
  final String unitLabel;

  /// Giá gốc lúc resolve/thêm dòng từ catalog — anchor trước preview.
  final MoneyDto catalogUnitPrice;

  ComposeLineIdentity copyWith({
    String? lineId,
    String? productId,
    String? productUnitId,
    String? productName,
    String? unitLabel,
    MoneyDto? catalogUnitPrice,
  }) {
    return ComposeLineIdentity(
      lineId: lineId ?? this.lineId,
      productId: productId ?? this.productId,
      productUnitId: productUnitId ?? this.productUnitId,
      productName: productName ?? this.productName,
      unitLabel: unitLabel ?? this.unitLabel,
      catalogUnitPrice: catalogUnitPrice ?? this.catalogUnitPrice,
    );
  }

  @override
  List<Object?> get props => [
    lineId,
    productId,
    productUnitId,
    productName,
    unitLabel,
    catalogUnitPrice.amountMinor,
    catalogUnitPrice.currencyCode,
  ];
}
