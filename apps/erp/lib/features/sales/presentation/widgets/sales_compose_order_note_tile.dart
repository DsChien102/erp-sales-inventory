import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

/// Ghi chú đơn hàng (SG-02):
/// - Mặc định: vcard tóm tắt — "Chưa có ghi chú" / nội dung đã nhập.
/// - Chạm header → bung/thu [VTextArea] (không bottom sheet).
class SalesComposeOrderNoteTile extends StatefulWidget {
  const SalesComposeOrderNoteTile({
    super.key,
    required this.note,
    required this.onChanged,
  });

  final String? note;
  final ValueChanged<String> onChanged;

  @override
  State<SalesComposeOrderNoteTile> createState() => _SalesComposeOrderNoteTileState();
}

class _SalesComposeOrderNoteTileState extends State<SalesComposeOrderNoteTile> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _expanded = false;

  String get _preview {
    final note = widget.note?.trim();
    if (note == null || note.isEmpty) return 'Chưa có ghi chú';
    return note;
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note ?? '');
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant SalesComposeOrderNoteTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.note ?? '';
    if (widget.note != oldWidget.note && next != _controller.text) {
      _controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _collapse() {
    if (!_expanded) return;
    _focusNode.unfocus();
    setState(() => _expanded = false);
  }

  void _expand() {
    if (_expanded) return;
    setState(() => _expanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _onHeaderTap() {
    if (_expanded) {
      _collapse();
    } else {
      _expand();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    // Không dùng VCard(onTap) — InkWell cha nuốt gesture, khó thu card.
    return VCard(
      key: const Key('card_compose_order_note'),
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: const Key('btn_compose_order_note'),
            onTap: _onHeaderTap,
            child: VCardHeader(
              padding: const EdgeInsets.all(VSpacing.md),
              title: VCardTitle(
                'Ghi chú đơn hàng',
                description: !_expanded ? _preview : null,
              ),
              action: VCardAction(
                child: AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: VIcon(
                    icon: VIcons.chevronDown,
                    size: 20,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          if (_expanded) ...[
            const VDivider(),
            const VGap.md(),
            VCardContent(
              child: VTextArea(
                key: const Key('input_compose_order_note'),
                controller: _controller,
                focusNode: _focusNode,
                hintText: 'VD: Giao trước 16:00',
                minLines: 3,
                maxLines: 5,
                maxLength: 500,
                showCounter: true,
                onChanged: widget.onChanged,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
