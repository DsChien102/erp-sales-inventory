import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class PlatformOnboardingStepOrganization extends StatelessWidget {
  const PlatformOnboardingStepOrganization({
    super.key,
    required this.orgNameController,
    required this.orgDisplayNameController,
    this.orgLegalNameController,
    this.orgTaxCodeController,
    required this.orgPhoneController,
    required this.orgEmailController,
    required this.orgAddressController,
    required this.selectedProvince,
    required this.selectedWard,
    required this.onProvinceChanged,
    required this.onWardChanged,
    required this.onOrgNameChanged,
    this.onOrgEmailChanged,
    this.onOrgPhoneChanged,
    this.orgNameErrorText,
    this.orgEmailErrorText,
    this.orgPhoneErrorText,
  });

  final TextEditingController orgNameController;
  final TextEditingController orgDisplayNameController;
  final TextEditingController? orgLegalNameController;
  final TextEditingController? orgTaxCodeController;
  final TextEditingController orgPhoneController;
  final TextEditingController orgEmailController;
  final TextEditingController orgAddressController;
  final String? selectedProvince;
  final String? selectedWard;
  final ValueChanged<String?> onProvinceChanged;
  final ValueChanged<String?> onWardChanged;
  final ValueChanged<String> onOrgNameChanged;
  final ValueChanged<String>? onOrgEmailChanged;
  final ValueChanged<String>? onOrgPhoneChanged;
  final String? orgNameErrorText;
  final String? orgEmailErrorText;
  final String? orgPhoneErrorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VText(
          'Chỉ tên tổ chức là bắt buộc.',
          variant: VTextVariant.bodySmall,
          color: colors.textSecondary,
        ),
        const VGap.md(),
        VTextField(
          controller: orgNameController,
          label: 'Tên tổ chức',
          isRequired: true,
          hintText: 'Nhập tên tổ chức (ví dụ: Thú y Minh Phát)',
          errorText: orgNameErrorText,
          onChanged: onOrgNameChanged,
        ),
        const VGap.sm(),
        VTextField(
          controller: orgDisplayNameController,
          label: 'Tên hiển thị',
          hintText: 'Nhập tên hiển thị trên ứng dụng',
        ),
        const VGap.sm(),
        VTextField(
          controller: orgLegalNameController,
          label: 'Tên pháp lý',
          hintText: 'Nhập tên pháp lý của tổ chức',
        ),
        const VGap.sm(),
        VTextField(
          controller: orgTaxCodeController,
          label: 'Mã số thuế',
          hintText: 'Nhập mã số thuế',
        ),
        const VGap.sm(),
        VTextField(
          controller: orgPhoneController,
          label: 'Số điện thoại',
          hintText: 'Nhập số điện thoại liên hệ',
          keyboardType: TextInputType.phone,
          errorText: orgPhoneErrorText,
          onChanged: onOrgPhoneChanged,
        ),
        const VGap.sm(),
        VTextField(
          controller: orgEmailController,
          label: 'Email liên hệ',
          hintText: 'Nhập email liên hệ',
          keyboardType: TextInputType.emailAddress,
          errorText: orgEmailErrorText,
          onChanged: onOrgEmailChanged,
        ),
        const VGap.sm(),
        VTextField(
          controller: orgAddressController,
          label: 'Địa chỉ liên hệ',
          hintText: 'Nhập địa chỉ (ví dụ: 125 Phạm Văn Thuận)',
        ),
        const VGap.sm(),
        VDropdown<String>(
          label: 'Tỉnh / thành phố',
          value: selectedProvince,
          hintText: 'Chọn tỉnh / thành phố',
          items: const [
            DropdownMenuItem(value: 'Đồng Nai', child: VText('Đồng Nai')),
            DropdownMenuItem(value: 'TP. Hồ Chí Minh', child: VText('TP. Hồ Chí Minh')),
            DropdownMenuItem(value: 'Hà Nội', child: VText('Hà Nội')),
          ],
          onChanged: onProvinceChanged,
        ),
        const VGap.sm(),
        VDropdown<String>(
          label: 'Xã / phường',
          value: selectedWard,
          hintText: 'Chọn xã / phường',
          items: const [
            DropdownMenuItem(value: 'Trấn Biên', child: VText('Trấn Biên')),
            DropdownMenuItem(value: 'Phường 1', child: VText('Phường 1')),
            DropdownMenuItem(value: 'Phường 2', child: VText('Phường 2')),
          ],
          onChanged: onWardChanged,
        ),
      ],
    );
  }
}
