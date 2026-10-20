import 'package:flutter/material.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';
import '../patterns/v_gap.dart';
import '../primitives/v_text.dart';
import '../primitives/v_icon.dart';
import '../foundations/icons/v_icons.dart';
import '../foundation/v_inspector_scope.dart';

enum VStepStatus { completed, active, inactive }

enum VStepsType { horizontal, list }

class VStepItem {
  final String title;
  final String? subtitle;
  final VStepStatus? status; // Optional override

  const VStepItem({
    required this.title,
    this.subtitle,
    this.status,
  });
}

class VSteps extends StatelessWidget {
  final List<VStepItem> steps;
  final int currentStep;
  final VStepsType type;
  final Axis direction; // Applicable when type is VStepsType.list
  final String? semanticLabel;

  const VSteps({
    super.key,
    required this.steps,
    required this.currentStep,
    this.type = VStepsType.horizontal,
    this.direction = Axis.horizontal,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    VStepStatus getStatus(int index, VStepItem item) {
      if (item.status != null) return item.status!;
      if (index < currentStep) return VStepStatus.completed;
      if (index == currentStep) return VStepStatus.active;
      return VStepStatus.inactive;
    }

    Widget buildCircle(VStepStatus status, int index) {
      final double circleSize = 32.0;

      switch (status) {
        // Done steps recede to a wash + check; the current step is the only
        // solid mark, so the eye lands on where the user is now.
        case VStepStatus.completed:
          return Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              color: dynamicColors.successBg,
              shape: BoxShape.circle,
              border: VBorders.all(dynamicColors.success, width: VBorders.thin),
            ),
            child: Center(
              child: VIcon(
                icon: VIcons.check,
                color: dynamicColors.success,
                size: 16.0,
              ),
            ),
          );
        case VStepStatus.active:
          return Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              color: dynamicColors.success,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: VText(
                '${index + 1}',
                style: VTypography.labelDefault.copyWith(
                  fontWeight: FontWeight.w700,
                  color: dynamicColors.textInverse,
                ),
              ),
            ),
          );
        case VStepStatus.inactive:
          return Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              color: dynamicColors.surfaceAlt,
              shape: BoxShape.circle,
              // Outline keeps upcoming steps visible on a Shelf Gray page.
              border: VBorders.all(dynamicColors.borderStrong, width: VBorders.thin),
            ),
            child: Center(
              child: VText(
                '${index + 1}',
                style: VTypography.labelDefault.copyWith(
                  color: dynamicColors.textSecondary,
                ),
              ),
            ),
          );
      }
    }

    Widget buildHorizontalStep(int index, VStepItem step) {
      final status = getStatus(index, step);
      final isLast = index == steps.length - 1;

      final Color lineAfterColor = index < currentStep
          ? dynamicColors.success
          : dynamicColors.borderDefault;

      final Color lineBeforeColor = index <= currentStep && index > 0
          ? dynamicColors.success
          : dynamicColors.borderDefault;

      final Color titleColor = switch (status) {
        VStepStatus.completed => dynamicColors.textPrimary,
        VStepStatus.active => dynamicColors.success,
        VStepStatus.inactive => dynamicColors.textMuted,
      };

      final titleStyle = VTypography.labelDefault.copyWith(
        fontWeight: status == VStepStatus.active ? FontWeight.w700 : FontWeight.w600,
        color: titleColor,
      );
      final subtitleStyle = VTypography.bodySmall.copyWith(color: dynamicColors.textSecondary);

      return Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 2.0,
                    color: index > 0 ? lineBeforeColor : Colors.transparent,
                  ),
                ),
                buildCircle(status, index),
                Expanded(
                  child: Container(
                    height: 2.0,
                    color: !isLast ? lineAfterColor : Colors.transparent,
                  ),
                ),
              ],
            ),
            const VGap.sm(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: VSpacing.space2),
              child: VText(
                step.title,
                style: titleStyle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (step.subtitle != null) ...[
              const VGap.xs(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: VSpacing.space2),
                child: VText(
                  step.subtitle!,
                  style: subtitleStyle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      );
    }

    Widget buildListHorizontalStep(int index, VStepItem step) {
      final status = getStatus(index, step);
      final isLast = index == steps.length - 1;

      final Color titleColor = switch (status) {
        VStepStatus.completed => dynamicColors.textPrimary,
        VStepStatus.active => dynamicColors.success,
        VStepStatus.inactive => dynamicColors.textMuted,
      };

      final titleStyle = VTypography.labelDefault.copyWith(
        fontWeight: status == VStepStatus.active ? FontWeight.w700 : FontWeight.w600,
        color: titleColor,
      );
      final subtitleStyle = VTypography.bodySmall.copyWith(color: dynamicColors.textSecondary);

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildCircle(status, index),
          const VGap.horizontalSm(),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VText(
                step.title,
                style: titleStyle,
              ),
              if (step.subtitle != null) ...[
                const VGap.xs(),
                VText(
                  step.subtitle!,
                  style: subtitleStyle,
                ),
              ],
            ],
          ),
          if (!isLast) const SizedBox(width: VSpacing.space6),
        ],
      );
    }

    Widget buildListVerticalStep(int index, VStepItem step) {
      final status = getStatus(index, step);
      final isLast = index == steps.length - 1;

      final Color titleColor = switch (status) {
        VStepStatus.completed => dynamicColors.textPrimary,
        VStepStatus.active => dynamicColors.success,
        VStepStatus.inactive => dynamicColors.textMuted,
      };

      final Color lineColor = index < currentStep
          ? dynamicColors.success
          : dynamicColors.borderDefault;

      final titleStyle = VTypography.labelDefault.copyWith(
        fontWeight: status == VStepStatus.active ? FontWeight.w700 : FontWeight.w600,
        color: titleColor,
      );
      final subtitleStyle = VTypography.bodySmall.copyWith(color: dynamicColors.textSecondary);

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildCircle(status, index),
                  if (!isLast)
                    Container(
                      width: 2.0,
                      height: 24.0,
                      color: lineColor,
                    ),
                ],
              ),
              const VGap.horizontalMd(),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6.0), // Align with circle center
                    VText(
                      step.title,
                      style: titleStyle,
                    ),
                    if (step.subtitle != null) ...[
                      const VGap.xs(),
                      VText(
                        step.subtitle!,
                        style: subtitleStyle,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (!isLast) const SizedBox(height: VSpacing.space2),
        ],
      );
    }

    Widget content;
    if (type == VStepsType.horizontal) {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          steps.length,
          (index) => buildHorizontalStep(index, steps[index]),
        ),
      );
    } else {
      if (direction == Axis.horizontal) {
        content = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(
              steps.length,
              (index) => buildListHorizontalStep(index, steps[index]),
            ),
          ),
        );
      } else {
        content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            steps.length,
            (index) => buildListVerticalStep(index, steps[index]),
          ),
        );
      }
    }

    return vInspectorHide(
      Semantics(
        label: semanticLabel ?? 'Các bước tiến trình',
        explicitChildNodes: true,
        child: content,
      ),
    );
  }
}
