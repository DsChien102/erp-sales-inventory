import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class PlatformUserActionCard extends StatelessWidget {
  const PlatformUserActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  final VIcons icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final cardBg = isDestructive ? colors.dangerBg : colors.surface;
    final cardBorder = isDestructive
        ? colors.danger
        : colors.borderDefault;
    final textColor = isDestructive ? colors.danger : colors.textPrimary;
    final subtitleColor = colors.textSecondary;
    final iconColor = isDestructive ? colors.danger : colors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VRadius.r12),
        child: Ink(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(VRadius.r12),
            border: Border.all(color: cardBorder, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.space4,
              vertical: 14,
            ),
            child: Row(
              children: [
                VIcon(icon: icon, color: iconColor, size: 24),
                const VGap.horizontalMd(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VText(
                        title,
                        variant: VTextVariant.bodyDefault,
                        color: textColor,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const VGap.xs(),
                      VText(
                        subtitle,
                        variant: VTextVariant.bodySmall,
                        color: subtitleColor,
                      ),
                    ],
                  ),
                ),
                VIcon(
                  icon: VIcons.chevronRight,
                  color: isDestructive ? colors.danger : colors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Confirm sheet — stays open on failure; caller pops only on success.
Future<void> showPlatformUserConfirmSheet({
  required BuildContext context,
  required String title,
  required Color titleColor,
  required String description,
  required String actionLabel,
  required VButtonVariant actionVariant,
  VComponentTone? actionTone,
  required Future<bool> Function(String reason) onConfirm,
  bool requireReason = false,
  String? localError,
}) {
  return showVBottomSheet(
    context: context,
    child: _PlatformUserConfirmSheetBody(
      title: title,
      titleColor: titleColor,
      description: description,
      actionLabel: actionLabel,
      actionVariant: actionVariant,
      actionTone: actionTone,
      onConfirm: onConfirm,
      requireReason: requireReason,
    ),
  );
}

class _PlatformUserConfirmSheetBody extends StatefulWidget {
  const _PlatformUserConfirmSheetBody({
    required this.title,
    required this.titleColor,
    required this.description,
    required this.actionLabel,
    required this.actionVariant,
    this.actionTone,
    required this.onConfirm,
    required this.requireReason,
  });

  final String title;
  final Color titleColor;
  final String description;
  final String actionLabel;
  final VButtonVariant actionVariant;
  final VComponentTone? actionTone;
  final Future<bool> Function(String reason) onConfirm;
  final bool requireReason;

  @override
  State<_PlatformUserConfirmSheetBody> createState() =>
      _PlatformUserConfirmSheetBodyState();
}

class _PlatformUserConfirmSheetBodyState
    extends State<_PlatformUserConfirmSheetBody> {
  late final TextEditingController _reasonController;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final reason = _reasonController.text.trim();
    if (widget.requireReason && reason.isEmpty) {
      setState(() => _error = 'Vui lòng nhập lý do.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final ok = await widget.onConfirm(reason);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _submitting = false;
      _error = 'Không hoàn tất thao tác. Vui lòng thử lại.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Padding(
      padding: const EdgeInsets.all(VSpacing.screenMobile),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VText(
            widget.title,
            variant: VTextVariant.headingH3,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: widget.titleColor,
            ),
          ),
          const VGap.sm(),
          VText(
            widget.description,
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
          ),
          if (widget.requireReason) ...[
            VField(
              invalid: _error != null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const VFieldLabel('Lý do', isRequired: true),
                  VTextFormField(
                    controller: _reasonController,
                    hintText: 'Nhập lý do',
                    enabled: !_submitting,
                    maxLines: 2,
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                  ),
                  if (_error != null)
                    VFieldError(_error!)
                  else
                    const VFieldDescription(
                      'Lý do được lưu trong lịch sử quản trị.',
                    ),
                ],
              ),
            ),
          ] else if (_error != null) ...[
            const VGap.sm(),
            VText(
              _error!,
              variant: VTextVariant.bodySmall,
              color: colors.danger,
            ),
          ],
          const VGap.lg(),
          VButton(
            label: 'Quay lại',
            variant: VButtonVariant.secondary,
            fullWidth: true,
            onPressed: _submitting ? null : () => Navigator.pop(context),
          ),
          const VGap.sm(),
          VButton(
            label: widget.actionLabel,
            variant: widget.actionVariant,
            tone: widget.actionTone,
            fullWidth: true,
            isLoading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
          const VGap.sm(),
        ],
      ),
    );
  }
}
