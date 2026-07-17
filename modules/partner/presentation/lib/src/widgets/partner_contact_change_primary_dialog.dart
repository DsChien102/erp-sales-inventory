import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class PartnerContactChangePrimaryDialog extends StatelessWidget {
  const PartnerContactChangePrimaryDialog({
    super.key,
    required this.currentPrimaryName,
    required this.newPrimaryName,
  });

  final String currentPrimaryName;
  final String newPrimaryName;

  Color _getAvatarColor(String displayName) {
    final palette = [
      VColors.success,
      VColors.warning,
      VColors.info,
      VColors.primary,
      const Color(0xFF9C27B0),
      const Color(0xFF00BCD4),
    ];
    int sum = 0;
    for (int i = 0; i < displayName.length; i++) {
      sum += displayName.codeUnitAt(i);
    }
    return palette[sum % palette.length];
  }

  String _getInitials(String displayName) {
    final words = displayName.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return '${words[0].substring(0, 1)}${words.last.substring(0, 1)}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VBottomSheet(
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              VSpacing.space4,
              VSpacing.space2,
              VSpacing.space4,
              VSpacing.space4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Đổi người liên hệ chính?',
                  textAlign: TextAlign.center,
                  style: VTypography.headingH3.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: VSpacing.space3),
                Text(
                  '$currentPrimaryName hiện đang là người liên hệ chính. Nếu tiếp tục, $newPrimaryName sẽ trở thành người liên hệ chính mới.',
                  textAlign: TextAlign.center,
                  style: VTypography.bodyDefault.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: VSpacing.space4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: _getAvatarColor(currentPrimaryName),
                      child: Text(
                        _getInitials(currentPrimaryName),
                        style: VTypography.bodyDefault.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: VSpacing.space4),
                    VIcon(
                      icon: VIcons.arrowForward,
                      color: colors.textMuted,
                      size: 24,
                    ),
                    const SizedBox(width: VSpacing.space4),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: _getAvatarColor(newPrimaryName),
                      child: Text(
                        _getInitials(newPrimaryName),
                        style: VTypography.bodyDefault.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VSpacing.space5),
                Row(
                  children: [
                    Expanded(
                      child: VButton(
                        label: 'Quay lại',
                        variant: VButtonVariant.outline,
                        foregroundColor: colors.success,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: VSpacing.space3),
                    Expanded(
                      child: VButton(
                        label: 'Xác nhận đổi',
                        variant: VButtonVariant.primary,
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
