import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../tokens/v_spacing.dart';
import 'v_combobox_empty.dart';
import 'v_combobox_item.dart';
import 'v_combobox.dart';

/// Filters [children] ([VComboboxItem]s) by root query and shows [empty] when none match.
///
/// Uses [Column] + [SingleChildScrollView] (not [ListView.shrinkWrap]) so
/// [MenuAnchor] can measure the overlay without hitting
/// `RenderShrinkWrappingViewport` intrinsic-dimension assertions.
class VComboboxList extends StatelessWidget {
  static const double _menuMaxHeight = 300;
  static const double _listMaxHeight = _menuMaxHeight - (VSpacing.space2 * 2);

  static final ScrollBehavior _menuScrollBehavior = const MaterialScrollBehavior()
      .copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.stylus,
          PointerDeviceKind.trackpad,
        },
      );

  const VComboboxList({
    super.key,
    required this.children,
    this.empty = const VComboboxEmpty(),
  });

  final List<Widget> children;
  final Widget empty;

  @override
  Widget build(BuildContext context) {
    final root = vComboboxOf(context);
    return ListenableBuilder(
      listenable: root,
      builder: (context, _) => _buildFiltered(context, root),
    );
  }

  Widget _buildFiltered(BuildContext context, VComboboxController root) {
    final visible = <Widget>[];
    for (final child in children) {
      if (child is VComboboxItem) {
        if (root.matchesItem(child.value, searchText: child.searchText)) {
          visible.add(child);
        }
      } else {
        visible.add(child);
      }
    }

    if (visible.isEmpty) {
      return SizedBox(
        height: VComboboxEmpty.preferredHeight,
        width: double.infinity,
        child: empty,
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: _listMaxHeight),
      child: ScrollConfiguration(
        behavior: _menuScrollBehavior,
        child: SingleChildScrollView(
          primary: false,
          padding: EdgeInsets.zero,
          physics: const ClampingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: visible,
          ),
        ),
      ),
    );
  }
}
