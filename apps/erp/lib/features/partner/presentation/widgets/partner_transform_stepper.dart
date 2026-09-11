import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class PartnerTransformStepper extends StatelessWidget {
  const PartnerTransformStepper({super.key, this.currentStep = 1});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _TransformStep(
              number: 1,
              label: 'Thông tin tổ chức',
              isActive: currentStep == 1,
              isComplete: currentStep > 1,
            ),
          ),
          const _StepConnector(key: Key('transform_step_connector_1')),
          Expanded(
            child: _TransformStep(
              number: 2,
              label: 'Xem trước',
              isActive: currentStep == 2,
              isComplete: currentStep > 2,
            ),
          ),
          const _StepConnector(key: Key('transform_step_connector_2')),
          Expanded(
            child: _TransformStep(
              number: 3,
              label: 'Xác nhận',
              isActive: currentStep == 3,
              isComplete: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 15),
        child: Container(height: 1, color: context.vColors.borderDefault),
      ),
    );
  }
}

class _TransformStep extends StatelessWidget {
  const _TransformStep({
    required this.number,
    required this.label,
    required this.isActive,
    required this.isComplete,
  });

  final int number;
  final String label;
  final bool isActive;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final highlighted = isActive || isComplete;
    final accent = highlighted ? colors.success : colors.textMuted;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: highlighted ? colors.success : colors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: highlighted ? colors.success : colors.borderDefault,
              width: 2,
            ),
          ),
          child: VText(
            '$number',
            variant: VTextVariant.bodyDefault,
            color: highlighted ? colors.surface : colors.textSecondary,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: VSpacing.space2),
        VText(
          label,
          maxLines: 2,
          textAlign: TextAlign.center,
          style: VTypography.bodySmall.copyWith(
            color: accent,
            fontSize: 11,
            fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
