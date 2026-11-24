import 'package:erp/features/assistant/logic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:c45_design_system/design_system.dart';

const assistantHint = 'Hỏi về doanh thu, tồn kho, công nợ…';
const assistantLockedHint = 'Đã hết lượt hôm nay';

class AssistantComposer extends StatelessWidget {
  const AssistantComposer({
    super.key,
    required this.controller,
    required this.waiting,
    required this.locked,
    required this.onSend,
    this.height = 44,
    this.autofocus = false,
    this.padding = const EdgeInsets.symmetric(horizontal: VSpacing.md, vertical: VSpacing.sm),
  });

  final TextEditingController controller;
  final bool waiting;
  final bool locked;
  final VoidCallback onSend;

  /// Cao ô nhập / cạnh nút gửi: 44 (iPhone), 52 (khung chat web 10-8b).
  final double height;
  final bool autofocus;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.vColors;
    return Container(
      color: c.surface,
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: VTextField(
              controller: controller,
              autofocus: autofocus,
              enabled: !locked,
              hintText: locked ? assistantLockedHint : assistantHint,
              textInputAction: TextInputAction.send,
              inputFormatters: [
                LengthLimitingTextInputFormatter(AskAssistantCubit.maxQuestionLength),
              ],
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: VSpacing.sm),
          SizedBox.square(
            dimension: height,
            child: VButton.icon(
              icon: VIcons.send,
              semanticLabel: 'Gửi',
              onPressed: (waiting || locked) ? null : onSend,
            ),
          ),
        ],
      ),
    );
  }
}
