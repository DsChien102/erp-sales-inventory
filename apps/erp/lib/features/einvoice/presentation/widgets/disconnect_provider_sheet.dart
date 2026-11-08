import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Content of the disconnect confirmation (HD-03). Pops `true` on confirm and
/// `false` on keep.
class DisconnectProviderSheet extends StatelessWidget {
  const DisconnectProviderSheet({super.key});

  static const title = 'Ngắt kết nối MISA?';
  static const message =
      'Sau khi ngắt kết nối, không thể phát hành hóa đơn điện tử mới. Hóa đơn và lịch sử đã phát sinh vẫn được giữ nguyên.';
  static const cancelLabel = 'Giữ kết nối';
  static const actionLabel = 'Ngắt kết nối';

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Material(
      key: const Key('wgt_e01_u01_fr08_01'),
      color: colors.surface.withValues(alpha: 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          VSpacing.space4,
          VSpacing.space3,
          VSpacing.space4,
          VSpacing.space4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            VText(
              message,
              variant: VTextVariant.bodyDefault,
              color: colors.textSecondary,
            ),
            const VGap.lg(),
            VButton(
              label: actionLabel,
              variant: VButtonVariant.primary,
              tone: VComponentTone.danger,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const VGap.sm(),
            VButton(
              label: cancelLabel,
              variant: VButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> showDisconnectProviderSheet(BuildContext context) async {
  final result = await showVAdaptiveSheet<bool>(
    context: context,
    title: DisconnectProviderSheet.title,
    semanticLabel: DisconnectProviderSheet.title,
    child: const DisconnectProviderSheet(),
  );
  return result ?? false;
}
