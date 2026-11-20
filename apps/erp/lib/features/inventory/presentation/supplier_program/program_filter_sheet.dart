import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

class ProgramFilterItem {
  final String id;
  final String label;
  final String? subtitle;

  const ProgramFilterItem({
    required this.id,
    required this.label,
    this.subtitle,
  });
}

Future<String?> showProgramFilterSheet({
  required BuildContext context,
  required String title,
  required List<ProgramFilterItem> items,
  required String? selectedId,
}) async {
  var picked = false;
  String? result;

  await showVAdaptiveSheet<void>(
    context: context,
    title: title,
    child: _ProgramFilterSheetBody(
      items: items,
      selectedId: selectedId,
      onSelected: (id) {
        picked = true;
        result = id;
        Navigator.of(context).pop();
      },
    ),
  );

  return picked ? (result ?? '') : null;
}

class _ProgramFilterSheetBody extends StatefulWidget {
  final List<ProgramFilterItem> items;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const _ProgramFilterSheetBody({
    required this.items,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  State<_ProgramFilterSheetBody> createState() =>
      _ProgramFilterSheetBodyState();
}

class _ProgramFilterSheetBodyState extends State<_ProgramFilterSheetBody> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalized = VTextNormalizer.normalizeForSearch(_query.trim());
    final filtered = widget.items.where((item) {
      if (normalized.isEmpty) return true;
      final hay = VTextNormalizer.normalizeForSearch(
        '${item.label} ${item.subtitle ?? ''}',
      );
      return hay.contains(normalized);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VSearchBar(
            controller: _searchController,
            hintText: 'Tìm kiếm',
            onChanged: (v) => setState(() => _query = v),
            onClear: () => setState(() => _query = ''),
          ),
          const SizedBox(height: VSpacing.space3),
          VListRow(
            title: 'Tất cả',
            type: VListRowType.selection,
            selected: widget.selectedId == null,
            onTap: () => widget.onSelected(null),
          ),
          for (final item in filtered)
            VListRow(
              title: item.label,
              subtitle: item.subtitle,
              type: VListRowType.selection,
              selected: widget.selectedId == item.id,
              onTap: () => widget.onSelected(item.id),
            ),
        ],
      ),
    );
  }
}

