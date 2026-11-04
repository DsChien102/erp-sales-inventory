import 'package:flutter/material.dart';
import '../../data/models.dart';
import 'package:vet45_design_system/design_system.dart';

/// Bottom sheet content cho phép chọn option single-select per custom field.
///
/// Được sử dụng bởi [ProductCatalogTabPage] qua [showVAdaptiveSheet].
class CustomFieldFilterSheet extends StatefulWidget {
  const CustomFieldFilterSheet({
    super.key,
    required this.options,
    required this.initialFilters,
    required this.onApply,
  });

  final List<CustomFieldFilterOptionDto> options;
  final List<CustomFieldFilterCriteria> initialFilters;
  final ValueChanged<List<CustomFieldFilterCriteria>> onApply;

  @override
  State<CustomFieldFilterSheet> createState() => _CustomFieldFilterSheetState();
}

class _CustomFieldFilterSheetState extends State<CustomFieldFilterSheet> {
  late final Map<String, String?> _selectedOptionIds;

  @override
  void initState() {
    super.initState();
    _selectedOptionIds = {};
    for (final opt in widget.options) {
      final existing = widget.initialFilters.where((f) => f.fieldId == opt.fieldId).firstOrNull;
      if (opt.fieldType == 'boolean') {
        if (existing?.booleanValue != null) {
          _selectedOptionIds[opt.fieldId] = existing!.booleanValue!.toString();
        } else {
          _selectedOptionIds[opt.fieldId] = null;
        }
      } else {
        _selectedOptionIds[opt.fieldId] = existing?.optionId;
      }
    }
  }

  List<CustomFieldFilterCriteria> _buildCriteria() {
    final criteriaList = <CustomFieldFilterCriteria>[];
    for (final opt in widget.options) {
      final selectedValue = _selectedOptionIds[opt.fieldId];
      if (selectedValue == null) {
        continue;
      }
      if (opt.fieldType == 'boolean') {
        criteriaList.add(
          CustomFieldFilterCriteria(
            fieldId: opt.fieldId,
            booleanValue: selectedValue == 'true',
          ),
        );
      } else {
        criteriaList.add(
          CustomFieldFilterCriteria(
            fieldId: opt.fieldId,
            optionId: selectedValue,
          ),
        );
      }
    }
    return criteriaList;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.options.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: VText(
                  'Chưa có thuộc tính mở rộng nào.',
                  variant: VTextVariant.bodyDefault,
                  color: colors.textSecondary,
                ),
              ),
            )
          else
            ...widget.options.map((opt) => _buildFieldFilter(colors, opt)),
          const SizedBox(height: VSpacing.space4),
          Row(
            children: [
              Expanded(
                child: VButton(
                  key: const Key('btn_filter_reset'),
                  label: 'Bỏ lọc',
                  variant: VButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: () {
                    setState(() {
                      for (final key in _selectedOptionIds.keys.toList()) {
                        _selectedOptionIds[key] = null;
                      }
                    });
                    Navigator.of(context).pop();
                    widget.onApply([]);
                  },
                ),
              ),
              const SizedBox(width: VSpacing.space3),
              Expanded(
                child: VButton(
                  key: const Key('btn_filter_apply'),
                  label: 'Áp dụng',
                  variant: VButtonVariant.primary,
                  fullWidth: true,
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onApply(_buildCriteria());
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.space4),
        ],
      ),
    );
  }

  Widget _buildFieldFilter(dynamic colors, CustomFieldFilterOptionDto opt) {
    final List<Map<String, String>> displayOptions = opt.fieldType == 'boolean'
        ? [
            {'id': 'true', 'label': 'Có'},
            {'id': 'false', 'label': 'Không'},
          ]
        : opt.options.map((o) => {'id': o.optionId, 'label': o.label}).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: VSpacing.space3),
        VText(
          opt.fieldName,
          variant: VTextVariant.headingH4,
          color: colors.textPrimary,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: VSpacing.space2),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: displayOptions.map((option) {
            final optionId = option['id']!;
            final optionLabel = option['label']!;
            final isSelected = _selectedOptionIds[opt.fieldId] == optionId;
            return VChip(
              label: optionLabel,
              selected: isSelected,
              emphasis: VComponentEmphasis.medium,
              tone: VComponentTone.primary,
              onTap: () {
                setState(() {
                  _selectedOptionIds[opt.fieldId] = isSelected ? null : optionId;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
