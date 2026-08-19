import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../support/configuration_state_copy.dart';

class ConfigurationPermissionDeniedState extends StatelessWidget {
  const ConfigurationPermissionDeniedState({
    super.key,
    this.onBack,
  });

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: VEmptyState(
        key: const Key('wgt_e01_s01_01'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const VEmptyHeader(
              children: [
                VEmptyMedia(
                  icon: VIcons.lock,
                  tone: VComponentTone.warning,
                ),
                VEmptyTitle(ConfigurationStateCopy.permissionTitle),
                VEmptyDescription(ConfigurationStateCopy.permissionDescription),
              ],
            ),
            VEmptyContent(
              child: VButton(
                label: ConfigurationStateCopy.permissionAction,
                variant: VButtonVariant.link,
                onPressed: onBack,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
