import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Shared confirm body for membership lifecycle sheets.
class MembershipLifecycleConfirmSheet extends StatefulWidget {
  const MembershipLifecycleConfirmSheet({
    super.key,
    required this.title,
    required this.description,
    required this.confirmLabel,
    required this.onConfirm,
    this.titleDanger = false,
    this.confirmDanger = false,
  });

  final String title;
  final String description;
  final String confirmLabel;
  final Future<bool> Function() onConfirm;
  final bool titleDanger;
  final bool confirmDanger;

  @override
  State<MembershipLifecycleConfirmSheet> createState() =>
      _MembershipLifecycleConfirmSheetState();
}

class _MembershipLifecycleConfirmSheetState
    extends State<MembershipLifecycleConfirmSheet> {
  bool _submitting = false;

  Future<void> _confirm() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final ok = await widget.onConfirm();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Padding(
      padding: const EdgeInsets.only(
        left: VSpacing.space4,
        right: VSpacing.space4,
        top: VSpacing.space2,
        bottom: VSpacing.space6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VText(
            widget.title,
            variant: VTextVariant.headingH3,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: widget.titleDanger ? colors.danger : colors.textPrimary,
            ),
          ),
          const VGap.xs(),
          VText(
            widget.description,
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
          ),
          const VGap.xl(),
          VButton(
            label: 'Quay lại',
            variant: VButtonVariant.outline,
            tone: VComponentTone.neutral,
            fullWidth: true,
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          ),
          const VGap.sm(),
          VButton(
            label: widget.confirmLabel,
            variant: widget.confirmDanger
                ? VButtonVariant.dangerOutline
                : VButtonVariant.primary,
            tone: widget.confirmDanger
                ? VComponentTone.danger
                : VComponentTone.success,
            fullWidth: true,
            isLoading: _submitting,
            onPressed: _submitting ? null : _confirm,
          ),
        ],
      ),
    );
  }
}
