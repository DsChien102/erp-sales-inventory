import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class PartnerContactInfoSection extends StatelessWidget {
  final String phone;
  final TextEditingController? phoneController;
  final ValueChanged<String> onPhoneChanged;
  final String email;
  final TextEditingController? emailController;
  final ValueChanged<String> onEmailChanged;
  final String address;
  final TextEditingController? addressController;
  final ValueChanged<String> onAddressChanged;
  final bool showValidationErrors;

  const PartnerContactInfoSection({
    super.key,
    required this.phone,
    this.phoneController,
    required this.onPhoneChanged,
    required this.email,
    this.emailController,
    required this.onEmailChanged,
    required this.address,
    this.addressController,
    required this.onAddressChanged,
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
            'THÔNG TIN LIÊN HỆ',
            style: VTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: dynamicColors.textSecondary,
            ),
          ),
        ),
        VTextField(
          controller: phoneController,
          label: 'Số điện thoại',
          isRequired: true,
          hintText: 'VD: 0912345678',
          prefixIcon: const Icon(Icons.phone_outlined, size: 20),
          keyboardType: TextInputType.phone,
          onChanged: onPhoneChanged,
          errorText: showValidationErrors && phone.trim().isEmpty
              ? 'Vui lòng nhập số điện thoại'
              : null,
        ),
        const SizedBox(height: VSpacing.space4),
        VTextField(
          controller: emailController,
          label: 'Email',
          hintText: 'VD: an@example.com',
          prefixIcon: const Icon(Icons.email_outlined, size: 20),
          keyboardType: TextInputType.emailAddress,
          onChanged: onEmailChanged,
        ),
        const SizedBox(height: VSpacing.space4),
        VTextField(
          controller: addressController,
          label: 'Địa chỉ',
          hintText: 'Nhập địa chỉ liên hệ',
          prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
          onChanged: onAddressChanged,
        ),
      ],
    );
  }
}

class PartnerTaxInfoSection extends StatelessWidget {
  final String taxId;
  final TextEditingController? taxIdController;
  final ValueChanged<String> onTaxIdChanged;
  final String profileType;
  final bool showValidationErrors;

  const PartnerTaxInfoSection({
    super.key,
    required this.taxId,
    this.taxIdController,
    required this.onTaxIdChanged,
    required this.profileType,
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
            'THÔNG TIN THUẾ',
            style: VTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: dynamicColors.textSecondary,
            ),
          ),
        ),
        VTextField(
          controller: taxIdController,
          label: 'Mã số thuế',
          hintText: 'Nhập mã số thuế nếu có',
          prefixIcon: const Icon(Icons.receipt_long_outlined, size: 20),
          onChanged: onTaxIdChanged,
        ),
        if (showValidationErrors && profileType != 'individual' && taxId.trim().isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: VSpacing.space2),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.space3,
                vertical: VSpacing.space2,
              ),
              decoration: BoxDecoration(
                color: VColors.warningBg,
                borderRadius: BorderRadius.circular(VRadius.card),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: VColors.warning,
                    size: 16,
                  ),
                  const SizedBox(width: VSpacing.space2),
                  Expanded(
                    child: Text(
                      'Tổ chức chưa có mã số thuế. Bạn vẫn có thể lưu và bổ sung sau.',
                      style: VTypography.bodySmall.copyWith(
                        color: VColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class PartnerBillingInfoSection extends StatelessWidget {
  final TextEditingController? billingNameController;
  final TextEditingController? billingAddressController;
  final TextEditingController? billingEmailController;
  final ValueChanged<String> onBillingNameChanged;
  final ValueChanged<String> onBillingAddressChanged;
  final ValueChanged<String> onBillingEmailChanged;

  const PartnerBillingInfoSection({
    super.key,
    this.billingNameController,
    this.billingAddressController,
    this.billingEmailController,
    required this.onBillingNameChanged,
    required this.onBillingAddressChanged,
    required this.onBillingEmailChanged,
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
            'THÔNG TIN HÓA ĐƠN',
            style: VTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: dynamicColors.textSecondary,
            ),
          ),
        ),
        VTextField(
          controller: billingNameController,
          label: 'Tên trên hóa đơn',
          hintText: 'Nhập tên hiển thị trên hóa đơn',
          prefixIcon: const Icon(Icons.badge_outlined, size: 20),
          onChanged: onBillingNameChanged,
        ),
        const SizedBox(height: VSpacing.space4),
        VTextField(
          controller: billingAddressController,
          label: 'Địa chỉ trên hóa đơn',
          hintText: 'Nhập địa chỉ xuất hóa đơn',
          prefixIcon: const Icon(Icons.location_city_outlined, size: 20),
          onChanged: onBillingAddressChanged,
        ),
        const SizedBox(height: VSpacing.space4),
        VTextField(
          controller: billingEmailController,
          label: 'Email nhận hóa đơn',
          hintText: 'VD: invoice@example.com',
          prefixIcon: const Icon(Icons.mark_email_read_outlined, size: 20),
          keyboardType: TextInputType.emailAddress,
          onChanged: onBillingEmailChanged,
        ),
      ],
    );
  }
}

class PartnerNoteSection extends StatelessWidget {
  final String note;
  final TextEditingController? noteController;
  final ValueChanged<String> onNoteChanged;

  const PartnerNoteSection({
    super.key,
    required this.note,
    this.noteController,
    required this.onNoteChanged,
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
            'GHI CHÚ',
            style: VTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: dynamicColors.textSecondary,
            ),
          ),
        ),
        VTextField(
          controller: noteController,
          hintText: 'Ghi chú nội bộ về KH & NCC (chỉ hiển thị trong hệ thống)',
          prefixIcon: const Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 14),
                child: Icon(Icons.sticky_note_2_outlined, size: 20),
              ),
            ],
          ),
          minLines: 3,
          maxLines: 5,
          onChanged: onNoteChanged,
        ),
      ],
    );
  }
}
