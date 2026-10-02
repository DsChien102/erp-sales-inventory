import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../organization_profile/data/vn_administrative_units_loader.dart';
import '../organization_profile/widgets/vn_administrative_unit_picker_sheet.dart';

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

            final canSelectWard = !isLoading && !hasError && province != null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SearchDropdownField(
                  label: 'Tỉnh / thành phố',
                  child: Semantics(
                    button: true,
                    enabled: !isLoading && !hasError && units.isNotEmpty,
                    child: InkWell(
                      key: const Key('field_select_province'),
                      onTap: (!isLoading && !hasError && units.isNotEmpty)
                          ? () async {
                              final result = await showVnAdministrativeUnitPickerSheet(
                                context: context,
                                units: units,
                                initialProvinceCode: province?.code,
                                initialCommuneCode: _findWardByName(wards, selectedWard)?.code,
                                initialTab: 0,
                              );
                              if (result != null) {
                                onProvinceChanged(result.province.fullName);
                                onWardChanged(result.ward?.fullName);
                              }
                            }
                          : null,
                      borderRadius: BorderRadius.circular(VRadius.input),
                      child: Container(
                        height: VCombobox.controlHeight,
                        padding: const EdgeInsets.symmetric(horizontal: VSpacing.space3),
                        decoration: BoxDecoration(
                          color: (!isLoading && !hasError && units.isNotEmpty)
                              ? context.vColors.surface
                              : context.vColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(VRadius.input),
                          border: Border.all(
                            color: (!isLoading && !hasError && units.isNotEmpty)
                                ? context.vColors.borderDefault
                                : context.vColors.borderDefault.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: (!isLoading && !hasError && units.isNotEmpty)
                                  ? context.vColors.textSecondary
                                  : context.vColors.textMuted,
                            ),
                            const SizedBox(width: VSpacing.space2),
                            Expanded(
                              child: Text(
                                provinceValue ??
                                    (hasError
                                        ? 'Không tải được tỉnh / thành phố'
                                        : isLoading
                                            ? 'Đang tải tỉnh / thành phố'
                                            : 'Chọn tỉnh / thành phố'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: VTypography.bodyDefault.copyWith(
                                  color: (provinceValue != null)
                                      ? context.vColors.textPrimary
                                      : context.vColors.textSecondary,
                                ),
                              ),
                            ),
                            if (provinceValue != null) ...[
                              GestureDetector(
                                key: const Key('field_select_province_clear'),
                                onTap: () {
                                  onProvinceChanged(null);
                                  onWardChanged(null);
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.all(VSpacing.space1),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: context.vColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: VSpacing.space1),
                            ],
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: context.vColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const VGap.md(),
                _SearchDropdownField(
                  label: 'Xã / phường',
                  child: Semantics(
                    button: true,
                    enabled: canSelectWard,
                    child: InkWell(
                      key: const Key('field_select_ward'),
                      onTap: canSelectWard
                          ? () async {
                              final result = await showVnAdministrativeUnitPickerSheet(
                                context: context,
                                units: units,
                                initialProvinceCode: province.code,
                                initialCommuneCode: _findWardByName(wards, selectedWard)?.code,
                                initialTab: 1,
                              );
                              if (result != null) {
                                onProvinceChanged(result.province.fullName);
                                onWardChanged(result.ward?.fullName);
                              }
                            }
                          : null,
                      borderRadius: BorderRadius.circular(VRadius.input),
                      child: Container(
                        height: VCombobox.controlHeight,
                        padding: const EdgeInsets.symmetric(horizontal: VSpacing.space3),
                        decoration: BoxDecoration(
                          color: canSelectWard
                              ? context.vColors.surface
                              : context.vColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(VRadius.input),
                          border: Border.all(
                            color: canSelectWard
                                ? context.vColors.borderDefault
                                : context.vColors.borderDefault.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.apartment_outlined,
                              size: 18,
                              color: canSelectWard
                                  ? context.vColors.textSecondary
                                  : context.vColors.textMuted,
                            ),
                            const SizedBox(width: VSpacing.space2),
                            Expanded(
                              child: Text(
                                wardValue ??
                                    (province == null
                                        ? 'Chọn tỉnh / thành phố trước'
                                        : 'Chọn xã / phường'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: VTypography.bodyDefault.copyWith(
                                  color: (wardValue != null)
                                      ? context.vColors.textPrimary
                                      : context.vColors.textSecondary,
                                ),
                              ),
                            ),
                            if (wardValue != null) ...[
                              GestureDetector(
                                key: const Key('field_select_ward_clear'),
                                onTap: () => onWardChanged(null),
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.all(VSpacing.space1),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: context.vColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: VSpacing.space1),
                            ],
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: canSelectWard
                                  ? context.vColors.textSecondary
                                  : context.vColors.textMuted,
                            ),
                          ],
                        ),
                      ),
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

  static VnWard? _findWardByName(List<VnWard> wards, String? name) {
    if (name == null) return null;
    for (final ward in wards) {
      if (ward.fullName == name) return ward;
    }
    return null;
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
