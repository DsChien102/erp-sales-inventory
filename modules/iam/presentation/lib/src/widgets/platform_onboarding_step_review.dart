import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class PlatformOnboardingStepReview extends StatelessWidget {
  const PlatformOnboardingStepReview({
    super.key,
    required this.isNewOwner,
    required this.lastName,
    required this.firstName,
    required this.email,
    required this.phone,
    required this.orgName,
    required this.orgPhone,
    required this.orgEmail,
    required this.orgAddress,
    required this.selectedProvince,
    required this.selectedWard,
  });

  final bool isNewOwner;
  final String lastName;
  final String firstName;
  final String email;
  final String phone;
  final String orgName;
  final String orgPhone;
  final String orgEmail;
  final String orgAddress;
  final String? selectedProvince;
  final String? selectedWard;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    final ownerName = isNewOwner
        ? '$lastName $firstName'.trim()
        : firstName; // For existing owner, firstName is full name

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VText(
          'Kiểm tra thông tin',
          variant: VTextVariant.headingH4,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const VGap.md(),

        // Owner Summary Card
        VText(
          'Chủ sở hữu',
          variant: VTextVariant.bodyDefault,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const VGap.sm(),
        VCard(
          child: Row(
            children: [
              VIconBox(
                icon: VIcons.person,
                size: 40,
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
                      ownerName,
                      variant: VTextVariant.bodyDefault,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const VGap.xs(),
                    VText(
                      email,
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                    if (phone.isNotEmpty) ...[
                      const VGap.xs(),
                      VText(
                        phone,
                        variant: VTextVariant.bodySmall,
                        color: colors.textSecondary,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const VGap.md(),

        // Organization Info Card
        VText(
          'Thông tin tổ chức',
          variant: VTextVariant.bodyDefault,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const VGap.sm(),
        VCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReviewRow('Tên tổ chức', orgName, colors),
              const VGap.sm(),
              _buildReviewRow('Điện thoại', orgPhone.isEmpty ? 'Chưa khai báo' : orgPhone, colors),
              const VGap.sm(),
              _buildReviewRow('Email', orgEmail.isEmpty ? 'Chưa khai báo' : orgEmail, colors),
              const VGap.sm(),
              _buildReviewRow('Địa chỉ', orgAddress.isEmpty ? 'Chưa khai báo' : '$orgAddress, $selectedWard, $selectedProvince', colors),
            ],
          ),
        ),
        const VGap.md(),

        // Legal Info Card (Placeholder)
        VText(
          'Thông tin pháp lý',
          variant: VTextVariant.bodyDefault,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const VGap.sm(),
        VCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReviewRow('Loại chủ thể', 'Chưa khai báo', colors),
              const VGap.sm(),
              _buildReviewRow('Tên pháp lý', 'Chưa khai báo', colors),
              const VGap.sm(),
              _buildReviewRow('Mã số thuế', 'Chưa khai báo', colors),
            ],
          ),
        ),
        const VGap.md(),

        VText(
          'Sau khi tạo, tổ chức ở trạng thái Đang thiết lập. Chủ sở hữu có vai trò vận hành mặc định là Chủ cửa hàng.',
          variant: VTextVariant.bodySmall,
          color: colors.textSecondary,
        ),
        const VGap.md(),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value, VColorScheme colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: VText(
            label,
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
          ),
        ),
        Expanded(
          child: VText(
            value,
            variant: VTextVariant.bodyDefault,
            color: colors.textPrimary,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
