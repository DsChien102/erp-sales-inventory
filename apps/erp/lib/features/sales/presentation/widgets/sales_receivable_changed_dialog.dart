import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Hộp thoại một nút (khuôn `_ConfirmBox` của `customer_collection_sheet.dart`).
class SalesReceivableChangedDialog extends StatelessWidget {
  const SalesReceivableChangedDialog({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.sheet)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.space5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: VTypography.headingH3.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: VSpacing.space4),
              Align(
                alignment: Alignment.centerRight,
                child: VButton(
                  key: const Key('btn_sg13_reload'),
                  label: 'Tải lại',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
