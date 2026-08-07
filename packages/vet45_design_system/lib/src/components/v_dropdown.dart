import 'package:flutter/material.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_component_contracts.dart';
import '../primitives/v_text.dart';
import '../primitives/v_icon.dart';
import '../foundations/icons/v_icons.dart';
import '../patterns/v_gap.dart';

class VDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool enabled;
  final String? hintText;
  final String? label;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final VComponentState state;
  final String? semanticLabel;

  const VDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
    this.hintText,
    this.label,
    this.tone = VComponentTone.neutral,
    this.emphasis = VComponentEmphasis.medium,
    this.state = VComponentState.enabled,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    DropdownMenuItem<T>? selectedItem;
    try {
      selectedItem = items.firstWhere((item) => item.value == value);
    } catch (_) {
      selectedItem = null;
    }

    final bool isEnabled = enabled && state != VComponentState.disabled;
    final Color borderColor = switch (tone) {
      VComponentTone.primary => colors.primary,
      VComponentTone.danger => colors.danger,
      _ => isEnabled ? colors.borderStrong : colors.borderDefault,
    };

    return Semantics(
      label: semanticLabel ?? label ?? hintText ?? 'Dropdown',
      textField: true,
      enabled: isEnabled,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          VText(
            label!,
            style: VTypography.headingH4.copyWith(
              color: enabled ? colors.textPrimary : colors.textMuted,
            ),
          ),
          const VGap.sm(),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            return PopupMenuButton<T>(
              enabled: isEnabled,
              offset: const Offset(
                0,
                48,
              ), // Opens right below the 44px container
              onSelected: onChanged,
              tooltip: '',
              color: colors.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(VRadius.input),
                side: VBorders.side(colors.borderDefault),
              ),
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                maxWidth: constraints.maxWidth,
              ),
              itemBuilder: (BuildContext context) {
                return items.map((item) {
                  return PopupMenuItem<T>(
                    value: item.value,
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.centerLeft,
                      child: DefaultTextStyle(
                        style: VTypography.bodyDefault.copyWith(
                          color: colors.textPrimary,
                        ),
                        child: item.child,
                      ),
                    ),
                  );
                }).toList();
              },
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(
                  horizontal: VSpacing.space3,
                ),
                decoration: BoxDecoration(
                  color: isEnabled ? colors.surface : colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(VRadius.input),
                  border: VBorders.all(
                    borderColor,
                    width: VBorders.widthFor(emphasis),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: DefaultTextStyle(
                        style: VTypography.bodyDefault.copyWith(
                          color: enabled
                              ? (selectedItem != null ? colors.textPrimary : colors.textMuted)
                              : colors.textSecondary,
                        ),
                        child: selectedItem != null
                            ? selectedItem.child
                            : VText(
                                hintText ?? 'Chọn...',
                                color: enabled ? colors.textMuted : colors.textSecondary,
                              ),
                      ),
                    ),
                    VIcon(
                      icon: VIcons.chevronDown,
                      color: isEnabled ? colors.textSecondary : colors.textMuted,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ),
    );
  }
}
