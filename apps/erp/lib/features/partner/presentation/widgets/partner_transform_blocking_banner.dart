import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Blocking warning shown when transform step-one validation fails.
class PartnerTransformBlockingBanner extends StatelessWidget {
  const PartnerTransformBlockingBanner({
    super.key,
    this.message = 'Không thể chuyển đổi khi thiếu thông tin bắt buộc hoặc dữ liệu bị trùng.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return VBanner(
      key: const Key('transform_blocking_banner'),
      status: VBannerStatus.warning,
      title: message,
    );
  }
}
