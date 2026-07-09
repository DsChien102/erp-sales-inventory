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
      _selectedOptionIds[opt.fieldId] = existing?.optionId;
    }
  }

  List<CustomFieldFilterCriteria> _buildCriteria() {
    return _selectedOptionIds.entries
        .where((e) => e.value != null)
        .map((e) => CustomFieldFilterCriteria(fieldId: e.key, optionId: e.value))
        .toList();
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
                child: OutlinedButton(
                  key: const Key('btn_filter_reset'),
                  onPressed: () {
                    setState(() {
                      for (final key in _selectedOptionIds.keys.toList()) {
                        _selectedOptionIds[key] = null;
                      }
                    });
                    Navigator.of(context).pop();
                    widget.onApply([]);
                  },
                  child: const Text('Bỏ lọc'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  key: const Key('btn_filter_apply'),
                  style: FilledButton.styleFrom(backgroundColor: colors.primary),
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onApply(_buildCriteria());
                  },
                  child: Text(
                    'Áp dụng',
                    style: TextStyle(color: colors.surface),
                  ),
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
          children: opt.options.map((option) {
            final isSelected = _selectedOptionIds[opt.fieldId] == option.optionId;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedOptionIds[opt.fieldId] = isSelected ? null : option.optionId;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? colors.primary : colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected ? null : Border.all(color: colors.borderDefault),
                ),
                child: Text(
                  option.label,
                  style: VTypography.bodySmall.copyWith(
                    color: isSelected ? Colors.white : colors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
