import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class K2Pending extends StatelessWidget {
  const K2Pending({
    super.key,
    required this.approver,
    required this.sentAt,
    this.facts = const [],
    this.subject = '',
  });

  final String approver;
  final String sentAt;
  final List<VKeyValueRow> facts;
  final String subject;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final subjectPart = subject.isNotEmpty ? ' $subject' : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        VBanner(
          tone: VComponentTone.info,
          title: 'Đang chờ duyệt',
          description: 'Chờ $approver duyệt$subjectPart · gửi $sentAt',
        ),
        if (facts.isNotEmpty) ...[
          const SizedBox(height: VSpacing.space3),
          VKeyValueGroup(
            title: 'Yêu cầu',
            rows: facts,
          ),
        ],
        const SizedBox(height: VSpacing.space2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: VSpacing.space3),
          child: Text(
            'Dữ liệu đã khoá. Tồn kho chưa thay đổi.',
            style: VTypography.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

enum K2AttentionTone {
  warning,
  info,
}

class K2AttentionItem {
  const K2AttentionItem({
    required this.label,
    required this.value,
    this.tone = K2AttentionTone.warning,
  });

  final String label;
  final String value;
  final K2AttentionTone tone;
}

class K2Attention extends StatelessWidget {
  const K2Attention({
    super.key,
    required this.items,
    this.title = 'Cần chú ý',
  });

  final List<K2AttentionItem> items;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final colors = context.vColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: VBorders.all(colors.borderDefault),
      ),
      padding: const EdgeInsets.all(VSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title.isNotEmpty) ...[
            VText(
              title,
              variant: VTextVariant.headingH4,
              color: colors.textPrimary,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: VSpacing.space2),
          ],
          for (var i = 0; i < items.length; i++) ...[
            _buildItem(items[i], colors),
            if (i < items.length - 1) const SizedBox(height: VSpacing.space2),
          ],
        ],
      ),
    );
  }

  Widget _buildItem(K2AttentionItem item, VColorScheme colors) {
    final cleanLabel = item.label.endsWith(':')
        ? item.label.substring(0, item.label.length - 1)
        : item.label;

    final icon = item.tone == K2AttentionTone.warning
        ? VIcons.warning
        : VIcons.info;
    final iconColor = item.tone == K2AttentionTone.warning
        ? colors.warning
        : colors.info;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VIcon(
          icon: icon,
          size: 18,
          color: iconColor,
        ),
        const SizedBox(width: VSpacing.space2),
        Expanded(
          child: Row(
            children: [
              Text(
                cleanLabel,
                style: VTypography.bodyDefault.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: VSpacing.space2),
              Expanded(
                child: Text(
                  item.value,
                  style: VTypography.bodyDefault.copyWith(
                    color: item.tone == K2AttentionTone.warning
                        ? colors.warning
                        : colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class K2Decision extends StatelessWidget {
  const K2Decision({
    super.key,
    required this.question,
    required this.maker,
    required this.sentAt,
    this.attention = const [],
    this.facts = const [],
    this.detail,
  });

  final String question;
  final String maker;
  final String sentAt;
  final List<K2AttentionItem> attention;
  final List<VKeyValueRow> facts;
  final Widget? detail;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        VText(
          'Cần quyết',
          variant: VTextVariant.headingH3,
          color: colors.textPrimary,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: VSpacing.space1),
        VText(
          question,
          variant: VTextVariant.headingH4,
          color: colors.textPrimary,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: VSpacing.space1),
        VText(
          '$maker gửi $sentAt',
          variant: VTextVariant.bodySmall,
          color: colors.textSecondary,
        ),
        if (attention.isNotEmpty) ...[
          const SizedBox(height: VSpacing.space3),
          K2Attention(items: attention),
        ],
        if (facts.isNotEmpty) ...[
          const SizedBox(height: VSpacing.space3),
          VKeyValueGroup(rows: facts),
        ],
        if (detail != null) ...[
          const SizedBox(height: VSpacing.space3),
          detail!,
        ],
      ],
    );
  }
}

Future<String?> showK2ReasonSheet(
  BuildContext context, {
  required String title,
  String description = '',
  String reasonLabel = 'Lý do từ chối',
  String placeholder = 'Nhập nội dung người lập cần sửa',
  String closeLabel = 'Hủy',
  String confirmLabel = 'Xác nhận từ chối',
  bool withReason = true,
  bool danger = false,
}) {
  return showVAdaptiveSheet<String>(
    context: context,
    title: title,
    child: _K2ReasonSheetBody(
      description: description,
      reasonLabel: reasonLabel,
      placeholder: placeholder,
      closeLabel: closeLabel,
      confirmLabel: confirmLabel,
      withReason: withReason,
      danger: danger,
    ),
  );
}

class _K2ReasonSheetBody extends StatefulWidget {
  const _K2ReasonSheetBody({
    required this.description,
    required this.reasonLabel,
    required this.placeholder,
    required this.closeLabel,
    required this.confirmLabel,
    required this.withReason,
    required this.danger,
  });

  final String description;
  final String reasonLabel;
  final String placeholder;
  final String closeLabel;
  final String confirmLabel;
  final bool withReason;
  final bool danger;

  @override
  State<_K2ReasonSheetBody> createState() => _K2ReasonSheetBodyState();
}

class _K2ReasonSheetBodyState extends State<_K2ReasonSheetBody> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final text = _controller.text;
    final canConfirm = !widget.withReason || text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(VSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.description.isNotEmpty) ...[
            Text(
              widget.description,
              style: VTypography.bodyDefault.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: VSpacing.space3),
          ],
          if (widget.withReason) ...[
            VField(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  VFieldLabel(widget.reasonLabel),
                  const SizedBox(height: VSpacing.space1),
                  VTextField(
                    controller: _controller,
                    hintText: widget.placeholder,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            const SizedBox(height: VSpacing.space4),
          ],
          Row(
            children: [
              Expanded(
                child: VButton(
                  label: widget.closeLabel,
                  variant: VButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop(null),
                ),
              ),
              const SizedBox(width: VSpacing.space2),
              Expanded(
                child: VButton(
                  label: widget.confirmLabel,
                  tone: widget.danger ? VComponentTone.danger : null,
                  onPressed: canConfirm
                      ? () => Navigator.of(context).pop(_controller.text.trim())
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
