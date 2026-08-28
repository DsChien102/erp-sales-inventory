import 'package:flutter/material.dart';
// contract: na tone/emphasis; optional invalid via VField

import '../foundation/v_component_scope.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_inspector_scope.dart';
import '../primitives/v_text.dart';
import 'v_gap.dart';

/// Ambient invalid flag for field chrome (e.g. future control cascade).
class _VFieldAncestry extends InheritedWidget {
  const _VFieldAncestry({
    required this.invalid,
    required super.child,
  });

  final bool invalid;

  @override
  bool updateShouldNotify(covariant _VFieldAncestry oldWidget) {
    return invalid != oldWidget.invalid;
  }
}

void _requireField(BuildContext context, {required String widgetName}) {
  requireAncestor<_VFieldAncestry>(
    context,
    widgetName: widgetName,
    ancestorName: 'VField',
  );
}

/// Form field shell (shadcn Field): label + control child + description/error.
///
/// Prefer composition — put the input directly as a child (no control wrapper):
/// ```dart
/// VField(
///   invalid: error != null,
///   child: Column(
///     crossAxisAlignment: CrossAxisAlignment.start,
///     children: [
///       VFieldLabel('Email', isRequired: true),
///       VTextField(hintText: '...'),
///       if (error != null)
///         VFieldError(error!)
///       else
///         const VFieldDescription('Helper'),
///     ],
///   ),
/// )
/// ```
class VField extends StatelessWidget {
  const VField({
    super.key,
    required this.child,
    this.invalid = false,
  });

  final Widget child;

  /// Ambient invalid flag (callers should pair with [VFieldError]).
  final bool invalid;

  @override
  Widget build(BuildContext context) {
    return vInspectorHide(
      _VFieldAncestry(
        invalid: invalid,
        child: vInspectorShow(child),
      ),
    );
  }
}

/// Label row above the control (shadcn FieldLabel).
class VFieldLabel extends StatelessWidget {
  const VFieldLabel(
    this.text, {
    super.key,
    this.isRequired = false,
  });

  final String text;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    _requireField(context, widgetName: 'VFieldLabel');
    final colors = context.vColors;

    return vInspectorHide(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              VText(
                text,
                variant: VTextVariant.headingH4,
                color: colors.textPrimary,
              ),
              if (isRequired)
                VText(
                  ' *',
                  variant: VTextVariant.headingH4,
                  color: colors.danger,
                ),
            ],
          ),
          const VGap.sm(),
        ],
      ),
    );
  }
}

/// Helper text below the control (shadcn FieldDescription).
class VFieldDescription extends StatelessWidget {
  const VFieldDescription(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    _requireField(context, widgetName: 'VFieldDescription');
    final colors = context.vColors;

    return vInspectorHide(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const VGap.sm(),
          VText(
            text,
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
          ),
        ],
      ),
    );
  }
}

/// Error text below the control (danger styling).
class VFieldError extends StatelessWidget {
  const VFieldError(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    _requireField(context, widgetName: 'VFieldError');
    final colors = context.vColors;

    return vInspectorHide(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const VGap.sm(),
          VText(
            text,
            variant: VTextVariant.bodySmall,
            color: colors.danger,
          ),
        ],
      ),
    );
  }
}

/// Legacy flat bridge: label + control + description/error (error wins helper).
///
/// Used by deprecated flat props on [VTextField] and siblings.
Widget vFieldShell({
  Key? key,
  required Widget control,
  String? label,
  bool isRequired = false,
  String? helperText,
  String? errorText,
}) {
  final hasError = errorText != null;

  return VField(
    key: key,
    invalid: hasError,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) VFieldLabel(label, isRequired: isRequired),
        control,
        if (hasError)
          VFieldError(errorText)
        else if (helperText != null)
          VFieldDescription(helperText),
      ],
    ),
  );
}
