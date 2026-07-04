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

  @override
  List<Object?> get props => [code, message, group];
}
