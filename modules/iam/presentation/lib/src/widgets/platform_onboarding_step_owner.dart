import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';

class PlatformOnboardingStepOwner extends StatelessWidget {
  const PlatformOnboardingStepOwner({
    super.key,
    required this.isNewOwner,
    required this.selectedOwner,
    required this.lastNameController,
    required this.firstNameController,
    required this.emailController,
    required this.phoneController,
    required this.searchResults,
    required this.onOwnerSelected,
    required this.onToggleNewOwner,
    required this.onSearchQueryChanged,
  });

  final bool isNewOwner;
  final PlatformUserSummaryDto? selectedOwner;
  final TextEditingController lastNameController;
  final TextEditingController firstNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final List<PlatformUserSummaryDto> searchResults;
  final ValueChanged<PlatformUserSummaryDto?> onOwnerSelected;
  final ValueChanged<bool> onToggleNewOwner;
  final ValueChanged<String> onSearchQueryChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    if (selectedOwner != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VText(
            'Người dùng đã chọn',
            variant: VTextVariant.bodyDefault,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const VGap.sm(),
          VCard(
            tone: VComponentTone.success,
            backgroundColor: colors.success.withValues(alpha: 0.05),
            child: Row(
              children: [
                VIconBox(
                  icon: VIcons.person,
                  size: 40,
                  backgroundColor: colors.successBg,
                  iconColor: colors.success,
                  isCircular: true,
                ),
                const VGap.horizontalMd(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VText(
                        selectedOwner!.fullName,
                        variant: VTextVariant.bodyDefault,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const VGap.xs(),
                      VText(
                        selectedOwner!.email,
                        variant: VTextVariant.bodySmall,
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const VGap.md(),
          VButton(
            label: 'Chọn người dùng khác',
            variant: VButtonVariant.outline,
            onPressed: () => onOwnerSelected(null),
          ),
        ],
      );
    }

    if (isNewOwner) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              VText(
                'Tạo chủ sở hữu mới',
                variant: VTextVariant.headingH4,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () => onToggleNewOwner(false),
                child: const VText(
                  'Chọn người dùng cũ',
                  variant: VTextVariant.bodySmall,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const VGap.sm(),
          VTextFormField(
            controller: lastNameController,
            label: 'Họ và tên đệm*',
            hintText: 'Nhập họ và tên đệm',
          ),
          const VGap.sm(),
          VTextFormField(
            controller: firstNameController,
            label: 'Tên*',
            hintText: 'Nhập tên',
          ),
          const VGap.sm(),
          VTextFormField(
            controller: emailController,
            label: 'Email*',
            hintText: 'Nhập email',
            keyboardType: TextInputType.emailAddress,
          ),
          const VGap.sm(),
          VTextFormField(
            controller: phoneController,
            label: 'Số điện thoại',
            hintText: 'Nhập số điện thoại (Không bắt buộc)',
            keyboardType: TextInputType.phone,
          ),
          const VGap.md(),
          VCard(
            backgroundColor: colors.surfaceAlt,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  'Quy ước tài khoản',
                  variant: VTextVariant.bodyDefault,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const VGap.sm(),
                _buildConventionRow('Mật khẩu', 'Người dùng tự thiết lập qua link kích hoạt', colors),
                const VGap.xs(),
                _buildConventionRow('Tư cách', 'Chủ sở hữu (Mặc định)', colors),
                const VGap.xs(),
                _buildConventionRow('Vai trò mặc định', 'Chủ cửa hàng', colors),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            VText(
              'Chọn chủ sở hữu',
              variant: VTextVariant.headingH4,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () => onToggleNewOwner(true),
              child: const VText(
                'Tạo chủ sở hữu mới',
                variant: VTextVariant.bodySmall,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const VGap.sm(),
        VSearchBar(
          hintText: 'Tìm tên hoặc email',
          onChanged: onSearchQueryChanged,
        ),
        const VGap.md(),
        VText(
          'Kết quả tìm kiếm',
          variant: VTextVariant.bodySmall,
          color: colors.textSecondary,
        ),
        const VGap.sm(),
        if (searchResults.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: VSpacing.space4),
            child: Center(
              child: VText(
                'Không tìm thấy người dùng phù hợp.',
                color: colors.textMuted,
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: searchResults.length,
            separatorBuilder: (context, index) => const VGap.sm(),
            itemBuilder: (context, index) {
              final user = searchResults[index];
              return VCard(
                onTap: () => onOwnerSelected(user),
                child: Row(
                  children: [
                    VIconBox(
                      icon: VIcons.person,
                      size: 36,
                      backgroundColor: colors.surfaceAlt,
                      iconColor: colors.textSecondary,
                      isCircular: true,
                    ),
                    const VGap.horizontalMd(),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          VText(
                            user.fullName,
                            variant: VTextVariant.bodyDefault,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const VGap.xs(),
                          VText(
                            user.email,
                            variant: VTextVariant.bodySmall,
                            color: colors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    VIcon(
                      icon: VIcons.chevronRight,
                      color: colors.textMuted,
                      size: 20,
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildConventionRow(String label, String value, VColorScheme colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: VText(
            label,
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
          ),
        ),
        Expanded(
          child: VText(
            value,
            variant: VTextVariant.bodySmall,
            color: colors.textPrimary,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
