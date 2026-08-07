import 'package:flutter/material.dart';

import '../foundation/v_context_extensions.dart';
import '../tokens/v_duration.dart';
import '../tokens/v_radius.dart';

/// shadcn-style focus: solid primary border is on the field; this paints the
/// softer outer ring (`focusRing`) when [focused] is true.
///
/// Ring grows outward from the field edge (thickness 0 → [ringSize]) so corners
/// stay concentric with the input border.
class VTextFieldFocusRing extends StatelessWidget {
  const VTextFieldFocusRing({
    super.key,
    required this.focused,
    required this.child,
    this.danger = false,
    this.innerRadius = VRadius.input,
    this.ringSize = 3,
  });

  final bool focused;
  final Widget child;
  final bool danger;

  /// Corner radius of the input field (inner shape).
  final double innerRadius;

  /// Thickness of the soft outer ring at full focus.
  final double ringSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    // TODO: (tech debt) bỏ ringColor thay bằng sử dụng color scheme từ `colors`
    final ringColor = danger ? colors.danger.withValues(alpha: 0.30) : colors.focusRing;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          left: -ringSize,
          top: -ringSize,
          right: -ringSize,
          bottom: -ringSize,
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: focused ? 1 : 0),
              duration: VDuration.medium,
              curve: Curves.easeInOutQuad,
              builder: (context, t, _) {
                final size = ringSize * t;
                if (size <= 0) return const SizedBox.shrink();
                // Inset shrinks as [t] grows → ring expands from the field edge.
                final inset = ringSize - size;
                return Padding(
                  padding: EdgeInsets.all(inset),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(innerRadius + size),
                      border: Border.all(color: ringColor, width: size),
                    ),
                    child: const SizedBox.expand(),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
