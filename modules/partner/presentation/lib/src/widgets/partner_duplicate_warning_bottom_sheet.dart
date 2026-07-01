import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

class PartnerDuplicateWarningBottomSheet extends StatelessWidget {
  final List<PartnerDuplicateMatchDto> warnings;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final VoidCallback onViewExisting;

  const PartnerDuplicateWarningBottomSheet({
    super.key,
    required this.warnings,
    required this.onCancel,
    required this.onConfirm,
    required this.onViewExisting,
  });

  String _getFieldLabel(PartnerDuplicateField field) {
    return switch (field) {
      PartnerDuplicateField.phone => 'Số điện thoại',
      PartnerDuplicateField.email => 'Email',
      PartnerDuplicateField.taxCode => 'Mã số thuế',
    };
  }

  String _avatarText(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    final lastTwo = parts.sublist(parts.length - 2);
    return lastTwo.map((part) => part.substring(0, 1)).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    
    // Default to the first warning's field if multiple
    final firstField = warnings.isNotEmpty ? _getFieldLabel(warnings.first.field) : 'Thông tin';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Thông tin này đã tồn tại ở một KH & NCC khác',
                    style: VTypography.headingH3.copyWith(
                      color: dynamicColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.close, color: dynamicColors.textPrimary),
                  onPressed: onCancel,
                ),
              ],
            ),
            const SizedBox(height: VSpacing.space2),
            Divider(color: dynamicColors.borderDefault, height: 1),
            const SizedBox(height: VSpacing.space4),
            Text(
              '$firstField đang trùng với KH & NCC sau:',
              style: VTypography.bodyDefault.copyWith(
                color: dynamicColors.textSecondary,
              ),
            ),
            const SizedBox(height: VSpacing.space3),
            ...warnings.map((match) => Padding(
                  padding: const EdgeInsets.only(bottom: VSpacing.space4),
                  child: Container(
                    padding: const EdgeInsets.all(VSpacing.space3),
                    decoration: BoxDecoration(
                      border: Border.all(color: dynamicColors.borderDefault),
                      borderRadius: BorderRadius.circular(VRadius.card),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: VColors.successBg,
                          child: Text(
                            _avatarText(match.displayName),
                            style: VTypography.bodyDefault.copyWith(
                              color: VColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: VSpacing.space3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                match.displayName,
                                style: VTypography.bodyDefault.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: dynamicColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Optional badges could go here if available
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: VColors.infoBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Khách hàng', // Placeholder
                                      style: VTypography.bodySmall.copyWith(
                                        color: VColors.info,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: VColors.successBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Đang hoạt động', // Placeholder
                                      style: VTypography.bodySmall.copyWith(
                                        color: VColors.success,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                match.matchedValue,
                                style: VTypography.bodySmall.copyWith(
                                  color: dynamicColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
            VButton(
              onPressed: onViewExisting,
              label: 'Xem KH & NCC hiện có',
              variant: VButtonVariant.outline,
            ),
            const SizedBox(height: VSpacing.space3),
            VButton(
              onPressed: onCancel,
              label: 'Quay lại chỉnh sửa',
              variant: VButtonVariant.outline,
            ),
            const SizedBox(height: VSpacing.space3),
            VButton(
              onPressed: onConfirm,
              label: 'Vẫn lưu',
              variant: VButtonVariant.warning,
            ),
          ],
        ),
      ),
    );
  }
}
