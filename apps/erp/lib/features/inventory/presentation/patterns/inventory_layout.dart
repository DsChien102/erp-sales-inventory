import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

bool inventoryIsWide(BuildContext context) {
  return MediaQuery.sizeOf(context).width >= VBreakpoints.desktop;
}

class K7Split extends StatelessWidget {
  const K7Split({
    super.key,
    required this.main,
    required this.aside,
    this.wideMain = false,
    this.asideWebOnly = false,
  });

  final Widget main;
  final Widget aside;
  final bool wideMain;
  final bool asideWebOnly;

  @override
  Widget build(BuildContext context) {
    final isWide = inventoryIsWide(context);

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: wideMain ? 7 : 5,
            child: main,
          ),
          const SizedBox(width: VSpacing.space4),
          Expanded(
            flex: wideMain ? 5 : 7,
            child: aside,
          ),
        ],
      );
    }

    if (asideWebOnly) {
      return main;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        main,
        const SizedBox(height: VSpacing.space3),
        aside,
      ],
    );
  }
}

class K7Column<T> {
  const K7Column({
    required this.label,
    required this.cell,
    this.numeric = false,
  });

  final String label;
  final Widget Function(T) cell;
  final bool numeric;
}

class K7Table<T> extends StatelessWidget {
  const K7Table({
    super.key,
    required this.columns,
    required this.rows,
    required this.mobileRow,
    this.onRowTap,
  });

  final List<K7Column<T>> columns;
  final List<T> rows;
  final Widget Function(T) mobileRow;
  final ValueChanged<T>? onRowTap;

  @override
  Widget build(BuildContext context) {
    final isWide = inventoryIsWide(context);

    if (isWide) {
      return VTable(
        headers: columns
            .map((c) => VTableHeader(title: c.label, isNumeric: c.numeric))
            .toList(),
        rows: rows
            .map((row) => columns.map((col) => col.cell(row)).toList())
            .toList(),
        onRowTap: onRowTap != null ? (index) => onRowTap!(rows[index]) : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (onRowTap != null)
            InkWell(
              onTap: () => onRowTap!(rows[i]),
              child: mobileRow(rows[i]),
            )
          else
            mobileRow(rows[i]),
          if (i < rows.length - 1) const SizedBox(height: VSpacing.space2),
        ],
      ],
    );
  }
}

class K7Filter {
  const K7Filter({
    required this.key,
    required this.label,
    required this.count,
  });

  final String key;
  final String label;
  final int count;
}

class K7FilterChips extends StatelessWidget {
  const K7FilterChips({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  final List<K7Filter> items;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            VChip(
              label: items[i].label,
              count: items[i].count,
              tone: items[i].key == selected
                  ? VComponentTone.primary
                  : VComponentTone.neutral,
              onTap: () => onSelected(items[i].key),
            ),
            if (i < items.length - 1) const SizedBox(width: VSpacing.space2),
          ],
        ],
      ),
    );
  }
}
