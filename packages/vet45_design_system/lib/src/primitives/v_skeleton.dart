import 'package:flutter/material.dart';
// contract: na tone/emphasis/state

import '../foundation/v_context_extensions.dart';
import '../tokens/v_duration.dart';
import '../tokens/v_radius.dart';

/// Shared pulse animation for descendant [VSkeleton] bones (shadcn-style).
///
/// Prefer wrapping a skeleton layout in one [VSkeletonScope] so all bones
/// share a single [AnimationController].
class VSkeletonScope extends StatefulWidget {
  const VSkeletonScope({
    super.key,
    required this.child,
    this.duration = VDuration.pulse,
  });

  final Widget child;
  final Duration duration;

  static Animation<double>? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_VSkeletonAnimation>()
        ?.opacity;
  }

  @override
  State<VSkeletonScope> createState() => _VSkeletonScopeState();
}

class _VSkeletonScopeState extends State<VSkeletonScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant VSkeletonScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _VSkeletonAnimation(
      opacity: _opacity,
      child: widget.child,
    );
  }
}

class _VSkeletonAnimation extends InheritedWidget {
  const _VSkeletonAnimation({
    required this.opacity,
    required super.child,
  });

  final Animation<double> opacity;

  @override
  bool updateShouldNotify(covariant _VSkeletonAnimation oldWidget) {
    return opacity != oldWidget.opacity;
  }
}

/// Loading placeholder bone — analogous to shadcn `Skeleton`.
///
/// Uses theme [VColorScheme.surfaceAlt] by default. When placed under
/// [VSkeletonScope], inherits the shared pulse; otherwise animates locally.
class VSkeleton extends StatefulWidget {
  const VSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = VRadius.r4,
    this.margin,
    this.color,
    this.semanticLabel,
  }) : isCircle = false;

  /// Circular bone (avatar / icon placeholder).
  const VSkeleton.circle({
    super.key,
    required double size,
    this.margin,
    this.color,
    this.semanticLabel,
  }) : width = size,
       height = size,
       borderRadius = null,
       isCircle = true;

  final double? width;
  final double? height;
  final double? borderRadius;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final String? semanticLabel;
  final bool isCircle;

  @override
  State<VSkeleton> createState() => _VSkeletonState();
}

class _VSkeletonState extends State<VSkeleton>
    with SingleTickerProviderStateMixin {
  AnimationController? _localController;
  Animation<double>? _localOpacity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scoped = VSkeletonScope.maybeOf(context);
    if (scoped != null) {
      _disposeLocal();
      return;
    }
    if (_localController == null) {
      _localController = AnimationController(
        vsync: this,
        duration: VDuration.pulse,
      )..repeat(reverse: true);
      _localOpacity = Tween<double>(begin: 0.4, end: 0.8).animate(
        CurvedAnimation(parent: _localController!, curve: Curves.easeInOut),
      );
    }
  }

  void _disposeLocal() {
    _localController?.dispose();
    _localController = null;
    _localOpacity = null;
  }

  @override
  void dispose() {
    _disposeLocal();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opacity = VSkeletonScope.maybeOf(context) ?? _localOpacity;
    final colors = context.vColors;
    final fill = widget.color ?? colors.surfaceAlt;

    final bone = Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: fill,
        shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: widget.isCircle
            ? null
            : BorderRadius.circular(widget.borderRadius ?? VRadius.r4),
      ),
    );

    final animated = opacity == null
        ? bone
        : AnimatedBuilder(
            animation: opacity,
            builder: (context, child) {
              return Opacity(
                opacity: opacity.value,
                child: child,
              );
            },
            child: bone,
          );

    return Semantics(
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel == null,
      child: animated,
    );
  }
}
