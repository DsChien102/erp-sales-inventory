import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';

Future<void> showPartnerDuplicateSheet({
  required BuildContext context,
  required PartnerDuplicateMatchLevel level,
  required List<PartnerDuplicateMatchDto> matches,
  required VoidCallback onBack,
  required VoidCallback onOpenExisting,
  VoidCallback? onContinue,
}) {
  return showVBottomSheet<void>(
    context: context,
    child: PartnerDuplicateSheet(
      level: level,
      matches: matches,
      onBack: onBack,
      onOpenExisting: onOpenExisting,
      onContinue: onContinue,
    ),
  );
}

class PartnerDuplicateSheet extends StatelessWidget {
  const PartnerDuplicateSheet({
    super.key,
    required this.level,
    required this.matches,
    required this.onBack,
    required this.onOpenExisting,
    this.onContinue,
  });

  final PartnerDuplicateMatchLevel level;
  final List<PartnerDuplicateMatchDto> matches;
  final VoidCallback onBack;
  final VoidCallback onOpenExisting;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final isExact = level == PartnerDuplicateMatchLevel.exact;
    final colors = context.vColors;
    return Padding(
      key: Key(isExact ? 'duplicate_exact' : 'duplicate_possible'),
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VIconBox(
            iconData: isExact ? Icons.warning_rounded : Icons.warning_amber_rounded,
            backgroundColor: isExact ? VColors.dangerBg : VColors.warningBg,
            iconColor: isExact ? VColors.danger : VColors.warning,
            isCircular: true,
            size: 48,
          ),
          const SizedBox(height: VSpacing.space3),
          Text(
            isExact ? 'Trùng khớp hoàn toàn' : 'Có thể là hồ sơ trùng',
            style: VTypography.headingH3.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: VSpacing.space2),
          Text(
            isExact
                ? 'Đã tồn tại hồ sơ trùng khớp hoàn toàn. Không thể tạo mới.'
                : 'Tìm thấy các hồ sơ có thông tin tương tự. Vui lòng kiểm tra trước khi tạo mới.',
            textAlign: TextAlign.center,
            style: VTypography.bodyDefault.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: VSpacing.space4),
          ...matches.map(
            (match) => Padding(
              padding: const EdgeInsets.only(bottom: VSpacing.space2),
              child: VCard(
                onTap: onOpenExisting,
                child: Row(
                  children: [
                    const VIconBox(iconData: Icons.person_outline, size: 36),
                    const SizedBox(width: VSpacing.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            match.displayName,
                            style: VTypography.bodyDefault.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (match.matchedValue != null)
                            Text(
                              match.matchedValue!,
                              style: VTypography.bodySmall.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: VSpacing.space2),
          if (!isExact)
            VButton(
              key: const Key('btn_continue_create'),
              label: 'Tiếp tục tạo mới',
              fullWidth: true,
              onPressed: onContinue,
            )
          else
            VButton(
              key: const Key('btn_open_duplicate'),
              label: 'Đi đến hồ sơ',
              fullWidth: true,
              onPressed: onOpenExisting,
            ),
          const SizedBox(height: VSpacing.space2),
          VButton(
            label: 'Quay lại',
            fullWidth: true,
            variant: VButtonVariant.ghost,
            onPressed: onBack,
          ),
        ],
      ),
    );
  }
}
