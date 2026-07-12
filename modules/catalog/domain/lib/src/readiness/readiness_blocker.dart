import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'readiness_blocker_code.dart';

final class ReadinessBlocker extends ValueObject {
  const ReadinessBlocker({
    required this.code,
    required this.message,
    this.group,
  });

  final String code;
  final String message;
  final String? group;

  factory ReadinessBlocker.missingBaseUnit() => const ReadinessBlocker(
    code: ReadinessBlockerCode.missingBaseUnit,
    message: 'Thiếu đơn vị cơ sở',
    group: 'units',
  );

  factory ReadinessBlocker.missingImage() => const ReadinessBlocker(
    code: ReadinessBlockerCode.missingImage,
    message: 'Chưa có ảnh sản phẩm',
    group: 'profile',
  );

  factory ReadinessBlocker.missingPrice() => const ReadinessBlocker(
    code: ReadinessBlockerCode.missingPrice,
    message: 'Thiếu giá',
    group: 'pricing',
  );

  factory ReadinessBlocker.missingPriceBand() => const ReadinessBlocker(
    code: ReadinessBlockerCode.missingPriceBand,
    message: 'Thiếu khung giá bán',
    group: 'pricing',
  );

  factory ReadinessBlocker.missingStock() => const ReadinessBlocker(
    code: ReadinessBlockerCode.missingStock,
    message: 'Thiếu thiết lập tồn kho',
    group: 'stock',
  );

  factory ReadinessBlocker.missingRequiredCustomFields() => const ReadinessBlocker(
    code: ReadinessBlockerCode.missingRequiredCustomFields,
    message: 'Thiếu thông tin bổ sung bắt buộc',
    group: 'custom_fields',
  );

  factory ReadinessBlocker.pendingStockFromInventory() => const ReadinessBlocker(
    code: ReadinessBlockerCode.pendingStockFromInventory,
    message: 'Chờ dữ liệu tồn kho từ module Kho',
    group: 'stock',
  );

  factory ReadinessBlocker.pendingBasePriceFromCosting() => const ReadinessBlocker(
    code: ReadinessBlockerCode.pendingBasePriceFromCosting,
    message: 'Chờ Giá cơ sở từ module Giá vốn',
    group: 'pricing',
  );

  @override
  List<Object?> get props => [code, message, group];
}
