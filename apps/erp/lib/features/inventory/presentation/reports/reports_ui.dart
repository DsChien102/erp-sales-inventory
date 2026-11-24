import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/reports/reports_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:c45_design_system/design_system.dart';

/// Lấy `ReportsRepository` từ cây widget (test) hoặc `getIt` (chạy thật).
ReportsRepository resolveReportsRepository(BuildContext context) {
  try {
    return context.read<ReportsRepository>();
  } catch (_) {
    return getIt<ReportsRepository>();
  }
}

/// `dd/MM/yyyy`.
String reportDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Dòng "Nhãn **giá trị**" — `.bj15-total` của prototype.
class ReportTotalLine extends StatelessWidget {
  const ReportTotalLine({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Text.rich(
      TextSpan(
        style: VTypography.bodyDefault.copyWith(
          color: colors.textSecondary,
          height: 22 / 14,
        ),
        children: [
          TextSpan(text: '$label '),
          TextSpan(
            text: value,
            style: VTypography.monoNumeric.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
              height: 22 / 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ghi chú 13/20 secondary — `.bj15-note`.
class ReportNote extends StatelessWidget {
  const ReportNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: VTypography.bodySmall.copyWith(
        color: context.vColors.textSecondary,
        height: 20 / 13,
      ),
    );
  }
}

/// Số trong ô bảng: mono, căn phải.
Widget reportNumberCell(BuildContext context, String text, {bool bold = false}) {
  return Text(
    text,
    textAlign: TextAlign.end,
    style: VTypography.monoNumeric.copyWith(
      color: context.vColors.textPrimary,
      fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
    ),
  );
}

/// Ô "Sản phẩm": tên đậm + phụ `mã · ĐVT`.
Widget reportProductCell(
  BuildContext context, {
  required String name,
  required String sub,
}) {
  final colors = context.vColors;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        name,
        style: VTypography.bodyDefault.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      if (sub.isNotEmpty)
        Text(
          sub,
          style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
        ),
    ],
  );
}

Widget reportBackButton(VoidCallback onPressed, {String tooltip = 'Quay lại'}) {
  return IconButton(
    icon: const Icon(Icons.arrow_back),
    tooltip: tooltip,
    onPressed: onPressed,
  );
}
