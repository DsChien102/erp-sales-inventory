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
    this.orgLegalName = '',
    this.orgTaxCode = '',
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
  final String orgLegalName;
  final String orgTaxCode;
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
        // Owner Summary Card (Matching design image 2)
        VCard(
          tone: VComponentTone.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VText(
                ownerName,
                variant: VTextVariant.bodyDefault,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const VGap.xs(),
              VText(
                email,
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
              ),
              const VGap.xs(),
              if (phone.isNotEmpty)
                VText(
                  phone,
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
            ],
          ),
        ),
        const VGap.md(),

        // Organization Info Card
        VCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VText(
                'Thông tin tổ chức',
                variant: VTextVariant.bodyDefault,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const VGap.md(),
              _buildReviewRow('Tên tổ chức', orgName.isEmpty ? 'Chưa khai báo' : orgName, colors),
              const VGap.sm(),
              _buildReviewRow('Điện thoại', orgPhone.isEmpty ? 'Chưa khai báo' : orgPhone, colors),
              const VGap.sm(),
              _buildReviewRow('Email', orgEmail.isEmpty ? 'Chưa khai báo' : orgEmail, colors),
              const VGap.sm(),
              _buildReviewRow(
                'Địa chỉ',
                orgAddress.isEmpty
                    ? 'Chưa khai báo'
                    : '$orgAddress${selectedWard != null ? ', $selectedWard' : ''}${selectedProvince != null ? ', $selectedProvince' : ''}',
                colors,
              ),
            ],
          ),
        ),
        const VGap.md(),

        // Legal Info Card
        VCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VText(
                'Thông tin pháp lý',
                variant: VTextVariant.bodyDefault,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const VGap.md(),
              _buildReviewRow('Loại chủ thể', 'Chưa khai báo', colors),
              const VGap.sm(),
              _buildReviewRow(
                'Tên pháp lý',
                orgLegalName.isEmpty ? 'Chưa khai báo' : orgLegalName,
                colors,
              ),
              const VGap.sm(),
              _buildReviewRow(
                'Mã số thuế',
                orgTaxCode.isEmpty ? 'Chưa khai báo' : orgTaxCode,
                colors,
              ),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        VText(
          label,
          variant: VTextVariant.bodySmall,
          color: colors.textSecondary,
        ),
        VText(
          value,
          variant: VTextVariant.bodySmall,
          color: colors.textPrimary,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
