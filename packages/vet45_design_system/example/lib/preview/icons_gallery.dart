import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Searchable grid of every [VIcons] token for the example catalog.
class VIconsGalleryPreview extends StatefulWidget {
  const VIconsGalleryPreview({super.key});

  @override
  State<VIconsGalleryPreview> createState() => _VIconsGalleryPreviewState();
}

class _VIconsGalleryPreviewState extends State<VIconsGalleryPreview> {
  String _query = '';

  List<VIcons> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return VIcons.values;
    return VIcons.values
        .where((icon) => icon.name.toLowerCase().contains(q))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final icons = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VTextField(
          hintText: 'Tìm icon theo tên (vd. cloud, chevron)…',
          prefixIcon: const VIcon(icon: VIcons.search),
          onChanged: (value) => setState(() => _query = value),
        ),
        const VGap.md(),
        VText(
          '${icons.length} / ${VIcons.values.length} icons',
          variant: VTextVariant.caption,
          color: colors.textSecondary,
        ),
        const VGap.sm(),
        if (icons.isEmpty)
          VText(
            'Không tìm thấy icon khớp “$_query”.',
            color: colors.textMuted,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              const minTile = 88.0;
              final crossAxisCount =
                  (constraints.maxWidth / minTile).floor().clamp(3, 8);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: icons.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: VSpacing.space2,
                  crossAxisSpacing: VSpacing.space2,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  final icon = icons[index];
                  return _IconTile(icon: icon);
                },
              );
            },
          ),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});

  final VIcons icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.r8),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.space2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            VIcon(icon: icon, iconSize: VIconSize.lg),
            const VGap.sm(),
            VText(
              icon.name,
              variant: VTextVariant.caption,
              color: colors.textSecondary,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
