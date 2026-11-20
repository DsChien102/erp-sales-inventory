import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

/// Layout selectable card — Avatar (KH/SP) hoặc List row (đơn vị bán).
enum PricingSelectableCardStyle {
  /// Leading + copy + radio trailing (Figma Avatar Card).
  avatar,

  /// Radio leading + copy (Figma List Row / Selection).
  listRow,
}

/// Feature-local selectable card (Figma DS v2).
///
/// Compose [VCard] + copy + [VRadio]. Single padding layer from [VCard].
/// Must sit under a [RadioGroup] of the same [T] for radio state.
class PricingSelectableEntityCard<T> extends StatelessWidget {
  const PricingSelectableEntityCard({
    super.key,
    required this.value,
    required this.isSelected,
    required this.onTap,
    required this.title,
    this.leading,
    this.subtitle,
    this.caption,
    this.subtitleChild,
    this.captionChild,
    this.style = PricingSelectableCardStyle.avatar,
    this.selectedSurfaceFill = false,
  });

  final T value;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final String? caption;
  final Widget? subtitleChild;
  final Widget? captionChild;
  final PricingSelectableCardStyle style;
  final bool selectedSurfaceFill;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final titleColor = colors.textPrimary;
    final secondaryColor = colors.textSecondary;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VText(
          title,
          variant: VTextVariant.bodyDefault,
          color: titleColor,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitleChild != null) ...[
          const VGap.xs(),
          subtitleChild!,
        ] else if (subtitle != null && subtitle!.isNotEmpty) ...[
          const VGap.xs(),
          VText(
            subtitle!,
            variant: VTextVariant.bodySmall,
            color: secondaryColor,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (captionChild != null) ...[
          const VGap.xs(),
          captionChild!,
        ] else if (caption != null && caption!.isNotEmpty) ...[
          const VGap.xs(),
          VText(
            caption!,
            variant: VTextVariant.bodySmall,
            color: secondaryColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );

    final radio = IgnorePointer(
      child: VRadio<T>(
        value: value,
        onChanged: null,
      ),
    );

    final rowChildren = switch (style) {
      PricingSelectableCardStyle.avatar => [
        if (leading != null) ...[
          leading!,
          const VGap.horizontalSm(),
        ],
        Expanded(child: content),
        const VGap.horizontalSm(),
        radio,
      ],
      PricingSelectableCardStyle.listRow => [
        radio,
        const VGap.horizontalSm(),
        Expanded(child: content),
      ],
    };

    return VCard(
      tone: isSelected ? VComponentTone.success : null,
      emphasis: isSelected ? VComponentEmphasis.strong : VComponentEmphasis.medium,
      backgroundColor: isSelected && selectedSurfaceFill ? colors.successBg : null,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: rowChildren,
      ),
    );
  }
}

/// Rounded-square initials leading — Figma Avatar Card (not circular [VAvatar]).
class PricingPickInitialsLeading extends StatelessWidget {
  const PricingPickInitialsLeading({super.key, required this.name});

  final String name;

  static String initialsFrom(String displayName) {
    final words = displayName.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '?';
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    final last = words.last;
    if (last.isEmpty) return words.first.substring(0, 1).toUpperCase();
    return '${words.first.substring(0, 1)}${last.substring(0, 1)}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return VIconBox(
      label: initialsFrom(name),
      size: 52,
      iconSize: 13,
      isCircular: false,
      borderRadius: VRadius.r16,
      tone: VComponentTone.success,
    );
  }
}
