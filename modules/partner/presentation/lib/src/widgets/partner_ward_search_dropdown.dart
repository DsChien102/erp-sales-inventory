import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../data/vn_administrative_unit.dart';
import 'partner_compact_field.dart';

/// Ward picker — same [VCompactSearchableDropdown] params as province
/// (`trailingMode: builtin`) so trailing icons share one layout.
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
      value: value.isEmpty ? null : value,
      hintText: hintText,
      enabled: enabled,
      stickyActionsReserve: PartnerCompactField.stickyActionsReserve,
      menuHeight: PartnerCompactField.menuHeight,
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
