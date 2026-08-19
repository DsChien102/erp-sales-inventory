import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

enum ProviderConnectionAction { recheck, reconnect, disconnect }

Future<ProviderConnectionAction?> showProviderConnectionActionSheet(
  BuildContext context,
) {
  return showVBottomSheet<ProviderConnectionAction>(
    context: context,
    child: const ProviderConnectionActionSheet(),
  );
}

class ProviderConnectionActionSheet extends StatelessWidget {
  const ProviderConnectionActionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    void select(ProviderConnectionAction action) {
      Navigator.of(context).pop(action);
    }

    return Material(
      key: const Key('wgt_e01_u01_fr06_01'),
      color: colors.surface.withValues(alpha: 0),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VSpacing.space4,
                  VSpacing.space4,
                  VSpacing.space4,
                  VSpacing.space2,
                ),
                child: VText(
                  'Kết nối MISA',
                  variant: VTextVariant.headingH3,
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              _ProviderConnectionActionCard(
                key: const Key('action_recheck'),
                icon: VIcons.refresh,
                iconBackground: colors.infoBg,
                iconColor: colors.info,
                title: 'Kiểm tra lại kết nối',
                subtitle: 'Xác minh trạng thái kết nối hiện tại',
                onTap: () => select(ProviderConnectionAction.recheck),
              ),
              _ProviderConnectionActionCard(
                key: const Key('action_reconnect'),
                icon: VIcons.key,
                iconBackground: colors.warningBg,
                iconColor: colors.warning,
                title: 'Kết nối lại',
                subtitle: 'Thay đổi tài khoản hoặc mật khẩu',
                onTap: () => select(ProviderConnectionAction.reconnect),
              ),
              _ProviderConnectionActionCard(
                key: const Key('action_disconnect'),
                icon: VIcons.unplug,
                iconBackground: colors.dangerBg,
                iconColor: colors.danger,
                title: 'Ngắt kết nối',
                subtitle: 'Không thể phát hành hóa đơn điện tử mới',
                onTap: () => select(ProviderConnectionAction.disconnect),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VSpacing.space4,
                  VSpacing.space3,
                  VSpacing.space4,
                  VSpacing.space4,
                ),
                child: VButton(
                  key: const Key('action_sheet_cancel'),
                  label: 'Hủy',
                  variant: VButtonVariant.secondary,
                  foregroundColor: colors.textPrimary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderConnectionActionCard extends StatelessWidget {
  const _ProviderConnectionActionCard({
    super.key,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final VIcons icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space2,
      ),
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VRadius.card),
          side: BorderSide(color: colors.borderDefault),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Row(
              children: [
                VIconBox(
                  icon: icon,
                  size: 44,
                  iconSize: 22,
                  isCircular: true,
                  backgroundColor: iconBackground,
                  iconColor: iconColor,
                ),
                const VGap.horizontalMd(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VText(
                        title,
                        variant: VTextVariant.bodyDefault,
                        color: colors.textPrimary,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const VGap.xs(),
                      VText(
                        subtitle,
                        variant: VTextVariant.bodySmall,
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ),
                const VGap.horizontalSm(),
                VIcon(
                  icon: VIcons.chevronRight,
                  color: colors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
