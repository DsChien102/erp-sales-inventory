import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

/// Single bordered surface with dividers between children (Figma grouped surface).
class SalesOrderDetailGroupedSurface extends StatelessWidget {
  const SalesOrderDetailGroupedSurface({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        items.add(const VDivider());
      }
      items.add(children[i]);
    }

    return VCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: items,
      ),
    );
  }
}
