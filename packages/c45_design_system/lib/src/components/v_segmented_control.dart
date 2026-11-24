import 'package:flutter/material.dart';

import '../foundation/v_component_contracts.dart';
import '../foundation/v_component_scope.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_inspector_scope.dart';
import '../theme/v_color_scheme.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_duration.dart';
import '../tokens/v_opacity.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_shadows.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';

/// Mutually exclusive segmented control: a Shelf Gray track with a white
/// thumb under the selected segment.
///
/// The thumb is a surface, not a brand fill, so the screen's single primary
/// button keeps Clinic Leaf Green to itself. Each segment cell spans the full
/// [VSpacing.minTouchTarget] height; the thumb is inset inside it. Prefer 2–4
/// segments.
class VSegmentedControl extends StatelessWidget {
  const VSegmentedControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
    this.enabled,
    this.tone = VComponentTone.primary,
    this.emphasis = VComponentEmphasis.medium,
    this.semanticLabel,
  });

  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool? enabled;

  /// Selected label color: ink for [VComponentTone.primary] / neutral,
  /// otherwise the status color of the tone.
  final VComponentTone tone;

  /// `strong` lifts the thumb to [VShadows.e2]; otherwise [VShadows.e1].
  final VComponentEmphasis emphasis;
  final String? semanticLabel;

  static const double _thumbInset = VSpacing.space1;

  Color _selectedLabelColor(VColorScheme colors) {
    return switch (tone) {
      VComponentTone.success => colors.success,
      VComponentTone.warning => colors.warning,
      VComponentTone.danger => colors.danger,
      VComponentTone.info => colors.info,
      VComponentTone.primary || VComponentTone.neutral => colors.textPrimary,
    };
  }

  @override
  Widget build(BuildContext context) {
    assert(segments.length >= 2, 'VSegmentedControl needs at least 2 segments');
    final colors = context.vColors;
    final isEnabled = VComponentScope.resolveEnabled(context, local: enabled);
    final animate = !MediaQuery.disableAnimationsOf(context);
    final height = context.vDensity.controlHeightMedium < VSpacing.minTouchTarget
        ? VSpacing.minTouchTarget
        : context.vDensity.controlHeightMedium;
    final thumbShadow = emphasis == VComponentEmphasis.strong ? VShadows.e2 : VShadows.e1;
    final selectedColor = _selectedLabelColor(colors);

    return vInspectorHide(
      Semantics(
        label: semanticLabel ?? 'Segmented control',
        container: true,
        explicitChildNodes: true,
        child: vDisabledOpacity(
          enabled: isEnabled,
          child: IgnorePointer(
            ignoring: !isEnabled,
            child: Container(
              height: height,
              padding: const EdgeInsets.symmetric(horizontal: _thumbInset),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                // Hairline keeps the track readable when it sits on Shelf Gray.
                border: VBorders.all(colors.borderDefault),
                borderRadius: BorderRadius.circular(VRadius.button + _thumbInset),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < segments.length; i++)
                    Expanded(
                      child: _Segment(
                        label: segments[i],
                        selected: i == selectedIndex,
                        enabled: isEnabled,
                        animate: animate,
                        selectedColor: selectedColor,
                        thumbShadow: thumbShadow,
                        onTap: i == selectedIndex ? null : () => onChanged(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.animate,
    required this.selectedColor,
    required this.thumbShadow,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final bool animate;
  final Color selectedColor;
  final List<BoxShadow> thumbShadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final duration = animate ? VDuration.fast : Duration.zero;

    // Weight stays 600 in both states so the label never reflows on select.
    final labelStyle = VTypography.actionDefault.copyWith(
      color: selected ? selectedColor : colors.textSecondary,
    );

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: VSegmentedControl._thumbInset),
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.space2),
            decoration: BoxDecoration(
              color: selected ? colors.surface : colors.surface.withValues(alpha: 0),
              borderRadius: BorderRadius.circular(VRadius.button),
              border: VBorders.all(
                selected ? colors.borderStrong : colors.borderStrong.withValues(alpha: 0),
              ),
              boxShadow: selected ? thumbShadow : const <BoxShadow>[],
            ),
            child: AnimatedDefaultTextStyle(
              duration: duration,
              curve: Curves.easeOutCubic,
              style: labelStyle,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
