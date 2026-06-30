import 'package:flutter/material.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';

class VTableHeader {
  final String title;
  final bool isNumeric;

  const VTableHeader({
    required this.title,
    this.isNumeric = false,
  });
}

class VTable extends StatelessWidget {
  final List<VTableHeader> headers;
  final List<List<Widget>> rows;
  final Map<int, TableColumnWidth>? columnWidths;

  const VTable({
    super.key,
    required this.headers,
    required this.rows,
    this.columnWidths,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Table(
      columnWidths: columnWidths,
      border: TableBorder(
        bottom: BorderSide(color: dynamicColors.borderDefault),
        horizontalInside: BorderSide(color: dynamicColors.borderDefault),
      ),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        // Header Row
        TableRow(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: dynamicColors.borderStrong, width: 1.5)),
          ),
          children: headers.map((header) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: VSpacing.space3,
                horizontal: VSpacing.space2,
              ),
              child: Text(
                header.title.toUpperCase(),
                style: VTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: dynamicColors.textSecondary,
                ),
                textAlign: header.isNumeric ? TextAlign.right : TextAlign.left,
              ),
            );
          }).toList(),
        ),
        // Data Rows
        ...rows.map((row) {
          assert(row.length == headers.length, 'Row length must match headers length');
          return TableRow(
            children: row.map((cell) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: VSpacing.space3,
                  horizontal: VSpacing.space2,
                ),
                child: cell,
              );
            }).toList(),
          );
        }),
      ],
    );
  }
}
