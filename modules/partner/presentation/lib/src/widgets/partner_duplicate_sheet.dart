import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

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

  bool get _isExact => level == PartnerDuplicateMatchLevel.exact;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Padding(
      key: Key(_isExact ? 'duplicate_exact' : 'duplicate_possible'),
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VIconBox(
            icon: VIcons.warning,
            backgroundColor: _isExact ? VColors.dangerBg : VColors.warningBg,
            iconColor: _isExact ? VColors.danger : VColors.warning,
            isCircular: true,
            size: 48,
            iconSize: 24,
          ),
          const SizedBox(height: VSpacing.space3),
          Text(
            _isExact ? 'Trùng khớp hoàn toàn' : 'Có thể là hồ sơ trùng',
            textAlign: TextAlign.center,
            style: VTypography.headingH3.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: VSpacing.space2),
          Text(
            _isExact
                ? 'Đã tồn tại hồ sơ trùng khớp hoàn toàn. Không thể tạo mới.'
                : 'Tìm thấy các hồ sơ có thông tin tương tự. Vui lòng kiểm tra trước khi tạo mới.',
            textAlign: TextAlign.center,
            style: VTypography.bodyDefault.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: VSpacing.space4),
          ...matches.map(
            (match) => Padding(
              padding: const EdgeInsets.only(bottom: VSpacing.space2),
              child: _DuplicateMatchCard(match: match),
            ),
          ),
          const SizedBox(height: VSpacing.space2),
          if (_isExact) ...[
            VButton(
              key: const Key('btn_open_duplicate'),
              label: 'Đi đến hồ sơ',
              fullWidth: true,
              onPressed: onOpenExisting,
            ),
            const SizedBox(height: VSpacing.space2),
            VButton(
              key: const Key('btn_back_from_duplicate'),
              label: 'Quay lại',
              fullWidth: true,
              variant: VButtonVariant.outline,
              onPressed: onBack,
            ),
          ] else ...[
            VButton(
              key: const Key('btn_continue_create'),
              label: 'Tiếp tục tạo mới',
              fullWidth: true,
              onPressed: onContinue,
            ),
            const SizedBox(height: VSpacing.space2),
            VButton(
              key: const Key('btn_view_duplicate_detail'),
              label: 'Xem chi tiết',
              fullWidth: true,
              variant: VButtonVariant.outline,
              onPressed: onOpenExisting,
            ),
          ],
        ],
      ),
    );
  }
}

class _DuplicateMatchCard extends StatelessWidget {
  const _DuplicateMatchCard({required this.match});

  final PartnerDuplicateMatchDto match;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final subtitle = _formatMatchedValue(
      field: match.matchedField,
      value: match.matchedValue,
    );

    return VCard(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space3,
        vertical: VSpacing.space3,
      ),
      child: Row(
        children: [
          VIconBox(
            icon: match.partnerType == PartnerType.person
                ? VIcons.person
                : VIcons.apartment,
            size: 40,
            backgroundColor: colors.surfaceBrand,
            iconColor: colors.primary,
          ),
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
                if (subtitle != null) ...[
                  const SizedBox(height: VSpacing.space1),
                  Text(
                    subtitle,
                    style: VTypography.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String? _formatMatchedValue({
    required PartnerDuplicateMatchField field,
    required String? value,
  }) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final label = switch (field) {
      PartnerDuplicateMatchField.phone => 'SĐT',
      PartnerDuplicateMatchField.email => 'Email',
      PartnerDuplicateMatchField.taxCode => 'MST',
      PartnerDuplicateMatchField.name => 'Tên',
    };

    return '$label: $value';
  }
}
