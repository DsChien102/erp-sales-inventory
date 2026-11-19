import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

/// Warning when required soft-completeness fields are missing (D-03).
class PartnerDetailWarningBanner extends StatelessWidget {
  const PartnerDetailWarningBanner({
    super.key,
    required this.description,
  });

  final String description;

  @override
  Widget build(BuildContext context) {
    return VBanner(
      status: VBannerStatus.warning,
      title: 'Hồ sơ còn thiếu thông tin',
      description: description,
    );
  }
}

/// Banner when partner is inactive (SG-07 / D-04).
class PartnerDetailInactiveBanner extends StatelessWidget {
  const PartnerDetailInactiveBanner({super.key});

  static const message = 'KH & NCC này sẽ không được chọn cho giao dịch mới.';

  @override
  Widget build(BuildContext context) {
    return const VBanner(
      key: Key('wgt_e02_u01_fr02_01'),
      status: VBannerStatus.warning,
      title: message,
    );
  }
}
