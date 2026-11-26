import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Cột nội dung của luồng công khai nhiều bước (prototype `.t1-stepcol`):
/// rộng tối đa [maxWidth], đệm 24 / 16 / 32, cuộn được, canh trên giữa.
/// [centerVertically] đặt cột giữa chiều cao khi nội dung thấp hơn màn (đệm trên 32).
class FlowColumn extends StatelessWidget {
  const FlowColumn({
    super.key,
    required this.children,
    this.maxWidth = 520,
    this.centerVertically = false,
  });

  final List<Widget> children;
  final double maxWidth;
  final bool centerVertically;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Align(
            alignment: centerVertically ? Alignment.center : Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  VSpacing.screenMobile,
                  centerVertically ? VSpacing.xl : VSpacing.lg,
                  VSpacing.screenMobile,
                  VSpacing.xl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Thẻ trắng của luồng công khai: viền `borderDefault` 1, bo card, đệm 24 / 20.
class FlowCard extends StatelessWidget {
  const FlowCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Padding(
        padding: padding ??
            const EdgeInsets.symmetric(
              vertical: VSpacing.lg,
              horizontal: VSpacing.space5,
            ),
        child: child,
      ),
    );
  }
}

/// Ô biểu tượng `surfaceBrand`: [large] 64 viền `borderBrand` icon 28;
/// [medium] 48 không viền icon 24. Trang trí, không có semantics.
class FlowIcon extends StatelessWidget {
  const FlowIcon.large(this.icon, {super.key})
    : _size = 64,
      _iconSize = 28,
      _bordered = true;
  const FlowIcon.medium(this.icon, {super.key})
    : _size = 48,
      _iconSize = 24,
      _bordered = false;

  final VIcons icon;
  final double _size;
  final double _iconSize;
  final bool _bordered;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return ExcludeSemantics(
      child: Container(
        width: _size,
        height: _size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.surfaceBrand,
          borderRadius: BorderRadius.circular(VRadius.iconBox),
          border: _bordered ? Border.all(color: colors.borderBrand) : null,
        ),
        child: VIcon(icon: icon, size: _iconSize, color: colors.textBrand),
      ),
    );
  }
}
