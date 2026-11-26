import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Hai nút liền nhau chọn loại chủ thể trên màn hình hẹp (prototype `.t1-segctl`).
class EntityTypeSegment extends StatelessWidget {
  const EntityTypeSegment({
    super.key,
    required this.value,
    required this.onChanged,
    this.invalid = false,
  });

  final String? value;
  final ValueChanged<String> onChanged;
  final bool invalid;

  static const _options = [
    ('HOUSEHOLD_BUSINESS', 'Hộ kinh doanh'),
    ('ENTERPRISE', 'Doanh nghiệp'),
  ];

  void _step(int delta) {
    final currentIndex = _options.indexWhere((o) => o.$1 == value);
    final nextIndex = currentIndex < 0
        ? (delta > 0 ? 0 : _options.length - 1)
        : (currentIndex + delta).clamp(0, _options.length - 1);
    if (_options[nextIndex].$1 != value) {
      onChanged(_options[nextIndex].$1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Focus(
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _step(-1);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _step(1);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (focusContext) {
          Widget half(int i) => _SegmentHalf(
            key: ValueKey(_options[i].$1),
            label: _options[i].$2,
            selected: value == _options[i].$1,
            invalid: invalid,
            isFirst: i == 0,
            // Đường chia giữa chỉ vẽ một lần (prototype `margin-left: -1px`):
            // nửa phải giữ nó khi đang được chọn (và không lỗi), còn lại nửa trái.
            ownsDivider: i == 0
                ? !(value == _options[1].$1 && !invalid)
                : value == _options[1].$1 && !invalid,
            onTap: () {
              Focus.of(focusContext).requestFocus();
              onChanged(_options[i].$1);
            },
            colors: colors,
          );
          return Semantics(
            container: true,
            label: 'Loại chủ thể',
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: half(0)),
                  Expanded(child: half(1)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SegmentHalf extends StatelessWidget {
  const _SegmentHalf({
    super.key,
    required this.label,
    required this.selected,
    required this.invalid,
    required this.isFirst,
    required this.ownsDivider,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final bool selected;
  final bool invalid;
  final bool isFirst;
  final bool ownsDivider;
  final VoidCallback onTap;
  final VColorScheme colors;

  /// Cùng một màu cho mọi cạnh hiện (bo góc yêu cầu màu đồng nhất); cạnh chung
  /// là `BorderSide.none` khi nửa kia giữ đường chia.
  Border _border(Color color) {
    final side = BorderSide(color: color);
    final divider = ownsDivider ? side : BorderSide.none;
    return Border(
      top: side,
      bottom: side,
      left: isFirst ? side : divider,
      right: isFirst ? divider : side,
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = invalid
        ? colors.danger
        : selected
        ? colors.primary
        : colors.borderInput;
    final bgColor = selected ? colors.surfaceBrand : colors.surface;
    final fgColor = selected ? colors.textBrand : colors.textPrimary;
    final radius = isFirst
        ? const BorderRadius.horizontal(left: Radius.circular(VRadius.input))
        : const BorderRadius.horizontal(right: Radius.circular(VRadius.input));

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: VSpacing.space2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: radius,
            border: _border(borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selected) ...[
                VIcon(icon: VIcons.check, size: 16, color: fgColor),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: VTypography.bodyDefault.copyWith(
                    fontWeight: FontWeight.w600,
                    color: fgColor,
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
