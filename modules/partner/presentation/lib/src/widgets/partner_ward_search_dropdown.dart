import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../data/vn_administrative_unit.dart';

/// Ward picker — same [VCompactSearchableDropdown] as province
/// (`trailingMode: builtin`) so trailing icons share one layout.
///
/// Remounts when [enabled]/[wards] change so Flutter [DropdownMenu] does not
/// keep a stale disabled/non-searchable text field after province selection.
class PartnerWardSearchDropdown extends StatelessWidget {
  const PartnerWardSearchDropdown({
    super.key,
    required this.value,
    required this.wards,
    required this.enabled,
    required this.hintText,
    required this.onSelected,
  });

  final String value;
  final List<VnWard> wards;
  final bool enabled;
  final String hintText;
  final ValueChanged<VnWard> onSelected;

  @override
  Widget build(BuildContext context) {
    return VCompactSearchableDropdown<String>(
      // Remount when province unlocks wards — keeps enableSearch/filter live.
      key: ValueKey<Object>('ward_${enabled}_${wards.length}'),
      value: value.isEmpty ? null : value,
      hintText: hintText,
      enabled: enabled,
      stickyActionsReserve: 72,
      menuHeight: VOverlayMenuLayout.defaultMenuHeight,
      items: wards
          .map(
            (ward) => DropdownMenuEntry<String>(
              value: ward.fullName,
              label: ward.fullName,
            ),
          )
          .toList(growable: false),
      onChanged: (selected) {
        if (selected == null) return;
        for (final ward in wards) {
          if (ward.fullName == selected) {
            onSelected(ward);
            return;
          }
        }
      },
    );
  }
}
