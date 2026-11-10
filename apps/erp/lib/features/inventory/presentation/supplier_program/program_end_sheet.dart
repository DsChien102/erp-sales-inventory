import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Sheet xác nhận kết thúc chương trình (mục 2.3):
/// Tiêu đề: 'Kết thúc chương trình "{tên}"?'
/// Nội dung: 'Phiếu nhận sau sẽ không áp ưu đãi này nữa. Không mở lại được.'
/// Nút: 'Kết thúc' (danger) · 'Huỷ'
Future<bool> showProgramEndSheet(
  BuildContext context, {
  required String programName,
}) async {
  final confirmed = await showVAdaptiveSheet<bool>(
    context: context,
    title: 'Kết thúc chương trình "$programName"?',
    child: Padding(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VText(
            'Phiếu nhận sau sẽ không áp ưu đãi này nữa. Không mở lại được.',
            variant: VTextVariant.bodyDefault,
            color: context.vColors.textSecondary,
          ),
          const SizedBox(height: VSpacing.space4),
          Row(
            children: [
              Expanded(
                child: VButton(
                  label: 'Huỷ',
                  variant: VButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: VSpacing.space2),
              Expanded(
                child: VButton(
                  label: 'Kết thúc',
                  variant: VButtonVariant.primary,
                  tone: VComponentTone.danger,
                  fullWidth: true,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return confirmed == true;
}

