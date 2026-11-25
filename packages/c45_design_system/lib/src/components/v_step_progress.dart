import 'package:flutter/material.dart';

import '../foundation/v_context_extensions.dart';
import '../foundation/v_inspector_scope.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';

/// Token set of [VStepProgress].
enum VStepProgressVariant {
  /// Web frame.
  standard,

  /// iPhone frame (tighter gap, taller label, stronger todo bar).
  mobile,
}

/// Segmented progress bar for multi-step flows (sign-up, reset password):
/// one 4 px bar per step with a "n. Title" label underneath.
class VStepProgress extends StatelessWidget {
  const VStepProgress({
    super.key,
    required this.titles,
    required this.currentIndex,
    this.variant = VStepProgressVariant.standard,
    this.semanticLabel,
  });

  final List<String> titles;

  /// 0-based index of the current step.
  final int currentIndex;
  final VStepProgressVariant variant;

  /// Defaults to `<currentIndex + 1>/<titles.length> · <titles[currentIndex]>`.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    assert(titles.isNotEmpty, 'titles must not be empty');
    assert(currentIndex >= 0 && currentIndex < titles.length, 'currentIndex out of range');
    final colors = context.vColors;
    final mobile = variant == VStepProgressVariant.mobile;
    final innerGap = mobile ? 6.0 : VSpacing.space2;
    final lineHeight = (mobile ? 20.0 : 18.0) / 13;

    Color barColor(int i) {
      if (i <= currentIndex) return colors.primary;
      return mobile ? colors.borderStrong : colors.borderDefault;
    }

    Color labelColor(int i) {
      if (i == currentIndex) return mobile ? colors.textBrand : colors.primary;
      if (mobile) return colors.textSecondary;
      return i < currentIndex ? colors.textSecondary : colors.textMuted;
    }

    return vInspectorHide(
      Semantics(
        container: true,
        label: semanticLabel ?? '${currentIndex + 1}/${titles.length} · ${titles[currentIndex]}',
        child: ExcludeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < titles.length; i++) ...[
                if (i > 0) const SizedBox(width: VSpacing.space2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DecoratedBox(
                        key: Key('v-step-bar-$i'),
                        decoration: BoxDecoration(
                          color: barColor(i),
                          borderRadius: BorderRadius.circular(VRadius.pill),
                        ),
                        child: const SizedBox(height: 4),
                      ),
                      SizedBox(height: innerGap),
                      Text(
                        '${i + 1}. ${titles[i]}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: VTypography.bodySmall.copyWith(
                          fontSize: 13,
                          height: lineHeight,
                          // Không thừa hưởng letterSpacing 0.25 của Material: nhãn bước
                          // dài nhất sẽ tràn cột 114 ở 390.
                          letterSpacing: 0,
                          fontWeight: FontWeight.w600,
                          color: labelColor(i),
                        ),
                      ),
                    ],
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
