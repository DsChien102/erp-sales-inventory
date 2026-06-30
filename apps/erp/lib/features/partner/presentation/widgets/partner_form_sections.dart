import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class PartnerContactInfoSection extends StatelessWidget {
  final String phone;
  final ValueChanged<String> onPhoneChanged;
  final String email;
  final ValueChanged<String> onEmailChanged;
  final String address;
  final ValueChanged<String> onAddressChanged;

  const PartnerContactInfoSection({
    super.key,
    required this.phone,
    required this.onPhoneChanged,
    required this.email,
    required this.onEmailChanged,
    required this.address,
    required this.onAddressChanged,
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
          label: 'Số điện thoại',
          isRequired: true,
          hintText: 'VD: 0912345678',
          prefixIcon: const Icon(Icons.phone_outlined, size: 20),
          keyboardType: TextInputType.phone,
          onChanged: onPhoneChanged,
        ),
        const SizedBox(height: VSpacing.space4),
        VTextField(
          label: 'Email',
          hintText: 'VD: an@example.com',
          prefixIcon: const Icon(Icons.email_outlined, size: 20),
          keyboardType: TextInputType.emailAddress,
          onChanged: onEmailChanged,
        ),
        const SizedBox(height: VSpacing.space4),
        VTextField(
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
  final ValueChanged<String> onTaxIdChanged;

  const PartnerTaxInfoSection({
    super.key,
    required this.taxId,
    required this.onTaxIdChanged,
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
          label: 'Mã số thuế',
          hintText: 'Nhập mã số thuế nếu có',
          prefixIcon: const Icon(Icons.receipt_long_outlined, size: 20),
          onChanged: onTaxIdChanged,
        ),
      ],
    );
  }
}

class PartnerNoteSection extends StatelessWidget {
  final String note;
  final ValueChanged<String> onNoteChanged;

  const PartnerNoteSection({
    super.key,
    required this.note,
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
