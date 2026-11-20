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
  });

  final TextEditingController controller;
  final bool waiting;
  final bool locked;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final c = context.vColors;
    return Container(
      color: c.surface,
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.md, vertical: VSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: VTextField(
              controller: controller,
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
          VButton.icon(
            icon: VIcons.send,
            semanticLabel: 'Gửi',
            onPressed: (waiting || locked) ? null : onSend,
          ),
        ],
      ),
    );
  }
}
