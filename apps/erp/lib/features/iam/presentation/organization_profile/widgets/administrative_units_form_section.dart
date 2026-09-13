import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import '../data/vn_administrative_units_loader.dart';

/// Form section containing province and ward selectors for VN administrative units.
class AdministrativeUnitsFormSection extends StatelessWidget {
  const AdministrativeUnitsFormSection({
    super.key,
    required this.unitsFuture,
    required this.selectedProvinceCode,
    required this.selectedCommuneCode,
    required this.onProvinceChanged,
    required this.onCommuneChanged,
  });

  final Future<List<VnAdministrativeUnit>> unitsFuture;
  final String? selectedProvinceCode;
  final String? selectedCommuneCode;
  final ValueChanged<String?> onProvinceChanged;
  final ValueChanged<String?> onCommuneChanged;

  static VnAdministrativeUnit? findProvinceByCode(
    List<VnAdministrativeUnit> units,
    String? code,
  ) {
    if (code == null) return null;
    for (final unit in units) {
      if (unit.code == code) return unit;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<VnAdministrativeUnit>>(
      future: unitsFuture,
      builder: (context, snapshot) {
        final units = snapshot.data ?? const [];
        final selectedProvince = findProvinceByCode(units, selectedProvinceCode);
        final wardList = selectedProvince?.wards ?? const <VnWard>[];
        VnWard? selectedWard;
        for (final ward in wardList) {
          if (ward.code == selectedCommuneCode) {
            selectedWard = ward;
            break;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SearchDropdownField(
              label: 'Tỉnh / thành phố',
              child: VCombobox<String>(
                value: selectedProvince?.code,
                displayTextForValue: (code) {
                  if (code == null) return '';
                  return findProvinceByCode(units, code)?.fullName ?? '';
                },
                onChanged: onProvinceChanged,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VComboboxContent(
                      child: VComboboxList(
                        children: [
                          for (final unit in units)
                            VComboboxItem<String>(
                              value: unit.code,
                              searchText: unit.fullName,
                              child: Text(unit.fullName),
                            ),
                        ],
                      ),
                    ),
                    const VComboboxInput(hintText: 'Chọn tỉnh / thành phố'),
                  ],
                ),
              ),
            ),
            const VGap.md(),
            SearchDropdownField(
              label: 'Xã / phường',
              child: VCombobox<String>(
                value: selectedWard?.code,
                enabled: selectedProvinceCode != null,
                displayTextForValue: (code) {
                  if (code == null) return '';
                  for (final ward in wardList) {
                    if (ward.code == code) return ward.fullName;
                  }
                  return '';
                },
                onChanged: onCommuneChanged,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VComboboxContent(
                      child: VComboboxList(
                        children: [
                          for (final ward in wardList)
                            VComboboxItem<String>(
                              value: ward.code,
                              searchText: ward.fullName,
                              child: Text(ward.fullName),
                            ),
                        ],
                      ),
                    ),
                    VComboboxInput(
                      hintText: selectedProvinceCode != null
                          ? 'Chọn xã / phường'
                          : 'Chọn tỉnh / thành phố trước',
                    ),
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

class SearchDropdownField extends StatelessWidget {
  const SearchDropdownField({
    super.key,
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
