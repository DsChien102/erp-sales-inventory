import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

class AdminTableColumn {
  const AdminTableColumn(
    this.label, {
    this.flex = 1,
    this.minWidth = 0,
  });

  final String label;
  final double flex;
  final double minWidth;
}

class AdminTableRow {
  const AdminTableRow({
    required this.cells,
    required this.onTap,
    required this.semanticLabel,
  });

  final List<Widget> cells;
  final VoidCallback onTap;
  final String semanticLabel;
}

class AdminTable extends StatelessWidget {
  const AdminTable({
    super.key,
    required this.columns,
    required this.rows,
    this.loadingRows = 0,
    this.state,
    this.semanticLabel,
  });

  final List<AdminTableColumn> columns;
  final List<AdminTableRow> rows;
  final int loadingRows;
  final Widget? state;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    Widget content;
    if (loadingRows > 0) {
      content = VSkeletonScope(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderRow(columns: columns),
            for (var i = 0; i < loadingRows; i++) ...[
              Divider(height: 1, color: colors.borderDefault),
              _SkeletonRow(columns: columns),
            ],
          ],
        ),
      );
    } else if (state != null) {
      content = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 360),
        child: Center(child: state!),
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderRow(columns: columns),
          for (final row in rows) ...[
            Divider(height: 1, color: colors.borderDefault),
            _DataRow(columns: columns, row: row),
          ],
        ],
      );
    }

    final table = Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: Border.all(color: colors.borderDefault),
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );

    if (semanticLabel == null || semanticLabel!.isEmpty) return table;
    return Semantics(
      label: semanticLabel,
      container: true,
      child: table,
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.columns});

  final List<AdminTableColumn> columns;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Container(
      color: colors.surfaceAlt,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          for (var i = 0; i < columns.length; i++) ...[
            if (i > 0) const SizedBox(width: 16),
            Expanded(
              flex: (columns[i].flex * 10).round().clamp(1, 100),
              child: VText(
                columns[i].label,
                variant: VTextVariant.caption,
                color: colors.textSecondary,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
          const SizedBox(width: 16),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.columns,
    required this.row,
  });

  final List<AdminTableColumn> columns;
  final AdminTableRow row;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Semantics(
      container: true,
      button: true,
      label: row.semanticLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: row.onTap,
        hoverColor: colors.surfaceAlt,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              for (var i = 0; i < columns.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                Expanded(
                  flex: (columns[i].flex * 10).round().clamp(1, 100),
                  child: i < row.cells.length
                      ? row.cells[i]
                      : const SizedBox.shrink(),
                ),
              ],
              const SizedBox(width: 16),
              SizedBox(
                width: 24,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: VIcon(
                    icon: VIcons.chevronRight,
                    size: 20,
                    color: colors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.columns});

  final List<AdminTableColumn> columns;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          for (var i = 0; i < columns.length; i++) ...[
            if (i > 0) const SizedBox(width: 16),
            Expanded(
              flex: (columns[i].flex * 10).round().clamp(1, 100),
              child: i == 0
                  ? const Row(
                      children: [
                        VSkeleton.circle(size: 36),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              VSkeleton(width: 160, height: 16),
                              SizedBox(height: 8),
                              VSkeleton(width: 120, height: 12),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: VSkeleton(
                        width: i == 2 ? 72 : 110,
                        height: i == 2 ? 22 : 16,
                      ),
                    ),
            ),
          ],
          const SizedBox(width: 16),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}

class AdminTablePage extends StatelessWidget {
  const AdminTablePage({
    super.key,
    required this.children,
    this.onNearEnd,
  });

  final List<Widget> children;
  final VoidCallback? onNearEnd;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (onNearEnd != null &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 120) {
          onNearEnd!();
        }
        return false;
      },
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
