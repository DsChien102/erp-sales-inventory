import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

Future<List<String>?> showProgramProductPickerSheet({
  required BuildContext context,
  required List<ProductOption> products,
  required List<String> selectedIds,
  required bool allowMultiple,
}) {
  return showVAdaptiveSheet<List<String>>(
    context: context,
    title: 'Chọn sản phẩm',
    child: _ProgramProductPickerBody(
      products: products,
      initialSelectedIds: selectedIds,
      allowMultiple: allowMultiple,
    ),
  );
}

class _ProgramProductPickerBody extends StatefulWidget {
  final List<ProductOption> products;
  final List<String> initialSelectedIds;
  final bool allowMultiple;

  const _ProgramProductPickerBody({
    required this.products,
    required this.initialSelectedIds,
    required this.allowMultiple,
  });

  @override
  State<_ProgramProductPickerBody> createState() =>
      _ProgramProductPickerBodyState();
}

class _ProgramProductPickerBodyState extends State<_ProgramProductPickerBody> {
  final TextEditingController _searchController = TextEditingController();
  late final Set<String> _selectedIds;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = {...widget.initialSelectedIds};
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggle(String productId) {
    if (!widget.allowMultiple) {
      Navigator.of(context).pop(<String>[productId]);
      return;
    }
    setState(() {
      if (_selectedIds.contains(productId)) {
        _selectedIds.remove(productId);
      } else {
        _selectedIds.add(productId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final normalized = VTextNormalizer.normalizeForSearch(_query.trim());
    final filtered = widget.products.where((p) {
      if (normalized.isEmpty) return true;
      final hay = VTextNormalizer.normalizeForSearch('${p.name} ${p.code}');
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
            hintText: 'Tìm sản phẩm',
            onChanged: (v) => setState(() => _query = v),
            onClear: () => setState(() => _query = ''),
          ),
          const SizedBox(height: VSpacing.space3),
          for (final p in filtered)
            VListRow(
              title: p.name,
              subtitle: '${p.code} · ${p.baseUom}',
              type: VListRowType.selection,
              selected: _selectedIds.contains(p.productId),
              trailing: widget.allowMultiple
                  ? VCheckbox(
                      value: _selectedIds.contains(p.productId),
                      onChanged: (_) => _toggle(p.productId),
                    )
                  : null,
              onTap: () => _toggle(p.productId),
            ),
          if (widget.allowMultiple) ...[
            const SizedBox(height: VSpacing.space4),
            VButton(
              label: 'Xong',
              variant: VButtonVariant.primary,
              fullWidth: true,
              onPressed: () {
                final ordered = [
                  for (final p in widget.products)
                    if (_selectedIds.contains(p.productId)) p.productId,
                ];
                Navigator.of(context).pop(ordered);
              },
            ),
          ],
        ],
      ),
    );
  }
}

