import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

const assistantGreeting = 'Chào bạn! Mình giúp bạn xem nhanh số liệu cửa hàng. Thử hỏi:';
const assistantSuggestions = <String>[
  'Hôm nay bán được bao nhiêu?',
  'Hàng nào sắp hết, nên nhập bao nhiêu?',
  'Khách nào đang nợ?',
  '5 mặt hàng bán chạy tháng này?',
];

class AssistantSuggestions extends StatelessWidget {
  const AssistantSuggestions({super.key, required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.vColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VText(assistantGreeting, color: c.textSecondary),
        const SizedBox(height: VSpacing.cozy),
        for (final s in assistantSuggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: VSpacing.sm),
            child: InkWell(
              borderRadius: BorderRadius.circular(VRadius.pill),
              onTap: () => onPick(s),
              child: Container(
                constraints: const BoxConstraints(minHeight: VSpacing.minTouchTarget),
                padding: const EdgeInsets.symmetric(
                  horizontal: VSpacing.md,
                  vertical: VSpacing.sm,
                ),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border.all(color: c.borderInput),
                  borderRadius: BorderRadius.circular(VRadius.pill),
                ),
                child: VText(s),
              ),
            ),
          ),
      ],
    );
  }
}
