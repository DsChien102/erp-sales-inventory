import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

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
                            const VText('danger', color: VColors.danger),
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
              const VBadge(
                label: 'tone override',
                status: VBadgeStatus.draft,
                tone: VComponentTone.danger,
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
                    VChip(label: 'Subtle', emphasis: VComponentEmphasis.subtle),
                    VChip(label: 'Medium', emphasis: VComponentEmphasis.medium),
                    VChip(label: 'Strong', emphasis: VComponentEmphasis.strong),
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
                      icon: VIcons.tag,
                    ),
                  ],
                ),
              ),
              PreviewStateRow(
                label: 'Removable',
                child: VChip(
                  label: 'Tag removable',
                  onRemove: () {},
                  icon: VIcons.tag,
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
              VIcon(icon: VIcons.home),
              VIcon(icon: VIcons.person, size: 18),
              VIcon(icon: VIcons.warning, color: VColors.warning),
              VIcon(icon: VIcons.success, color: VColors.success, size: 28),
              VIcon(icon: VIcons.error, color: VColors.danger, size: 28),
            ],
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
              VIconBox(icon: VIcons.camera, onTap: () {}),
              VIconBox(
                icon: VIcons.add,
                tone: VComponentTone.primary,
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
          title: 'VSkeleton',
          description:
              'Shadcn-style loading bones. Prefer VSkeletonScope when composing many.',
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
