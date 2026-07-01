import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class PartnerRoleTypeSection extends StatelessWidget {
  final String role;
  final ValueChanged<String> onRoleChanged;
  final String profileType;
  final ValueChanged<String> onProfileTypeChanged;
  final TextEditingController? nameController;
  final ValueChanged<String> onNameChanged;
  final String name;
  final String contactName;
  final ValueChanged<String> onContactNameChanged;
  final bool showValidationErrors;

  const PartnerRoleTypeSection({
    super.key,
    required this.role,
    required this.onRoleChanged,
    required this.profileType,
    required this.onProfileTypeChanged,
    this.nameController,
    required this.onNameChanged,
    required this.name,
    required this.contactName,
    required this.onContactNameChanged,
    required this.showValidationErrors,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: VSpacing.space2),
          child: Text(
            'THÔNG TIN CƠ BẢN',
            style: VTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: dynamicColors.textSecondary,
            ),
          ),
        ),

        // Vai trò
        RichText(
          text: TextSpan(
            style: VTypography.bodyDefault.copyWith(
              color: dynamicColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            children: const [
              TextSpan(text: 'Vai trò '),
              TextSpan(
                text: '*',
                style: TextStyle(color: VColors.danger),
              ),
            ],
          ),
        ),
        const SizedBox(height: VSpacing.space2),
        _buildRoleItem(context, 'customer', 'Khách hàng', Icons.person_outline),
        const SizedBox(height: VSpacing.space2),
        _buildRoleItem(context, 'supplier', 'Nhà cung cấp', Icons.storefront_outlined),
        const SizedBox(height: VSpacing.space2),
        _buildRoleItem(context, 'both', 'KH & NCC', Icons.people_outline),

        const SizedBox(height: VSpacing.space4),

        // Loại hồ sơ
        RichText(
          text: TextSpan(
            style: VTypography.bodyDefault.copyWith(
              color: dynamicColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            children: const [
              TextSpan(text: 'Loại hồ sơ '),
              TextSpan(
                text: '*',
                style: TextStyle(color: VColors.danger),
              ),
            ],
          ),
        ),
        const SizedBox(height: VSpacing.space2),
        Row(
          children: [
            Expanded(
              child: _buildProfileTypeItem(context, 'individual', 'Cá nhân'),
            ),
            const SizedBox(width: VSpacing.space2),
            Expanded(
              child: _buildProfileTypeItem(context, 'company', 'Công ty'),
            ),
            const SizedBox(width: VSpacing.space2),
            Expanded(
              child: _buildProfileTypeItem(context, 'household', 'HKD'),
            ),
          ],
        ),

        const SizedBox(height: VSpacing.space4),
        if (profileType == 'individual')
          VTextField(
            controller: nameController,
            label: 'Họ và tên',
            isRequired: true,
            hintText: 'VD: Nguyễn Văn An',
            onChanged: onNameChanged,
            errorText: showValidationErrors && name.trim().isEmpty
                ? 'Vui lòng nhập họ và tên'
                : null,
          )
        else ...[
          VTextField(
            controller: nameController,
            label: 'Tên',
            isRequired: true,
            hintText: 'VD: Công ty TNHH Thú y An Bình',
            onChanged: onNameChanged,
            errorText: showValidationErrors && name.trim().isEmpty
                ? 'Vui lòng nhập tên tổ chức'
                : null,
          ),
          const SizedBox(height: VSpacing.space4),
          VTextField(
            // TODO: Pass contactNameController when supported
            label: 'Người liên hệ',
            hintText: 'VD: Anh Minh',
            prefixIcon: const Icon(Icons.person_outline, size: 20),
            onChanged: onContactNameChanged,
          ),
        ],
      ],
    );
  }

  Widget _buildRoleItem(BuildContext context, String value, String label, IconData icon) {
    final isSelected = role == value;
    final dynamicColors = context.vColors;

    return InkWell(
      onTap: () => onRoleChanged(value),
      borderRadius: BorderRadius.circular(VRadius.card),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4, vertical: VSpacing.space3),
        decoration: BoxDecoration(
          color: isSelected ? VColors.successBg : dynamicColors.surface,
          borderRadius: BorderRadius.circular(VRadius.card),
          border: Border.all(
            color: isSelected ? VColors.success : dynamicColors.borderDefault,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? VColors.success : dynamicColors.textSecondary,
            ),
            const SizedBox(width: VSpacing.space3),
            Expanded(
              child: Text(
                label,
                style: VTypography.bodyDefault.copyWith(
                  color: isSelected ? VColors.success : dynamicColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check,
                size: 20,
                color: VColors.success,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTypeItem(BuildContext context, String value, String label) {
    final isSelected = profileType == value;
    final dynamicColors = context.vColors;

    return InkWell(
      onTap: () => onProfileTypeChanged(value),
      borderRadius: BorderRadius.circular(VRadius.card),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: VSpacing.space3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? VColors.successBg : dynamicColors.surface,
          borderRadius: BorderRadius.circular(VRadius.card),
          border: Border.all(
            color: isSelected ? VColors.success : dynamicColors.borderDefault,
          ),
        ),
        child: Text(
          label,
          style: VTypography.bodyDefault.copyWith(
            color: isSelected ? VColors.success : dynamicColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
