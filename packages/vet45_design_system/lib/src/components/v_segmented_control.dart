import 'package:flutter/material.dart';

import '../foundation/v_component_contracts.dart';
import '../foundation/v_component_scope.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_inspector_scope.dart';
import '../patterns/v_gap.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import 'v_button.dart';

/// Mutually exclusive segmented control (brand fill on selected).
///
/// Segments are [VButton] (`small`); prefer 2–4 segments.
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
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    assert(segments.length >= 2, 'VSegmentedControl needs at least 2 segments');
    final colors = context.vColors;
    final isEnabled = VComponentScope.resolveEnabled(context, local: enabled);

    return vInspectorHide(
      Semantics(
        label: semanticLabel ?? 'Segmented control',
        child: Opacity(
          opacity: isEnabled ? 1 : 0.5,
          child: Container(
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
                    child: Semantics(
                      button: true,
                      selected: i == selectedIndex,
                      enabled: isEnabled,
                      label: segments[i],
                      child: VButton(
                        label: segments[i],
                        fullWidth: true,
                        size: VButtonSize.medium,
                        variant: i == selectedIndex
                            ? VButtonVariant.primary
                            : VButtonVariant.secondary,
                        tone: tone,
                        emphasis: emphasis,
                        onPressed: isEnabled ? () => onChanged(i) : null,
                        semanticLabel: segments[i],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
