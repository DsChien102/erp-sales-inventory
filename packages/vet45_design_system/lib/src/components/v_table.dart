import 'package:flutter/material.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_component_contracts.dart';
import '../foundation/v_inspector_scope.dart';

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
  final VComponentEmphasis emphasis;
  final VComponentTone? tone;
  final bool stripedRows;
  final String? semanticLabel;
  final ValueChanged<int>? onRowTap;

  const VTable({
    super.key,
    required this.headers,
    required this.rows,
    this.columnWidths,
    this.emphasis = VComponentEmphasis.medium,
    this.tone,
    this.stripedRows = false,
    this.semanticLabel,
    this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    final resolvedTone = tone ?? VComponentTone.neutral;
    final headerAccent = switch (resolvedTone) {
      VComponentTone.primary => dynamicColors.primary,
      VComponentTone.danger => dynamicColors.danger,
      _ => dynamicColors.borderStrong,
    };

    return vInspectorHide(
      Semantics(
        label: semanticLabel ?? 'Data table',
        child: Table(
          columnWidths: columnWidths,
          border: TableBorder(
            bottom: VBorders.side(dynamicColors.borderDefault),
            horizontalInside: VBorders.side(dynamicColors.borderDefault),
          ),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            // Header Row
            TableRow(
              decoration: BoxDecoration(
                border: Border(
                  bottom: VBorders.side(
                    resolvedTone == VComponentTone.neutral
                        ? dynamicColors.borderStrong
                        : headerAccent,
                    width: VBorders.widthFor(emphasis),
                  ),
                ),
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
            ...rows.asMap().entries.map((entry) {
              final row = entry.value;
              assert(row.length == headers.length, 'Row length must match headers length');
              final int rowIndex = entry.key;
              return TableRow(
                decoration: stripedRows && rowIndex.isOdd
                    ? BoxDecoration(color: dynamicColors.surfaceAlt.withValues(alpha: 0.35))
                    : null,
                children: [
                  for (var i = 0; i < row.length; i++)
                    () {
                      Widget cell = Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: VSpacing.space3,
                          horizontal: VSpacing.space2,
                        ),
                        // Numeric columns align right like their header, so
                        // amounts stack digit over digit.
                        child: headers[i].isNumeric
                            ? Align(alignment: Alignment.centerRight, child: row[i])
                            : row[i],
                      );

                      if (onRowTap != null) {
                        cell = InkWell(
                          onTap: () => onRowTap!(rowIndex),
                          child: cell,
                        );
                        if (i == 0) {
                          cell = Semantics(
                            button: true,
                            child: cell,
                          );
                        }
                      }
                      return cell;
                    }(),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
