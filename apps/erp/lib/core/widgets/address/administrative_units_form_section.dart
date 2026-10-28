import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'vn_administrative_unit_picker_sheet.dart';
import 'vn_administrative_units_loader.dart';

/// Form section containing province and ward selectors for VN administrative units.
class AdministrativeUnitsFormSection extends StatelessWidget {
  const AdministrativeUnitsFormSection({
    super.key,
    required this.unitsFuture,
    this.selectedProvinceCode,
    this.selectedCommuneCode,
    this.onProvinceChanged,
    this.onCommuneChanged,
    this.selectedProvinceName,
    this.selectedCommuneName,
    this.onProvinceNameChanged,
    this.onCommuneNameChanged,
    this.provinceFieldKey = const Key('field_select_province'),
    this.communeFieldKey = const Key('field_select_ward'),
    this.provinceClearKey = const Key('field_select_province_clear'),
    this.communeClearKey = const Key('field_select_ward_clear'),
    this.provinceKey,
    this.communeKey,
    this.provinceError,
    this.communeError,
    this.isRequired = false,
    this.provinceLabel = 'Tỉnh / thành phố',
    this.communeLabel = 'Xã / phường',
  });

  final Future<List<VnAdministrativeUnit>> unitsFuture;
  final String? selectedProvinceCode;
  final String? selectedCommuneCode;
  final ValueChanged<String?>? onProvinceChanged;
  final ValueChanged<String?>? onCommuneChanged;
  final String? selectedProvinceName;
  final String? selectedCommuneName;
  final ValueChanged<String?>? onProvinceNameChanged;
  final ValueChanged<String?>? onCommuneNameChanged;
  final Key provinceFieldKey;
  final Key communeFieldKey;
  final Key provinceClearKey;
  final Key communeClearKey;
  final Key? provinceKey;
  final Key? communeKey;
  final String? provinceError;
  final String? communeError;
  final bool isRequired;
  final String provinceLabel;
  final String communeLabel;

  static VnAdministrativeUnit? findProvince(
    List<VnAdministrativeUnit> units, {
    String? code,
    String? name,
  }) {
    if (code != null && code.isNotEmpty) {
      for (final unit in units) {
        if (unit.code == code) return unit;
      }
    }
    if (name != null && name.isNotEmpty) {
      for (final unit in units) {
        if (unit.fullName == name) return unit;
      }
    }
    return null;
  }

  static VnAdministrativeUnit? findProvinceByCode(
    List<VnAdministrativeUnit> units,
    String? code,
  ) => findProvince(units, code: code);

  static VnWard? findWard(
    List<VnWard> wards, {
    String? code,
    String? name,
  }) {
    if (code != null && code.isNotEmpty) {
      for (final ward in wards) {
        if (ward.code == code) return ward;
      }
    }
    if (name != null && name.isNotEmpty) {
      for (final ward in wards) {
        if (ward.fullName == name) return ward;
      }
    }
    return null;
  }

