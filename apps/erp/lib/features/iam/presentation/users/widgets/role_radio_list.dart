import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

class RoleChoice {
  const RoleChoice({
    required this.id,
    required this.title,
    required this.description,
    this.isCurrent = false,
  });

  final String id;
  final String title;
  final String description;
  final bool isCurrent;
}

class RoleRadioList extends StatelessWidget {
  const RoleRadioList({
    super.key,
    required this.roles,
    required this.value,
    required this.onChanged,
    this.invalid = false,
    this.header,
  });

  final List<RoleChoice> roles;
  final String? value;
  final ValueChanged<String>? onChanged;
  final bool invalid;

  /// Tiêu đề trong thẻ (`.t1-rolelist__legend`: đệm 16 / 16 / 4), không gạch dưới.
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final enabled = onChanged != null;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: Border.all(
          color: invalid ? colors.danger : colors.borderStrong,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: RadioGroup<String>(
        groupValue: value,
        onChanged: (next) {
          if (enabled && next != null) {
            onChanged!(next);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VSpacing.space4,
                  VSpacing.space4,
                  VSpacing.space4,
                  VSpacing.space1,
                ),
                child: header,
              ),
            for (var i = 0; i < roles.length; i++) ...[
              if (i > 0) Divider(height: 1, color: colors.borderDefault),
              _RoleListTile(
                choice: roles[i],
                isSelected: !roles[i].isCurrent && roles[i].id == value,
                enabled: enabled,
                onTap: enabled && !roles[i].isCurrent
                    ? () => onChanged!(roles[i].id)
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoleListTile extends StatelessWidget {
  const _RoleListTile({
    required this.choice,
    required this.isSelected,
    required this.enabled,
    this.onTap,
  });

  final RoleChoice choice;
  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final bg = choice.isCurrent
        ? colors.surfaceAlt
        : (isSelected ? colors.surfaceBrand : Colors.transparent);

    return Material(
      color: bg,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.space4,
              vertical: VSpacing.space2,
            ),
            child: Row(
              children: [
                if (!choice.isCurrent) ...[
                  Radio<String>(
                    value: choice.id,
                    enabled: enabled,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: VSpacing.space3),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VText(
                        choice.title,
                        variant: VTextVariant.bodyDefault,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (choice.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        VText(
                          choice.description,
                          variant: VTextVariant.bodySmall,
                          color: colors.textSecondary,
                        ),
                      ],
                    ],
                  ),
                ),
                if (choice.isCurrent) ...[
                  const SizedBox(width: VSpacing.space2),
                  const VBadge(
                    label: 'Hiện tại',
                    tone: VComponentTone.success,
                    variant: VBadgeVariant.soft,
                    isSmall: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
