import 'package:flutter/material.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_design_system/design_system.dart';

import 'product_control_center_section_card.dart';

class ProductControlCenterCustomFieldsSection extends StatelessWidget {
  const ProductControlCenterCustomFieldsSection({
    super.key,
    required this.groups,
    required this.onEditGroup,
  });

  final List<CustomFieldGroupCardDto> groups;
  final ValueChanged<CustomFieldGroupCardDto> onEditGroup;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: VSpacing.space2,
      children: [
        for (final group in groups)
          ProductControlCenterSectionCard(
            title: group.name,
            emoji: group.iconKey?.isNotEmpty == true ? group.iconKey : null,
            icon: group.iconKey?.isNotEmpty == true ? null : VIcons.clipboard,
            hasError: group.hasRequiredMissing,
            subtitle: _subtitleFor(group),
            actionText: group.fields.every((f) => !f.isActive) ? 'Xem' : 'Sửa',
            onEdit: () => onEditGroup(group),
          ),
      ],
    );
  }

  String _subtitleFor(CustomFieldGroupCardDto group) {
    final filledCount = group.fields
        .where((f) => f.displayValue != null && f.displayValue!.isNotEmpty)
        .length;
    return '$filledCount/${group.fields.length} trường đã điền';
  }
}
