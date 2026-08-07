import 'package:flutter/material.dart';

import '../foundation/v_component_contracts.dart';
import '../foundation/v_context_extensions.dart';
import '../patterns/v_gap.dart';
import '../primitives/v_text.dart';
import '../theme/v_color_scheme.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';

/// Mutually exclusive segmented control (brand fill on selected).
///
/// Overall height stays at [VSpacing.minTouchTarget] (44). Prefer 2–4 segments.
class VSegmentedControl extends StatelessWidget {
  const VSegmentedControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
    this.enabled = true,
    this.tone = VComponentTone.primary,
    this.emphasis = VComponentEmphasis.medium,
    this.state,
    this.semanticLabel,
  });

  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool enabled;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final VComponentState? state;
  final String? semanticLabel;

  VComponentState _resolveState() =>
      state ?? (enabled ? VComponentState.enabled : VComponentState.disabled);

  Color _selectedBg(VColorScheme colors) => switch (tone) {
        VComponentTone.danger => colors.danger,
        VComponentTone.warning => colors.warning,
        VComponentTone.success => colors.success,
        VComponentTone.info => colors.info,
        _ => colors.primary,
      };

  @override
  Widget build(BuildContext context) {
    assert(segments.length >= 2, 'VSegmentedControl needs at least 2 segments');
    final colors = context.vColors;
    final isEnabled = _resolveState() == VComponentState.enabled;
    final selectedBg = _selectedBg(colors);

    return Semantics(
      label: semanticLabel ?? 'Segmented control',
      child: Opacity(
        opacity: isEnabled ? 1 : 0.5,
        child: Container(
          height: VSpacing.minTouchTarget,
          padding: const EdgeInsets.all(VSpacing.space1),
          decoration: BoxDecoration(
            color: colors.surfaceAlt,
            borderRadius: BorderRadius.circular(VRadius.r8 + 2),
          ),
          child: Row(
            children: [
              for (var i = 0; i < segments.length; i++) ...[
                if (i > 0) const VGap.horizontalXs(),
                Expanded(
                  child: _Segment(
                    label: segments[i],
                    selected: i == selectedIndex,
                    enabled: isEnabled,
                    selectedBg: selectedBg,
                    onTap: () => onChanged(i),
                    colors: colors,
                    emphasis: emphasis,
                  ),
                ),
              ],
            ],
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
    required this.selectedBg,
    required this.onTap,
    required this.colors,
    required this.emphasis,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final Color selectedBg;
  final VoidCallback onTap;
  final VColorScheme colors;
  final VComponentEmphasis emphasis;

  @override
  Widget build(BuildContext context) {
    final borderWidth = VBorders.widthFor(emphasis);

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: label,
      child: Material(
        color: selected ? selectedBg : colors.surface,
        borderRadius: BorderRadius.circular(VRadius.r8),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(VRadius.r8),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(VRadius.r8),
              border: selected
                  ? null
                  : VBorders.all(
                      colors.borderDefault,
                      width: borderWidth,
                    ),
            ),
            child: VText(
              label,
              variant: VTextVariant.bodyDefault,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              color: selected ? colors.surface : colors.textPrimary,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                height: 20 / 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
