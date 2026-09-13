import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../organization_profile/data/vn_administrative_units_loader.dart';

class PlatformOnboardingStepOrganization extends StatelessWidget {
  const PlatformOnboardingStepOrganization({
    super.key,
    required this.orgNameController,
    this.orgDisplayNameController,
    this.orgLegalNameController,
    this.orgTaxCodeController,
    this.orgRegisteredAddressController,
    required this.orgPhoneController,
    required this.orgEmailController,
    required this.orgAddressController,
    required this.selectedProvince,
    required this.selectedWard,
    this.selectedEntityType,
    required this.onProvinceChanged,
    required this.onWardChanged,
    required this.onOrgNameChanged,
    this.onOrgEmailChanged,
    this.onOrgPhoneChanged,
    this.onEntityTypeChanged,
    this.orgNameErrorText,
    this.orgEmailErrorText,
    this.orgPhoneErrorText,
    this.administrativeUnitsFuture,
  });

  final TextEditingController orgNameController;
  final TextEditingController? orgDisplayNameController;
  final TextEditingController? orgLegalNameController;
  final TextEditingController? orgTaxCodeController;
  final TextEditingController? orgRegisteredAddressController;
  final TextEditingController orgPhoneController;
  final TextEditingController orgEmailController;
  final TextEditingController orgAddressController;
  final String? selectedProvince;
  final String? selectedWard;
  final String? selectedEntityType;
  final ValueChanged<String?> onProvinceChanged;
  final ValueChanged<String?> onWardChanged;
  final ValueChanged<String> onOrgNameChanged;
  final ValueChanged<String>? onOrgEmailChanged;
  final ValueChanged<String>? onOrgPhoneChanged;
  final ValueChanged<String?>? onEntityTypeChanged;
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
        VField(
          invalid: orgNameErrorText != null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VFieldLabel('Tên tổ chức', isRequired: true),
              VTextField(
                controller: orgNameController,
                hintText: 'Nhập tên tổ chức (ví dụ: Thú y Minh Phát)',
                onChanged: onOrgNameChanged,
              ),
              if (orgNameErrorText != null)
                VFieldError(orgNameErrorText!)
              else
                const VFieldDescription('Tên hiển thị'),
            ],
          ),
        ),
        const VGap.md(),
        VField(
          invalid: orgPhoneErrorText != null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VFieldLabel('Số điện thoại'),
              VPhoneField(
                controller: orgPhoneController,
                hintText: 'Nhập số điện thoại liên hệ',
                validateOnChanged: false,
                onChanged: onOrgPhoneChanged,
              ),
              if (orgPhoneErrorText != null) VFieldError(orgPhoneErrorText!),
            ],
          ),
        ),
        const VGap.md(),
        VField(
          invalid: orgEmailErrorText != null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VFieldLabel('Email liên hệ'),
              VTextField(
                controller: orgEmailController,
                hintText: 'Nhập email liên hệ',
                keyboardType: TextInputType.emailAddress,
                onChanged: onOrgEmailChanged,
              ),
              if (orgEmailErrorText != null) VFieldError(orgEmailErrorText!),
            ],
          ),
        ),
        const VGap.md(),
        VField(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VFieldLabel('Địa chỉ liên hệ'),
              VTextField(
                controller: orgAddressController,
                hintText: 'Nhập địa chỉ (ví dụ: 125 Phạm Văn Thuận)',
              ),
            ],
          ),
        ),
        const VGap.md(),
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
                _SearchDropdownField(
                  label: 'Tỉnh / thành phố',
                  child: VCombobox<String>(
                    value: provinceValue,
                    enabled: !isLoading && !hasError && units.isNotEmpty,
                    displayTextForValue: (v) => v ?? '',
                    onChanged: onProvinceChanged,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VComboboxContent(
                          child: VComboboxList(
                            children: [
                              for (final unit in units)
                                VComboboxItem<String>(
                                  value: unit.fullName,
                                  searchText: unit.fullName,
                                  child: Text(unit.fullName),
                                ),
                            ],
                          ),
                        ),
                        VComboboxInput(
                          hintText: hasError
                              ? 'Không tải được tỉnh / thành phố'
                              : isLoading
                              ? 'Đang tải tỉnh / thành phố'
                              : 'Chọn tỉnh / thành phố',
                        ),
                      ],
                    ),
                  ),
                ),
                const VGap.md(),
                _SearchDropdownField(
                  label: 'Xã / phường',
                  child: VCombobox<String>(
                    value: wardValue,
                    enabled: !isLoading && !hasError && province != null,
                    displayTextForValue: (v) => v ?? '',
                    onChanged: onWardChanged,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VComboboxContent(
                          child: VComboboxList(
                            children: [
                              for (final ward in wards)
                                VComboboxItem<String>(
                                  value: ward.fullName,
                                  searchText: ward.fullName,
                                  child: Text(ward.fullName),
                                ),
                            ],
                          ),
                        ),
                        VComboboxInput(
                          hintText: province == null
                              ? 'Chọn tỉnh / thành phố trước'
                              : 'Chọn xã / phường',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const VGap.md(),
        _SearchDropdownField(
          label: 'Loại chủ thể',
          child: VCombobox<String>(
            value: selectedEntityType,
            displayTextForValue: (v) => switch (v) {
              'HOUSEHOLD_BUSINESS' => 'Hộ kinh doanh',
              'ENTERPRISE' => 'Doanh nghiệp',
              'VETERINARY_CLINIC' => 'Phòng khám thú y',
              _ => '',
            },
            onChanged: onEntityTypeChanged,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                VComboboxContent(
                  child: VComboboxList(
                    children: const [
                      VComboboxItem<String>(
                        value: 'HOUSEHOLD_BUSINESS',
                        searchText: 'Hộ kinh doanh',
                        child: Text('Hộ kinh doanh'),
                      ),
                      VComboboxItem<String>(
                        value: 'ENTERPRISE',
                        searchText: 'Doanh nghiệp',
                        child: Text('Doanh nghiệp'),
                      ),
                      VComboboxItem<String>(
                        value: 'VETERINARY_CLINIC',
                        searchText: 'Phòng khám thú y',
                        child: Text('Phòng khám thú y'),
                      ),
                    ],
                  ),
                ),
                const VComboboxInput(hintText: 'Chọn loại chủ thể'),
              ],
            ),
          ),
        ),
        VField(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VFieldLabel('Tên pháp lý'),
              VTextField(
                controller: orgLegalNameController,
                hintText: 'Nhập tên pháp lý của tổ chức',
              ),
            ],
          ),
        ),
        const VGap.md(),
        VField(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VFieldLabel('Mã số thuế'),
              VTextField(
                controller: orgTaxCodeController,
                hintText: 'Nhập mã số thuế',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        const VGap.md(),
        VField(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VFieldLabel('Địa chỉ đăng ký'),
              VTextField(
                controller: orgRegisteredAddressController,
                hintText: 'Nhập địa chỉ đăng ký',
              ),
            ],
          ),
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

class _SearchDropdownField extends StatelessWidget {
  const _SearchDropdownField({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VText(
          label,
          variant: VTextVariant.bodySmall,
          color: context.vColors.textPrimary,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const VGap.sm(),
        child,
      ],
    );
  }
}
