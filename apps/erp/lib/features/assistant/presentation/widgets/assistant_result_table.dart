import 'package:erp/features/assistant/data.dart' hide TableRow;
import 'package:erp/features/assistant/data.dart' as data show TableRow;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../assistant_cell_format.dart';
import '../assistant_open_target.dart';

bool _isNumeric(ColumnKind k) =>
    k == ColumnKind.tien || k == ColumnKind.so || k == ColumnKind.phanTram;

String? _location(data.TableRow row) {
  final open = row.open;
  return open == null ? null : assistantOpenLocation(open);
}

/// Bảng thật (rộng ≥ [VBreakpoints.tablet]) hoặc từng thẻ (hẹp), theo bề rộng khung bảng.
class AssistantResultTable extends StatelessWidget {
  const AssistantResultTable({super.key, required this.block});

  final TableBlock block;

  @override
  Widget build(BuildContext context) {
    if (block.columns.isEmpty || block.rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (block.title.isNotEmpty) ...[
          VText(block.title, variant: VTextVariant.headingH4),
          const SizedBox(height: VSpacing.sm),
        ],
        LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth >= VBreakpoints.tablet
              ? _Grid(block: block)
              : _Cards(block: block),
        ),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.block});

  final TableBlock block;

  @override
  Widget build(BuildContext context) {
    final c = context.vColors;
    return VTable(
      headers: [
        for (final col in block.columns)
          VTableHeader(title: col.name, isNumeric: _isNumeric(col.kind)),
      ],
      columnWidths: const {0: FlexColumnWidth(3)},
      onRowTap: (i) {
        final location = _location(block.rows[i]);
        if (location != null) context.push(location);
      },
      rows: [
        for (final row in block.rows)
          [
            for (var i = 0; i < block.columns.length; i++)
              VText(
                formatAssistantCell(block.columns[i].kind, row.cells[block.columns[i].key]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: _isNumeric(block.columns[i].kind) ? TextAlign.right : TextAlign.left,
                color: i == 0 && _location(row) != null ? c.textBrand : null,
              ),
          ],
      ],
    );
  }
}

class _Cards extends StatelessWidget {
  const _Cards({required this.block});

  final TableBlock block;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final row in block.rows) ...[
        _RowCard(block: block, row: row),
        const SizedBox(height: VSpacing.sm),
      ],
    ],
  );
}

class _RowCard extends StatelessWidget {
  const _RowCard({required this.block, required this.row});

  final TableBlock block;
  final data.TableRow row;

  @override
  Widget build(BuildContext context) {
    final c = context.vColors;
    final location = _location(row);
    final first = block.columns.first;
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VSpacing.cozy),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: location != null ? c.borderBrand : c.borderDefault),
        borderRadius: BorderRadius.circular(VRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VText(
            formatAssistantCell(first.kind, row.cells[first.key]),
            variant: VTextVariant.headingH4,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          for (final col in block.columns.skip(1))
            Padding(
              padding: const EdgeInsets.only(top: VSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: VText(
                      col.name,
                      variant: VTextVariant.bodySmall,
                      color: c.textSecondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: VSpacing.sm),
                  Flexible(
                    child: VText(
                      formatAssistantCell(col.kind, row.cells[col.key]),
                      variant: VTextVariant.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    if (location == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(VRadius.card),
      onTap: () => context.push(location),
      child: content,
    );
  }
}
