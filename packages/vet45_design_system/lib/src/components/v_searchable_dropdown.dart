import 'package:flutter/material.dart';

import '../foundation/v_context_extensions.dart';
import '../foundation/v_component_contracts.dart';
import '../foundation/v_dropdown_filter.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';

class VSearchableDropdown<T> extends StatelessWidget {
  /// Control height used by [inputDecorationTheme] constraints.
  static const double controlHeight = 44;

  static const EdgeInsets contentPadding = EdgeInsets.symmetric(
    horizontal: VSpacing.space3,
  );

  const VSearchableDropdown({
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

  final T? value;
  final List<DropdownMenuEntry<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool enabled;
  final String? hintText;
  final String? label;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final VComponentState state;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    final bool isEnabled = enabled && state != VComponentState.disabled;
    final Color borderColor = switch (tone) {
      VComponentTone.primary => colors.primary,
      VComponentTone.danger => Colors.red,
      _ => colors.borderDefault,
    };

    return Semantics(
      label: semanticLabel ?? label ?? hintText ?? 'Searchable dropdown',
      textField: true,
      enabled: isEnabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: VTypography.headingH4.copyWith(
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: VSpacing.space2),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              return DropdownMenu<T>(
                width: constraints.maxWidth,
                enabled: isEnabled,
                initialSelection: value,
                hintText: hintText,
                enableSearch: true,
                enableFilter: true,
                filterCallback: filterDropdownEntries,
                requestFocusOnTap: true,
                menuHeight: 300,
                textStyle: VTypography.bodyDefault.copyWith(
                  color: isEnabled ? colors.textPrimary : colors.textMuted,
                ),
                menuStyle: MenuStyle(
                  backgroundColor: WidgetStatePropertyAll(colors.surface),
                  surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(VRadius.input),
                      side: VBorders.side(colors.borderDefault),
                    ),
                  ),
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: isEnabled ? colors.surface : colors.surfaceAlt,
                  contentPadding: contentPadding,
                  hintStyle: VTypography.bodyDefault.copyWith(
                    color: colors.textMuted,
                  ),
                  enabledBorder: VBorders.outlineInput(
                    borderColor,
                    width: VBorders.widthFor(emphasis),
                  ),
                  disabledBorder: VBorders.outlineInput(colors.borderDefault),
                  focusedBorder: VBorders.outlineInput(colors.borderStrong),
                  constraints: const BoxConstraints(
                    minHeight: controlHeight,
                    maxHeight: controlHeight,
                  ),
                ),
                onSelected: onChanged,
                dropdownMenuEntries: items,
              );
            },
          ),
        ],
      ),
    );
  }
}