  Future<void> _openPicker({
    required BuildContext context,
    required List<VnAdministrativeUnit> units,
    required VnAdministrativeUnit? currentProvince,
    required VnWard? currentWard,
    required int initialTab,
  }) async {
    final result = await showVnAdministrativeUnitPickerSheet(
      context: context,
      units: units,
      initialProvinceCode: currentProvince?.code,
      initialCommuneCode: currentWard?.code,
      initialTab: initialTab,
    );

    if (result != null) {
      onProvinceChanged?.call(result.province.code);
      onProvinceNameChanged?.call(result.province.fullName);
      onCommuneChanged?.call(result.ward?.code);
      onCommuneNameChanged?.call(result.ward?.fullName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<VnAdministrativeUnit>>(
      future: unitsFuture,
      builder: (context, snapshot) {
        final units = snapshot.data ?? const [];
        final selectedProvince = findProvince(
          units,
          code: selectedProvinceCode,
          name: selectedProvinceName,
        );
        final wardList = selectedProvince?.wards ?? const <VnWard>[];
        final selectedWard = findWard(
          wardList,
          code: selectedCommuneCode,
          name: selectedCommuneName,
        );

        final canSelectWard = selectedProvince != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KeyedSubtree(
              key: provinceKey,
              child: VField(
                invalid: provinceError != null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SearchDropdownField(
                      label: provinceLabel,
                      isRequired: isRequired,
                      child: _AdministrativeUnitTouchField(
                        fieldKey: provinceFieldKey,
                        clearKey: provinceClearKey,
                        value: selectedProvince?.fullName,
                        hintText: 'Chọn tỉnh / thành phố',
                        prefixIcon: Icons.location_on_outlined,
                        enabled: units.isNotEmpty,
                        onTap: () => _openPicker(
                          context: context,
                          units: units,
                          currentProvince: selectedProvince,
                          currentWard: selectedWard,
                          initialTab: 0,
                        ),
                        onClear: selectedProvince != null
                            ? () {
                                onProvinceChanged?.call(null);
                                onProvinceNameChanged?.call(null);
                                onCommuneChanged?.call(null);
                                onCommuneNameChanged?.call(null);
                              }
                            : null,
                      ),
                    ),
                    if (provinceError != null) VFieldError(provinceError!),
                  ],
                ),
              ),
            ),
            const VGap.md(),
            KeyedSubtree(
              key: communeKey,
              child: VField(
                invalid: communeError != null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SearchDropdownField(
                      label: communeLabel,
                      isRequired: isRequired,
                      child: _AdministrativeUnitTouchField(
                        fieldKey: communeFieldKey,
                        clearKey: communeClearKey,
                        value: selectedWard?.fullName,
                        hintText: canSelectWard
                            ? 'Chọn xã / phường'
                            : 'Chọn tỉnh / thành phố trước',
                        prefixIcon: Icons.apartment_outlined,
                        enabled: canSelectWard,
                        onTap: () => _openPicker(
                          context: context,
                          units: units,
                          currentProvince: selectedProvince,
                          currentWard: selectedWard,
                          initialTab: canSelectWard ? 1 : 0,
                        ),
                        onClear: selectedWard != null
                            ? () {
                                onCommuneChanged?.call(null);
                                onCommuneNameChanged?.call(null);
                              }
                            : null,
                      ),
                    ),
                    if (communeError != null) VFieldError(communeError!),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Interactive touch field that triggers the administrative unit picker bottom sheet.
class _AdministrativeUnitTouchField extends StatelessWidget {
  const _AdministrativeUnitTouchField({
    required this.fieldKey,
    this.clearKey,
    required this.value,
    required this.hintText,
    required this.prefixIcon,
    required this.enabled,
    required this.onTap,
    this.onClear,
  });

  final Key fieldKey;
  final Key? clearKey;
  final String? value;
  final String hintText;
  final IconData prefixIcon;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final hasValue = value != null && value!.isNotEmpty;

    return Semantics(
      button: true,
      enabled: enabled,
      child: InkWell(
        key: fieldKey,
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(VRadius.input),
        child: Container(
          height: VCombobox.controlHeight,
          padding: const EdgeInsets.symmetric(horizontal: VSpacing.space3),
          decoration: BoxDecoration(
            color: enabled ? colors.surface : colors.surfaceAlt,
            borderRadius: BorderRadius.circular(VRadius.input),
            border: Border.all(
              color: !enabled
                  ? colors.borderDefault.withValues(alpha: 0.5)
                  : VField.resolveInvalid(context, local: null)
                  ? colors.danger
                  : colors.borderDefault,
            ),
          ),
          child: Row(
            children: [
              Icon(
                prefixIcon,
                size: 18,
                color: enabled ? colors.textSecondary : colors.textMuted,
              ),
              const SizedBox(width: VSpacing.space2),
              Expanded(
                child: Text(
                  hasValue ? value! : hintText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: VTypography.bodyDefault.copyWith(
                    color: !enabled
                        ? colors.textMuted
                        : hasValue
                        ? colors.textPrimary
                        : colors.textSecondary,
                  ),
                ),
              ),
              if (hasValue && onClear != null) ...[
                GestureDetector(
                  key: clearKey,
                  onTap: onClear,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(VSpacing.space1),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: VSpacing.space1),
              ],
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: enabled ? colors.textSecondary : colors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchDropdownField extends StatelessWidget {
  const SearchDropdownField({
    super.key,
    required this.label,
    required this.child,
    this.isRequired = false,
  });

  final String label;
  final Widget child;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VFieldLabel(label, isRequired: isRequired),
        child,
      ],
    );
  }
}
