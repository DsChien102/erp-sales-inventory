import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Business overlay: dải góc chéo kiểu Flutter [Banner] (như EnvBanner) + icon
/// `%` — báo hiệu dòng/SP đang dùng giá riêng / special price.
///
/// Bản thân là [Stack]: [child] nằm dưới, ribbon nằm trên, clip theo
/// [borderRadius] (shape của content). Không có shadow.
class SalesSpecialPriceBanner extends StatelessWidget {
  const SalesSpecialPriceBanner({
    super.key,
    required this.child,
    this.visible = true,
    this.borderRadius,
  });

  final Widget child;

  /// `false` → chỉ render [child], không vẽ ribbon.
  final bool visible;

  /// Clip child + ribbon theo bo góc content (vd. dòng hàng / thumbnail).
  final BorderRadius? borderRadius;

  static const Key bannerKey = Key('sales_special_price_banner');

  @override
  Widget build(BuildContext context) {
    if (!visible) return child;

    final colors = context.vColors;
    final radius = borderRadius ?? BorderRadius.zero;

    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          child,
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final side = math.min(
                  constraints.maxWidth.isFinite ? constraints.maxWidth : 40.0,
                  constraints.maxHeight.isFinite ? constraints.maxHeight : 40.0,
                );
                final offset = side * 0.4;
                final height = math.max(10.0, side * 0.22);
                final iconSize = height * 0.85;
                final ribbonMidY = offset - height / 2;
                final iconCenter = Offset(
                  ribbonMidY * math.sqrt1_2,
                  ribbonMidY * math.sqrt1_2,
                );

                return IgnorePointer(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CustomPaint(
                        key: bannerKey,
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: _SalesSpecialPriceRibbonPainter(
                          color: colors.success,
                          offset: offset,
                          height: height,
                        ),
                      ),
                      Positioned(
                        left: iconCenter.dx - iconSize / 2,
                        top: iconCenter.dy - iconSize / 2,
                        width: iconSize,
                        height: iconSize,
                        child: Transform.rotate(
                          angle: -math.pi / 4,
                          child: VIcon(
                            icon: VIcons.badgePercent,
                            size: iconSize,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Dải chéo top-start (LTR), geometry tương đương [BannerPainter] — không shadow.
class _SalesSpecialPriceRibbonPainter extends CustomPainter {
  const _SalesSpecialPriceRibbonPainter({
    required this.color,
    required this.offset,
    required this.height,
  });

  final Color color;
  final double offset;
  final double height;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(-offset, offset - height, offset * 2.0, height);
    final bannerPaint = Paint()..color = color;

    canvas
      ..save()
      ..translate(0, 0)
      ..rotate(-math.pi / 4)
      ..drawRect(rect, bannerPaint)
      ..restore();
  }

  @override
  bool shouldRepaint(covariant _SalesSpecialPriceRibbonPainter oldDelegate) {
    return color != oldDelegate.color ||
        offset != oldDelegate.offset ||
        height != oldDelegate.height;
  }

  @override
  bool hitTest(Offset position) => false;
}
