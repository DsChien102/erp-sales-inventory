import 'package:flutter/material.dart';

import '../foundation/v_component_contracts.dart';
import '../primitives/v_icon_box.dart';

/// Circular initials avatar for partner (KH/NCC) identities.
///
/// Composes [VIconBox] with success tone by default so feature UI only passes
/// a display name — no manual color/initials wiring at call sites.
class VAvatar extends StatelessWidget {
  /// Creates an avatar from a display [name], deriving 1–2 uppercase initials.
  factory VAvatar({
    Key? key,
    required String name,
    double size = 40.0,
    double? textSize,
    Color? backgroundColor,
    Color? foregroundColor,
    VoidCallback? onTap,
  }) {
    return VAvatar._(
      key: key,
      label: _initialsFrom(name),
      size: size,
      textSize: textSize,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      onTap: onTap,
    );
  }

  const VAvatar._({
    super.key,
    required this.label,
    this.size = 40.0,
    this.textSize,
    this.backgroundColor,
    this.foregroundColor,
    this.onTap,
  });

  /// Resolved initials label (1–2 Latin letters, or `?`).
  final String label;

  final double size;

  /// Initials font size — defaults to a ratio of [size].
  final double? textSize;

  /// Overrides the default success-tone background.
  final Color? backgroundColor;

  /// Overrides the default success-tone foreground.
  final Color? foregroundColor;

  final VoidCallback? onTap;

  /// Initials for avatar label (1–2 Latin letters, or `?`).
  static String _initialsFrom(String displayName) {
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
    final hasColorOverride = backgroundColor != null || foregroundColor != null;

    return VIconBox(
      label: label,
      isCircular: true,
      size: size,
      iconSize: textSize ?? size * 0.35,
      backgroundColor: backgroundColor,
      iconColor: foregroundColor,
      tone: hasColorOverride ? null : VComponentTone.success,
      onTap: onTap,
    );
  }
}
