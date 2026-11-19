import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

import 'icons_gallery.dart';
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
          title: 'VText',
          description: 'All VTextVariant values + color / overflow / align.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final variant in VTextVariant.values)
                PreviewStateRow(
                  label: variant.name,
                  child: VText(
                    'The quick brown fox — ${variant.name}',
                    variant: variant,
                  ),
                ),
              PreviewStateRow(
                label: 'Colors',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Builder(
                      builder: (context) {
                        final colors = context.vColors;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            VText('textPrimary', color: colors.textPrimary),
                            VText('textSecondary', color: colors.textSecondary),
                            VText('textMuted', color: colors.textMuted),
                            VText('textBrand', color: colors.textBrand),
                            VText('danger', color: colors.danger),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const PreviewStateRow(
                label: 'maxLines + overflow ellipsis',
                child: SizedBox(
                  width: 180,
                  child: VText(
                    'This is a long line that should truncate with an ellipsis at the end.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const PreviewStateRow(
                label: 'textAlign center',
                child: SizedBox(
                  width: double.infinity,
                  child: VText(
                    'Centered text',
                    textAlign: TextAlign.center,
                    variant: VTextVariant.headingH4,
                  ),
                ),
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VBadge',
          description: 'Every VComponentTone in soft and strong variant.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PreviewStateRow(
                label: 'soft — tinted surface + tone foreground',
                child: PreviewStateWrap(
                  children: [
                    for (final tone in VComponentTone.values) VBadge(label: tone.name, tone: tone),
                  ],
                ),
              ),
              PreviewStateRow(
                label: 'strong — tone fill + inverted foreground',
                child: PreviewStateWrap(
                  children: [
                    for (final tone in VComponentTone.values)
                      VBadge(
                        label: tone.name,
                        tone: tone,
                        variant: VBadgeVariant.strong,
                      ),
                  ],
                ),
              ),
              PreviewStateRow(
                label: 'small (isSmall) — soft then strong',
                child: PreviewStateWrap(
                  children: [
                    for (final variant in VBadgeVariant.values)
                      for (final tone in VComponentTone.values)
                        VBadge(
                          label: tone.name,
                          tone: tone,
                          variant: variant,
                          isSmall: true,
                        ),
                  ],
                ),
              ),
              PreviewStateRow(
                label: 'dot / icon / ambient tone',
                child: PreviewStateWrap(
                  children: [
                    const VBadge(
                      label: 'with dot',
                      tone: VComponentTone.info,
                      showDot: true,
                    ),
                    const VBadge(
                      label: 'with dot',
                      tone: VComponentTone.info,
                      variant: VBadgeVariant.strong,
                      showDot: true,
                    ),
                    const VBadge(
                      label: 'with icon',
                      tone: VComponentTone.success,
                      iconData: Icons.check_rounded,
                    ),
                    const VBadge(
                      label: 'with icon',
                      tone: VComponentTone.success,
                      variant: VBadgeVariant.strong,
                      iconData: Icons.check_rounded,
                    ),
                    vProvideComponentScope(
                      tone: VComponentTone.danger,
                      child: const VBadge(label: 'ambient tone'),
                    ),
                    vProvideComponentScope(
                      tone: VComponentTone.danger,
                      child: const VBadge(
                        label: 'ambient tone',
                        variant: VBadgeVariant.strong,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VChip',
          description: 'Every VComponentTone, plus selectable, removable, disabled.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PreviewStateRow(
                label: 'All tones (static)',
                child: PreviewStateWrap(
                  children: [
                    for (final tone in VComponentTone.values)
                      VChip(label: tone.name, tone: tone),
                  ],
                ),
              ),
              PreviewStateRow(
                label: 'All tones (with icon, clickable)',
                child: PreviewStateWrap(
                  children: [
                    for (final tone in VComponentTone.values)
                      VChip(
                        label: tone.name,
                        tone: tone,
                        icon: VIcons.tag,
                        onTap: () {},
                      ),
                  ],
                ),
              ),
              PreviewStateRow(
                label: 'Selectable — tone primary when selected',
                child: PreviewStateWrap(
                  children: [
                    VChip(
                      label: 'Filter A',
                      tone: _chipSelected
                          ? VComponentTone.primary
                          : VComponentTone.neutral,
                      onTap: () => setState(() => _chipSelected = !_chipSelected),
                    ),
                    VChip(
                      label: 'Filter B',
                      tone: _chipSelected
                          ? VComponentTone.neutral
                          : VComponentTone.primary,
                      onTap: () => setState(() => _chipSelected = !_chipSelected),
                      icon: VIcons.tag,
                    ),
                  ],
                ),
              ),
              PreviewStateRow(
                label: 'Ambient tone via VComponentScope',
                child: vProvideComponentScope(
                  tone: VComponentTone.info,
                  child: const PreviewStateWrap(
                    children: [
                      VChip(label: 'inherits info'),
                      VChip(label: 'local danger', tone: VComponentTone.danger),
                    ],
                  ),
                ),
              ),
              PreviewStateRow(
                label: 'Removable',
                child: PreviewStateWrap(
                  children: [
                    VChip(
                      label: 'Tag removable',
                      onRemove: () {},
                      icon: VIcons.tag,
                    ),
                    VChip(
                      label: 'Danger removable',
                      tone: VComponentTone.danger,
                      onRemove: () {},
                    ),
                  ],
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
          child: Builder(
            builder: (context) {
              final colors = context.vColors;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PreviewStateRow(
                    label: 'Sizes and colors',
                    child: PreviewStateWrap(
                      children: [
                        const VIcon(icon: VIcons.home),
                        const VIcon(icon: VIcons.person, size: 18),
                        VIcon(icon: VIcons.warning, color: colors.warning),
                        VIcon(icon: VIcons.success, color: colors.success, size: 28),
                        VIcon(icon: VIcons.check, color: colors.success, size: 28),
                        VIcon(icon: VIcons.error, color: colors.danger, size: 28),
                      ],
                    ),
                  ),
                  PreviewStateRow(
                    label:
                        'Weight — default (null) rồi thin → semiBold, cùng icon ở size 32',
                    child: PreviewStateWrap(
                      children: [
                        const VIcon(icon: VIcons.search, size: 32),
                        for (final weight in VIconWeight.values)
                          VIcon(icon: VIcons.search, size: 32, weight: weight),
                      ],
                    ),
                  ),
                  PreviewStateRow(
                    label: 'Weight ở size nhỏ (16) — cùng thứ tự',
                    child: PreviewStateWrap(
                      children: [
                        const VIcon(icon: VIcons.calendar, size: 16),
                        for (final weight in VIconWeight.values)
                          VIcon(icon: VIcons.calendar, size: 16, weight: weight),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const PreviewSection(
          title: 'VIcons catalog',
          description:
              'Toàn bộ token trong enum VIcons — tìm theo tên để chọn icon khi implement UI.',
          child: VIconsGalleryPreview(),
        ),
        PreviewSection(
          title: 'VIconBox',
          child: PreviewStateWrap(
            children: [
              // Drawn 24px, tappable area 44×44 (hit-test the corners).
              VIconBox(
                icon: VIcons.camera,
                size: 24,
                iconSize: 16,
                semanticLabel: 'Chụp ảnh',
                onTap: () {},
              ),
              VIconBox(
                icon: VIcons.add,
                tone: VComponentTone.primary,
                semanticLabel: 'Thêm',
                onTap: () {},
              ),
              const VIconBox(
                icon: VIcons.lock,
                tone: VComponentTone.neutral,
              ),
              VAvatar(name: 'Nguyễn Văn A', textSize: 14),
            ],
          ),
        ),
        PreviewSection(
          title: 'VDivider',
          description: 'Horizontal / vertical separator; default thickness 1, color borderDefault.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PreviewStateRow(
                label: 'Horizontal (default)',
                child: VDivider(),
              ),
              PreviewStateRow(
                label: 'Horizontal + indent',
                child: const VDivider(indent: VSpacing.md, endIndent: VSpacing.md),
              ),
              PreviewStateRow(
                label: 'Custom color / thickness',
                child: Builder(
                  builder: (context) {
                    return VDivider(
                      thickness: 2,
                      color: context.vColors.borderStrong,
                    );
                  },
                ),
              ),
              PreviewStateRow(
                label: 'Vertical',
                child: SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      const VText('Left'),
                      const VGap.horizontalSm(),
                      const VDivider(axis: Axis.vertical),
                      const VGap.horizontalSm(),
                      const VText('Right'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VSkeleton',
          description: 'Shadcn-style loading bones. Prefer VSkeletonScope when composing many.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PreviewStateRow(
                label: 'Standalone bones',
                child: PreviewStateWrap(
                  children: const [
                    VSkeleton(width: 120, height: 16),
                    VSkeleton(width: 80, height: 12, borderRadius: VRadius.r8),
                    VSkeleton.circle(size: 40),
                  ],
                ),
              ),
              PreviewStateRow(
                label: 'Scoped layout (shared pulse)',
                child: VSkeletonScope(
                  child: Row(
                    children: [
                      const VSkeleton.circle(size: 48),
                      const VGap.horizontalMd(),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            VSkeleton(width: 140, height: 16),
                            VGap.sm(),
                            VSkeleton(width: 100, height: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PreviewStateRow(
                label: 'semanticLabel',
                child: const VSkeleton(
                  width: 160,
                  height: 18,
                  semanticLabel: 'Đang tải',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
