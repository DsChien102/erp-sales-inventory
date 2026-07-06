import 'package:flutter/material.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';

String _removeVietnameseTones(String str) {
  str = str.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
  str = str.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
  str = str.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
  str = str.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
  str = str.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
  str = str.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
  str = str.replaceAll(RegExp(r'[đ]'), 'd');
  str = str.replaceAll(RegExp(r'[ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ]'), 'A');
  str = str.replaceAll(RegExp(r'[ÈÉẸẺẼÊỀẾỆỂỄ]'), 'E');
  str = str.replaceAll(RegExp(r'[ÌÍỊỈĨ]'), 'I');
  str = str.replaceAll(RegExp(r'[ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ]'), 'O');
  str = str.replaceAll(RegExp(r'[ÙÚỤỦŨƯỪỨỰỬỮ]'), 'U');
  str = str.replaceAll(RegExp(r'[ỲÝỴỶỸ]'), 'Y');
  str = str.replaceAll(RegExp(r'[Đ]'), 'D');
  return str;
}

class VSearchableDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuEntry<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool enabled;
  final String? hintText;
  final String? label;

  const VSearchableDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
    this.hintText,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Column(
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
              enabled: enabled,
              initialSelection: value,
              hintText: hintText,
              enableSearch: true,
              enableFilter: true,
              filterCallback: (entries, filter) {
                final normalizedFilter = _removeVietnameseTones(filter).toLowerCase();
                return entries.where((entry) {
                  final normalizedLabel = _removeVietnameseTones(entry.label).toLowerCase();
                  return normalizedLabel.contains(normalizedFilter);
                }).toList();
              },
              requestFocusOnTap: true,
              menuHeight: 300,
              textStyle: VTypography.bodyDefault.copyWith(color: enabled ? colors.textPrimary : colors.textMuted),
              menuStyle: MenuStyle(
                backgroundColor: WidgetStatePropertyAll(colors.surface),
                surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(VRadius.input),
                    side: BorderSide(color: colors.borderDefault),
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: enabled ? colors.surface : colors.surfaceAlt,
                contentPadding: const EdgeInsets.symmetric(horizontal: VSpacing.space3),
                hintStyle: VTypography.bodyDefault.copyWith(color: colors.textMuted),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(VRadius.input),
                  borderSide: BorderSide(color: colors.borderDefault),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(VRadius.input),
                  borderSide: BorderSide(color: colors.borderDefault),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(VRadius.input),
                  borderSide: BorderSide(color: colors.borderStrong),
                ),
                constraints: const BoxConstraints(minHeight: 44, maxHeight: 44),
              ),
              onSelected: onChanged,
              dropdownMenuEntries: items,
            );
          },
        ),
      ],
    );
  }
}
