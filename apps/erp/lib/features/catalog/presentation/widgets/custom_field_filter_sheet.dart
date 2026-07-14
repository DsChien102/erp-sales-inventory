import 'package:flutter/material.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_design_system/design_system.dart';

/// Bottom sheet content cho phép chọn option single-select per custom field.
///
/// Được sử dụng bởi [ProductCatalogTabPage] qua [showVBottomSheet].
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
                child: Text(
                  'Chưa có thuộc tính mở rộng nào.',
                  style: VTypography.bodyDefault.copyWith(color: colors.textSecondary),
                ),
              ),
            )
          else
            ...widget.options.map((opt) => _buildFieldFilter(colors, opt)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: VButton(
                  key: const Key('btn_filter_reset'),
                  label: 'Bỏ lọc',
                  variant: VButtonVariant.outline,
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
              const SizedBox(width: 12),
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
          const SizedBox(height: 16),
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
        : opt.options
            .map((o) => {'id': o.optionId, 'label': o.label})
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          opt.fieldName,
          style: VTypography.headingH4.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
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
              emphasis: VChipEmphasis.base,
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
