import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'preview_section.dart';

class PrimitivesPreviewTab extends StatefulWidget {
  const PrimitivesPreviewTab({super.key});

  @override
  State<PrimitivesPreviewTab> createState() => _PrimitivesPreviewTabState();
}

class _PrimitivesPreviewTabState extends State<PrimitivesPreviewTab> {
  bool _chipSelected = true;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(VSpacing.screenMobile),
      children: [
        PreviewSection(
          title: 'VBadge',
          description: 'All VBadgeStatus values.',
          child: PreviewStateWrap(
            children: [
              for (final status in VBadgeStatus.values)
                VBadge(label: status.name, status: status),
              const VBadge(
                label: 'with dot',
                status: VBadgeStatus.info,
                showDot: true,
              ),
              const VBadge(
                label: 'small',
                status: VBadgeStatus.success,
                isSmall: true,
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VChip',
          description: 'Static, selectable, removable, disabled, emphasis.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PreviewStateRow(
                label: 'Static (no onTap)',
                child: PreviewStateWrap(
                  children: const [
                    VChip(label: 'Subdued', emphasis: VChipEmphasis.subdued),
                    VChip(label: 'Base', emphasis: VChipEmphasis.base),
                    VChip(label: 'Strong', emphasis: VChipEmphasis.strong),
                  ],
                ),
              ),
              PreviewStateRow(
                label: 'Selectable',
                child: PreviewStateWrap(
                  children: [
                    VChip(
                      label: 'Filter A',
                      selected: _chipSelected,
                      onTap: () => setState(() => _chipSelected = !_chipSelected),
                    ),
                    VChip(
                      label: 'Filter B',
                      selected: !_chipSelected,
                      onTap: () => setState(() => _chipSelected = !_chipSelected),
                      leadingIcon: Icons.tag,
                    ),
                  ],
                ),
              ),
              PreviewStateRow(
                label: 'Removable',
                child: VChip(
                  label: 'Tag removable',
                  onRemove: () {},
                  leadingIcon: Icons.label_outline,
                ),
              ),
              PreviewStateRow(
                label: 'Disabled',
                child: PreviewStateWrap(
                  children: [
                    VChip(label: 'Disabled static', enabled: false),
                    VChip(
                      label: 'Disabled clickable',
                      enabled: false,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VIcon',
          child: PreviewStateWrap(
            children: const [
              VIcon(iconData: Icons.home_rounded),
              VIcon(iconData: Icons.person_outline, size: 18),
              VIcon(iconData: Icons.warning_amber_rounded, color: VColors.warning),
              VIcon(iconData: Icons.check_circle, color: VColors.success, size: 28),
              VIcon(iconData: Icons.error_outline, color: VColors.danger, size: 28),
            ],
          ),
        ),
        PreviewSection(
          title: 'VIconBox',
          child: PreviewStateWrap(
            children: [
              VIconBox(iconData: Icons.qr_code_scanner, onTap: () {}),
              VIconBox(
                iconData: Icons.add,
                backgroundColor: VColors.primary100,
                iconColor: VColors.primary700,
                onTap: () {},
              ),
              const VIconBox(
                iconData: Icons.lock_outline,
                backgroundColor: VColors.neutral100,
                iconColor: VColors.neutral500,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
