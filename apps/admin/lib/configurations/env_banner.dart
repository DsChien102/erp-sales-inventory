import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'env.dart';

/// Non-production environment indicator (DEV / STAGING).
class EnvBanner extends StatelessWidget {
  const EnvBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final label = Env.environmentBannerLabel;
    if (label == null) {
      return child;
    }

    return Banner(
      message: label,
      location: BannerLocation.topEnd,
      color: Env.isStaging ? VColors.warning : VColors.info,
      textStyle: VTypography.bodySmall.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 10,
      ),
      child: child,
    );
  }
}
