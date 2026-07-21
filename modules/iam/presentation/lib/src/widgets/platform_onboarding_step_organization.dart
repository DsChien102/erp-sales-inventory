import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class PlatformOnboardingStepOrganization extends StatelessWidget {
  const PlatformOnboardingStepOrganization({
    super.key,
    required this.orgNameController,
    required this.orgDisplayNameController,
    required this.orgPhoneController,
    required this.orgEmailController,
    required this.orgAddressController,
    required this.selectedProvince,
    required this.selectedWard,
    required this.onProvinceChanged,
    required this.onWardChanged,
    required this.onOrgNameChanged,
  });

  final TextEditingController orgNameController;
  final TextEditingController orgDisplayNameController;
  final TextEditingController orgPhoneController;
  final TextEditingController orgEmailController;
  final TextEditingController orgAddressController;
  final String? selectedProvince;
  final String? selectedWard;
  final ValueChanged<String?> onProvinceChanged;
  final ValueChanged<String?> onWardChanged;
  final ValueChanged<String> onOrgNameChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VText(
          'Thông tin tổ chức',
          variant: VTextVariant.headingH4,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const VGap.xs(),
        VText(
          'Chi tên tổ chức là bắt buộc.',
          variant: VTextVariant.bodySmall,
          color: colors.textSecondary,
        ),
        const VGap.md(),
        VTextFormField(
          controller: orgNameController,
          label: 'Tên tổ chức*',
          hintText: 'Nhập tên tổ chức (ví dụ: Thú y Minh Phát)',
          onChanged: onOrgNameChanged,
        ),
        const VGap.sm(),
        VTextFormField(
          controller: orgDisplayNameController,
          label: 'Tên hiển thị',
          hintText: 'Nhập tên hiển thị trên ứng dụng',
        ),
        const VGap.sm(),
        VTextFormField(
          controller: orgPhoneController,
          label: 'Số điện thoại',
          hintText: 'Nhập số điện thoại liên hệ',
          keyboardType: TextInputType.phone,
        ),
        const VGap.sm(),
        VTextFormField(
          controller: orgEmailController,
          label: 'Email liên hệ',
          hintText: 'Nhập email liên hệ',
          keyboardType: TextInputType.emailAddress,
        ),
        const VGap.sm(),
        VTextFormField(
          controller: orgAddressController,
          label: 'Địa chỉ liên hệ',
          hintText: 'Nhập địa chỉ (ví dụ: 125 Phạm Văn Thuận)',
        ),
        const VGap.sm(),
        DropdownButtonFormField<String>(
          value: selectedProvince,
          decoration: const InputDecoration(
            labelText: 'Tỉnh / thành phố',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Đồng Nai', child: Text('Đồng Nai')),
            DropdownMenuItem(value: 'TP. Hồ Chí Minh', child: Text('TP. Hồ Chí Minh')),
            DropdownMenuItem(value: 'Hà Nội', child: Text('Hà Nội')),
          ],
          onChanged: onProvinceChanged,
        ),
        const VGap.sm(),
        DropdownButtonFormField<String>(
          value: selectedWard,
          decoration: const InputDecoration(
            labelText: 'Xã / phường',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Trấn Biên', child: Text('Trấn Biên')),
            DropdownMenuItem(value: 'Phường 1', child: Text('Phường 1')),
            DropdownMenuItem(value: 'Phường 2', child: Text('Phường 2')),
          ],
          onChanged: onWardChanged,
        ),
      ],
    );
  }
}
