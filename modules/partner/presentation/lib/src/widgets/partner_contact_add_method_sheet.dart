import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

enum AddContactMethod { createNew, selectExisting }

class PartnerContactAddMethodSheet extends StatelessWidget {
  const PartnerContactAddMethodSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VBottomSheet(
      child: Material(
        color: Colors.transparent,
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
                  child: Text(
                    'Thêm người liên hệ',
                    style: VTypography.headingH3.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: VSpacing.space2),
                
                // Option 1: Tạo người liên hệ mới (Card style)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.space4,
                    vertical: VSpacing.space2,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border.all(color: colors.borderDefault),
                      borderRadius: BorderRadius.circular(VRadius.card),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(AddContactMethod.createNew),
                        borderRadius: BorderRadius.circular(VRadius.card),
                        child: Padding(
                          padding: const EdgeInsets.all(VSpacing.space4),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: colors.success.withValues(alpha: 0.1),
                                child: Icon(Icons.person_add_outlined, color: colors.success),
                              ),
                              const SizedBox(width: VSpacing.space3),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tạo người liên hệ mới',
                                      style: VTypography.bodyDefault.copyWith(
                                        color: colors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Nhập thông tin để tạo người liên hệ mới',
                                      style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: colors.textMuted),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Option 2: Chọn từ cá nhân có sẵn (Card style)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.space4,
                    vertical: VSpacing.space2,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border.all(color: colors.borderDefault),
                      borderRadius: BorderRadius.circular(VRadius.card),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(AddContactMethod.selectExisting),
                        borderRadius: BorderRadius.circular(VRadius.card),
                        child: Padding(
                          padding: const EdgeInsets.all(VSpacing.space4),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: colors.info.withValues(alpha: 0.1),
                                child: Icon(Icons.search_rounded, color: colors.info),
                              ),
                              const SizedBox(width: VSpacing.space3),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Chọn từ cá nhân có sẵn',
                                      style: VTypography.bodyDefault.copyWith(
                                        color: colors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tìm kiếm và liên kết cá nhân đã có trong hệ thống',
                                      style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: colors.textMuted),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: VSpacing.space4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
                  child: VButton(
                    label: 'Hủy',
                    variant: VButtonVariant.outline,
                    foregroundColor: colors.success,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(height: VSpacing.space4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
