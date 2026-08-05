import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../organization_profile/data/vn_administrative_units_loader.dart';

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
    this.administrativeUnitsFuture,
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
  final Future<List<VnAdministrativeUnit>>? administrativeUnitsFuture;

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
        FutureBuilder<List<VnAdministrativeUnit>>(
          future: administrativeUnitsFuture ?? VnAdministrativeUnitsLoader.load(),
          builder: (context, snapshot) {
            final units = snapshot.data ?? const <VnAdministrativeUnit>[];
            final isLoading = snapshot.connectionState != ConnectionState.done;
            final hasError = snapshot.hasError;
            final province = _findProvinceByName(units, selectedProvince);
            final provinceValue = province?.fullName;
            final wards = province?.wards ?? const <VnWard>[];
            final wardValue = _containsWardName(wards, selectedWard) ? selectedWard : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VDropdown<String>(
                  label: 'Tỉnh / thành phố',
                  value: provinceValue,
                  hintText: hasError
                      ? 'Không tải được tỉnh / thành phố'
                      : isLoading
                      ? 'Đang tải tỉnh / thành phố'
                      : 'Chọn tỉnh / thành phố',
                  enabled: !isLoading && !hasError && units.isNotEmpty,
                  items: units
                      .map(
                        (unit) => DropdownMenuItem(
                          value: unit.fullName,
                          child: VText(unit.fullName),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: onProvinceChanged,
                ),
                const VGap.sm(),
                VDropdown<String>(
                  label: 'Xã / phường',
                  value: wardValue,
                  hintText: province == null ? 'Chọn tỉnh / thành phố trước' : 'Chọn xã / phường',
                  enabled: !isLoading && !hasError && province != null,
                  items: wards
                      .map(
                        (ward) => DropdownMenuItem(
                          value: ward.fullName,
                          child: VText(ward.fullName),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: onWardChanged,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  VnAdministrativeUnit? _findProvinceByName(
    List<VnAdministrativeUnit> units,
    String? fullName,
  ) {
    if (fullName == null) return null;
    for (final unit in units) {
      if (unit.fullName == fullName) return unit;
    }
    return null;
  }

  bool _containsWardName(List<VnWard> wards, String? fullName) {
    if (fullName == null) return false;
    for (final ward in wards) {
      if (ward.fullName == fullName) return true;
    }
    return false;
  }
}
