import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

import 'inventory_layout.dart';
import 'inventory_states.dart';

class K6Status {
  const K6Status({
    required this.label,
    required this.tone,
  });

  final String label;
  final VComponentTone tone;
}

class K6Search {
  const K6Search({
    required this.value,
    required this.hint,
    required this.onChanged,
  });

  final String value;
  final String hint;
  final ValueChanged<String> onChanged;
}

class K6TaskRow<T> extends StatelessWidget {
  const K6TaskRow({
    super.key,
    required this.title,
    this.subtitle,
    this.below,
    this.status,
    this.trailing,
    this.disabled = false,
    this.onTap,
  }) : assert(
          status != null || trailing != null,
          'K6TaskRow cần status (badge) hoặc trailing',
        );

  final String title;
  final String? subtitle;
  final Widget? below;

  /// Badge trạng thái; bỏ trống khi dùng [trailing].
  final K6Status? status;

  /// Thay badge bằng widget tuỳ ý, căn phải; không đo chỗ badge.
  final Widget? trailing;
  final bool disabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = this.status;
    if (status == null) {
      return VListRow(
        title: title,
        subtitle: subtitle,
        enabled: !disabled,
        onTap: !disabled ? onTap : null,
        trailing: trailing,
        contentBelow: below,
      );
    }

    final badgeWidget = VBadge(
      label: status.label,
      tone: status.tone,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final movesBadgeBelow = constraints.maxWidth.isFinite &&
            _titleWraps(context, constraints.maxWidth, status);

        Widget? contentBelow;
        if (below != null && movesBadgeBelow) {
          contentBelow = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              below!,
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: badgeWidget,
              ),
            ],
          );
        } else if (below != null) {
          contentBelow = below;
        } else if (movesBadgeBelow) {
          contentBelow = Align(
            alignment: Alignment.centerLeft,
            child: badgeWidget,
          );
        }

        return VListRow(
          title: title,
          subtitle: subtitle,
          enabled: !disabled,
          onTap: !disabled ? onTap : null,
          trailing: movesBadgeBelow ? null : badgeWidget,
          contentBelow: contentBelow,
        );
      },
    );
  }

  // Kích thước cố định bên trong `VListRow` (không leading) và `VBadge` (cỡ thường),
  // không có token riêng: chevron 20, đệm ngang của badge 10 mỗi bên.
  static const double _chevronSize = 20;
  static const double _badgeHorizontalPadding = 10;

  /// G3-7: tiêu đề có gãy dòng nếu badge nằm cột phải không?
  /// Đo theo cỡ chữ người dùng (`textScaler`) cho cả tiêu đề và badge.
  bool _titleWraps(BuildContext context, double rowWidth, K6Status status) {
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);

    double measure(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: textDirection,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final titleWidth = measure(
      title,
      VTypography.bodyDefault.copyWith(fontWeight: FontWeight.w600),
    );
    final badgeWidth = measure(
          status.label,
          VTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ) +
        2 * _badgeHorizontalPadding;

    final available = rowWidth -
        2 * VSpacing.space3 - // đệm ngang của VListRow
        (VSpacing.space2 + badgeWidth) - // badge ở cột phải
        (VSpacing.space2 + _chevronSize); // chevron

    return titleWidth > available;
  }
}

class K6TaskList<T> extends StatelessWidget {
  const K6TaskList({
    super.key,
    this.search,
    this.filters,
    required this.columns,
    required this.rows,
    required this.total,
    required this.title,
    this.subtitle,
    this.below,
    this.status,
    this.trailing,
    this.isDisabled,
    required this.onOpen,
    required this.empty,
    required this.filterEmpty,
  }) : assert(
          status != null || trailing != null,
          'K6TaskList cần status (badge) hoặc trailing',
        );

  final K6Search? search;
  final K7FilterChips? filters;
  final List<K7Column<T>> columns;
  final List<T> rows;
  final int total;
  final String Function(T) title;
  final String Function(T)? subtitle;
  final Widget? Function(T)? below;
  final K6Status Function(T)? status;
  final Widget Function(T)? trailing;
  final bool Function(T)? isDisabled;
  final ValueChanged<T> onOpen;
  final InventoryEmpty empty;
  final InventoryEmpty filterEmpty;

  @override
  Widget build(BuildContext context) {
    if (total == 0) {
      return empty;
    }

    final isWide = inventoryIsWide(context);

    Widget content;
    if (rows.isEmpty && total > 0) {
      content = filterEmpty;
    } else if (isWide) {
      content = K7Table<T>(
        columns: columns,
        rows: rows,
        mobileRow: (item) => K6TaskRow<T>(
          title: title(item),
          subtitle: subtitle?.call(item),
          below: below?.call(item),
          status: status?.call(item),
          trailing: trailing?.call(item),
          disabled: isDisabled?.call(item) ?? false,
          onTap: () => onOpen(item),
        ),
        onRowTap: (item) {
          if (isDisabled?.call(item) != true) {
            onOpen(item);
          }
        },
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            K6TaskRow<T>(
              title: title(rows[i]),
              subtitle: subtitle?.call(rows[i]),
              below: below?.call(rows[i]),
              status: status?.call(rows[i]),
              trailing: trailing?.call(rows[i]),
              disabled: isDisabled?.call(rows[i]) ?? false,
              onTap: () => onOpen(rows[i]),
            ),
            if (i < rows.length - 1) const SizedBox(height: VSpacing.space2),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (search != null) ...[
          _K6SearchField(search: search!),
          const SizedBox(height: VSpacing.space3),
        ],
        if (filters != null) ...[
          filters!,
          const SizedBox(height: VSpacing.space3),
        ],
        content,
      ],
    );
  }
}

/// Ô tìm của K6: hiện lại từ khoá đang lọc (`K6Search.value`) khi màn dựng lại.
class _K6SearchField extends StatefulWidget {
  const _K6SearchField({required this.search});

  final K6Search search;

  @override
  State<_K6SearchField> createState() => _K6SearchFieldState();
}

class _K6SearchFieldState extends State<_K6SearchField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.search.value);

  @override
  void didUpdateWidget(covariant _K6SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final value = widget.search.value;
    if (value != _controller.text) {
      _controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VSearchBar(
      controller: _controller,
      hintText: widget.search.hint,
      onChanged: widget.search.onChanged,
    );
  }
}
