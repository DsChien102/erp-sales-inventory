import 'package:flutter/material.dart';

import '../foundation/v_inspector_scope.dart';
import '../primitives/v_divider.dart';

class _VListDetailScope extends InheritedWidget {
  const _VListDetailScope({
    required this.isSplit,
    required super.child,
  });

  final bool isSplit;

  @override
  bool updateShouldNotify(_VListDetailScope oldWidget) => isSplit != oldWidget.isSplit;
}

/// Hai cột danh sách – chi tiết khi đủ rộng; hẹp hơn thì chỉ dựng [detail]
/// (trang hẹp tự lo danh sách qua navigator, xem W-2 mục 3.3).
class VListDetailLayout extends StatefulWidget {
  const VListDetailLayout({
    super.key,
    required this.list,
    required this.detail,
    this.listWidth = 360,
    this.minSplitWidth = 840,
  });

  final Widget list;
  final Widget detail;
  final double listWidth;
  final double minSplitWidth;

  /// `true` khi có [VListDetailLayout] tổ tiên đang chia 2 cột.
  static bool isSplitOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_VListDetailScope>();
    return scope?.isSplit ?? false;
  }

  @override
  State<VListDetailLayout> createState() => _VListDetailLayoutState();
}

class _VListDetailLayoutState extends State<VListDetailLayout> {
  final GlobalKey _detailKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSplit = constraints.maxWidth >= widget.minSplitWidth;
        final detailSubtree = KeyedSubtree(
          key: _detailKey,
          child: widget.detail,
        );

        if (isSplit) {
          return _VListDetailScope(
            isSplit: true,
            child: vInspectorHide(
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: widget.listWidth,
                    child: ScaffoldMessenger(
                      child: widget.list,
                    ),
                  ),
                  const VDivider(axis: Axis.vertical),
                  Expanded(
                    child: detailSubtree,
                  ),
                ],
              ),
            ),
          );
        }

        return _VListDetailScope(
          isSplit: false,
          child: vInspectorHide(detailSubtree),
        );
      },
    );
  }
}
