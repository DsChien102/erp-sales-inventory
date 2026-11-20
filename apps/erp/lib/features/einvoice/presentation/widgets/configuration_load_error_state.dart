import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/einvoice/presentation/support/configuration_state_copy.dart';

class ConfigurationLoadErrorState extends StatelessWidget {
  const ConfigurationLoadErrorState({
    super.key,
    this.onRetry,
  });

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: VEmptyState(
        key: const Key('wgt_e01_s02_01'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const VEmptyHeader(
              children: [
                VEmptyMedia(
                  icon: VIcons.error,
                  tone: VComponentTone.danger,
                ),
                VEmptyTitle(ConfigurationStateCopy.loadErrorTitle),
                VEmptyDescription(ConfigurationStateCopy.loadErrorDescription),
              ],
            ),
            VEmptyContent(
              child: VButton(
                label: ConfigurationStateCopy.loadErrorAction,
                variant: VButtonVariant.link,
                onPressed: onRetry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
