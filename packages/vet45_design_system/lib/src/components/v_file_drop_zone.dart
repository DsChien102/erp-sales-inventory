import 'package:flutter/material.dart';

import '../foundation/v_component_contracts.dart';
import '../foundation/v_context_extensions.dart';
import '../foundations/icons/v_icons.dart';
import '../patterns/v_gap.dart';
import '../primitives/v_icon.dart';
import '../primitives/v_text.dart';
import '../theme/v_color_scheme.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';

/// Trạng thái visual của [VFileDropZone].
///
/// Mapping Excel import:
/// - [empty] — chưa nhập
/// - [valid] — đang kéo hợp lệ / vùng sẵn sàng
/// - [invalid] — file/excel không hợp lệ
/// - [disabled] — chặn quyền / không tương tác
enum VFileDropZoneState { empty, valid, invalid, disabled }

/// Drop zone chọn / kéo thả file (UI only — không chứa file_picker).
///
/// Role: input. State derive → [VComponentState].
///
/// Khi có [action] (vd. nút "Chọn file từ thiết bị"), vùng chỉ là visual +
/// drag target; tap chọn file nên gắn vào [action], không bọc cả zone bằng
/// InkWell để tránh xung đột với nút.
class VFileDropZone extends StatelessWidget {
  const VFileDropZone({
    super.key,
    required this.title,
    this.subtitle,
    this.state = VFileDropZoneState.empty,
    this.onTap,
    this.icon,
    this.trailing,
    this.action,
    this.minHeight = 148,
    this.semanticLabel,
  });

  final String title;
  final String? subtitle;

  /// empty / valid / invalid / disabled.
  final VFileDropZoneState state;

  /// Null khi [state] == disabled hoặc khi dùng [action] làm CTA chính.
  final VoidCallback? onTap;

  /// Override icon mặc định theo state.
  final VIcons? icon;

  /// Optional trailing (vd. badge).
  final Widget? trailing;

  /// CTA nằm trong zone (vd. outline button "Chọn file từ thiết bị").
  final Widget? action;

  final double minHeight;
  final String? semanticLabel;

  VComponentState get _componentState => switch (state) {
        VFileDropZoneState.disabled => VComponentState.disabled,
        VFileDropZoneState.invalid => VComponentState.error,
        VFileDropZoneState.empty ||
        VFileDropZoneState.valid =>
          VComponentState.enabled,
      };

  bool get _isInteractive =>
      state != VFileDropZoneState.disabled && onTap != null && action == null;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final style = _styleFor(colors);
    final resolvedIcon = icon ?? style.icon;
    final radius = BorderRadius.circular(VRadius.card);

    final content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: style.background,
                borderRadius: radius,
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _DashedRRectPainter(
                  color: style.borderColor,
                  radius: VRadius.card,
                  strokeWidth: 1.5,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.md,
              vertical: VSpacing.lg,
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VIcon(
                        icon: resolvedIcon,
                        size: VSpacing.space10,
                        color: style.iconColor,
                      ),
                      const VGap.sm(),
                      VText(
                        title,
                        variant: VTextVariant.bodyDefault,
                        color: style.titleColor,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const VGap.xs(),
                        VText(
                          subtitle!,
                          variant: VTextVariant.bodySmall,
                          color: style.subtitleColor,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (action != null) ...[
                        const VGap.md(),
                        action!,
                      ],
                    ],
                  ),
                ),
                if (trailing != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: trailing!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    return Semantics(
      label: semanticLabel ?? title,
      button: _isInteractive,
      enabled: _componentState != VComponentState.disabled,
      child: Material(
        color: Colors.transparent,
        child: _isInteractive
            ? InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: onTap,
                borderRadius: radius,
                child: content,
              )
            : content,
      ),
    );
  }

  _DropZoneStyle _styleFor(VColorScheme colors) {
    return switch (state) {
      VFileDropZoneState.empty => _DropZoneStyle(
          background: colors.surface,
          borderColor: colors.borderDefault,
          icon: VIcons.cloudUpload,
          iconColor: colors.success,
          titleColor: colors.textPrimary,
          subtitleColor: colors.textSecondary,
        ),
      VFileDropZoneState.valid => _DropZoneStyle(
          background: colors.successBg,
          borderColor: colors.success,
          icon: VIcons.cloudUpload,
          iconColor: colors.success,
          titleColor: colors.textPrimary,
          subtitleColor: colors.textSecondary,
        ),
      VFileDropZoneState.invalid => _DropZoneStyle(
          background: colors.dangerBg,
          borderColor: colors.danger,
          icon: VIcons.fileUp,
          iconColor: colors.danger,
          titleColor: colors.danger,
          subtitleColor: colors.danger,
        ),
      VFileDropZoneState.disabled => _DropZoneStyle(
          background: colors.disabledBg,
          borderColor: colors.disabledBorder,
          icon: VIcons.cloudUpload,
          iconColor: colors.disabledFg,
          titleColor: colors.disabledFg,
          subtitleColor: colors.disabledFg,
        ),
    };
  }
}

class _DropZoneStyle {
  const _DropZoneStyle({
    required this.background,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.titleColor,
    required this.subtitleColor,
  });

  final Color background;
  final Color borderColor;
  final VIcons icon;
  final Color iconColor;
  final Color titleColor;
  final Color subtitleColor;
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({
    required this.color,
    required this.radius,
    this.strokeWidth = 1.5,
  });

  final Color color;
  final double radius;
  final double strokeWidth;

  /// Khớp mock: nét đứt trên mọi state.
  static const double _dashLength = 8;
  static const double _gapLength = 5;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final inset = strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        inset,
        inset,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular((radius - inset).clamp(0, radius)),
    );

    final path = Path()..addRRect(rrect);
    canvas.drawPath(_dashPath(path), paint);
  }

  Path _dashPath(Path source) {
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final next = (distance + (draw ? _dashLength : _gapLength))
            .clamp(0.0, metric.length)
            .toDouble();
        if (draw) {
          dashed.addPath(metric.extractPath(distance, next), Offset.zero);
        }
        distance = next;
        draw = !draw;
      }
    }
    return dashed;
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
