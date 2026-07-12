import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../data/vn_administrative_unit.dart';
import 'partner_compact_field.dart';

class PartnerWardSearchDropdown extends StatefulWidget {
  const PartnerWardSearchDropdown({
    super.key,
    required this.value,
    required this.wards,
    required this.enabled,
    required this.hintText,
    required this.onSelected,
  });

  final String value;
  final List<VnWard> wards;
  final bool enabled;
  final String hintText;
  final ValueChanged<VnWard> onSelected;

  @override
  State<PartnerWardSearchDropdown> createState() => _PartnerWardSearchDropdownState();
}

class _PartnerWardSearchDropdownState extends State<PartnerWardSearchDropdown> {
  final MenuController _menuController = MenuController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode(
    debugLabel: 'PartnerWardInlineSearch',
  );
  String _query = '';

  List<VnWard> get _filteredWards {
    final query = _normalize(_query.trim());
    if (query.isEmpty) return widget.wards;
    return widget.wards
        .where((ward) => _normalize(ward.fullName).contains(query))
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _textController.text = widget.value;
  }

  @override
  void didUpdateWidget(covariant PartnerWardSearchDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && !_inputFocusNode.hasFocus) {
      _textController.text = widget.value;
    }
  }

  void _handleInputTap() {
    if (_textController.text.isNotEmpty) {
      _textController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _textController.text.length,
      );
    }
  }

  void _handleQueryChanged(String value) {
    setState(() => _query = value);
    if (!_menuController.isOpen) _menuController.open();
  }

  Future<void> _toggleMenuFromArrow() async {
    if (!widget.enabled) return;
    _inputFocusNode.unfocus();
    if (_menuController.isOpen) {
      _menuController.close();
      return;
    }
    await PartnerCompactField.ensureMenuOpensDownward(context);
    if (mounted) _menuController.open();
  }

  void _select(VnWard ward) {
    _textController.text = ward.fullName;
    _query = '';
    widget.onSelected(ward);
    _menuController.close();
    _inputFocusNode.unfocus();
  }

  void _restoreSelectedValue() {
    if (_query.isEmpty) return;
    _query = '';
    _textController.text = widget.value;
  }

  @override
  void dispose() {
    _textController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return LayoutBuilder(
      builder: (context, constraints) => MenuAnchor(
        controller: _menuController,
        crossAxisUnconstrained: false,
        alignmentOffset: PartnerCompactField.menuAlignmentOffset,
        onClose: _restoreSelectedValue,
        style: MenuStyle(
          alignment: PartnerCompactField.menuAlignment,
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          minimumSize: WidgetStatePropertyAll(Size(constraints.maxWidth, 0)),
          maximumSize: WidgetStatePropertyAll(
            Size(constraints.maxWidth, PartnerCompactField.menuHeight),
          ),
          backgroundColor: WidgetStatePropertyAll(colors.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(VRadius.input),
              side: BorderSide(color: colors.borderDefault),
            ),
          ),
        ),
        menuChildren: [
          SizedBox(
            width: constraints.maxWidth,
            height: PartnerCompactField.menuHeight,
            child: _filteredWards.isEmpty
                ? Center(
                    child: Text(
                      'Không tìm thấy xã/phường phù hợp',
                      style: VTypography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    primary: false,
                    padding: EdgeInsets.zero,
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: _filteredWards.length,
                    itemBuilder: (context, index) {
                      final ward = _filteredWards[index];
                      return MenuItemButton(
                        onPressed: () => _select(ward),
                        child: Text(ward.fullName),
                      );
                    },
                  ),
          ),
        ],
        builder: (context, controller, child) => SizedBox(
          height: PartnerCompactField.controlHeight,
          width: double.infinity,
          child: DecoratedBox(
            decoration: PartnerCompactField.decoration(
              context,
              enabled: widget.enabled,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Listener(
                    onPointerDown: (_) => _handleInputTap(),
                    child: VTextField(
                      key: const Key('input_ward_inline_search'),
                      controller: _textController,
                      focusNode: _inputFocusNode,
                      enabled: widget.enabled,
                      hintText: widget.hintText,
                      variant: VTextFieldVariant.inline,
                      textStyle: PartnerCompactField.valueStyle(context),
                      contentPadding: PartnerCompactField.contentPadding,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      onChanged: _handleQueryChanged,
                      onSubmitted: (_) {
                        if (_filteredWards.length == 1) {
                          _select(_filteredWards.single);
                        }
                      },
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('btn_ward_dropdown'),
                  onPressed: widget.enabled ? _toggleMenuFromArrow : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 40),
                  icon: Icon(
                    controller.isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18,
                    color: widget.enabled ? colors.textSecondary : colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
      .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
      .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
      .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
      .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
      .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
      .replaceAll('đ', 'd');
}
