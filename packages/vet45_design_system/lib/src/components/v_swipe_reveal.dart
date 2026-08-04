import 'package:flutter/material.dart';

/// Swipe-left shell that reveals actions behind [child].
///
/// Shared by swipe record / order line — implementation detail (not barrel-exported).
class VSwipeReveal extends StatefulWidget {
  const VSwipeReveal({
    super.key,
    required this.child,
    required this.actionsBuilder,
    required this.actionExtent,
    this.enabled = true,
    this.initiallyRevealed = false,
    this.onTap,
    this.height,
    this.clipBorderRadius,
  });

  final Widget child;

  /// Build revealed actions; call [close] after an action fires.
  final Widget Function(BuildContext context, VoidCallback close) actionsBuilder;
  final double actionExtent;
  final bool enabled;
  final bool initiallyRevealed;
  final VoidCallback? onTap;
  final double? height;
  final BorderRadius? clipBorderRadius;

  @override
  State<VSwipeReveal> createState() => _VSwipeRevealState();
}

class _VSwipeRevealState extends State<VSwipeReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _dragExtent = 0;

  bool get _isOpen => _controller.value > 0.01;

  @override
  void initState() {
    super.initState();
    final revealed = widget.initiallyRevealed;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: revealed ? 1 : 0,
    );
    _dragExtent = revealed ? -widget.actionExtent : 0;
  }

  @override
  void didUpdateWidget(covariant VSwipeReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initiallyRevealed == oldWidget.initiallyRevealed) return;
    widget.initiallyRevealed ? _open() : _close();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    _controller.animateTo(0);
    _dragExtent = 0;
  }

  void _open() {
    _controller.animateTo(1);
    _dragExtent = -widget.actionExtent;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled || widget.actionExtent <= 0) return;
    final next =
        (_dragExtent + details.delta.dx).clamp(-widget.actionExtent, 0.0);
    setState(() => _dragExtent = next);
    _controller.value = (-_dragExtent) / widget.actionExtent;
  }

  void _onDragEnd(DragEndDetails details) {
    if (!widget.enabled || widget.actionExtent <= 0) return;
    final velocity = details.primaryVelocity ?? 0;
    final shouldOpen = velocity < -200 || _controller.value > 0.45;
    shouldOpen ? _open() : _close();
  }

  @override
  Widget build(BuildContext context) {
    final canSwipe = widget.enabled && widget.actionExtent > 0;
    final body = Stack(
      children: [
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: widget.actionsBuilder(context, _close),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Transform.translate(
            offset: Offset(-_controller.value * widget.actionExtent, 0),
            child: child,
          ),
          child: GestureDetector(
            onHorizontalDragUpdate: canSwipe ? _onDragUpdate : null,
            onHorizontalDragEnd: canSwipe ? _onDragEnd : null,
            child: GestureDetector(
              onTap: !widget.enabled
                  ? null
                  : () => _isOpen ? _close() : widget.onTap?.call(),
              child: widget.child,
            ),
          ),
        ),
      ],
    );

    final clipped = widget.clipBorderRadius != null
        ? ClipRRect(borderRadius: widget.clipBorderRadius!, child: body)
        : ClipRect(child: body);

    return SizedBox(height: widget.height, child: clipped);
  }
}
