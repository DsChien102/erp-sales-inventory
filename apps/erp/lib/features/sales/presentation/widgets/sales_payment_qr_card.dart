import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'package:erp/core/formatting/money_formatter.dart';
/// SG-05 / SG-10 — Thẻ hiển thị mã QR thanh toán (VietQR).
class SalesPaymentQrCard extends StatelessWidget {
  const SalesPaymentQrCard({
    super.key,
    required this.amountMinor,
    this.bankTitle = 'VET45 · ACB',
    this.accountNumber = '1028 6888',
    this.accountName = 'Nguyễn Văn A',
    this.qrImage,
  });
  final int amountMinor;
  final String bankTitle;
  final String accountNumber;
  final String accountName;

  /// Ảnh QR (MemoryImage / NetworkImage / AssetImage). Null → placeholder icon.
  final ImageProvider? qrImage;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return IntrinsicHeight(
      child: Row(
        key: const Key('wgt_sales_payment_qr_card'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ô QR vuông: cạnh = chiều cao của cột thông tin bên phải.
          AspectRatio(
            aspectRatio: 1,
            child: qrImage == null
                ? VIconBox(
                    icon: VIcons.qrCode,
                    backgroundColor: colors.surfaceAlt,
                    size: 80,
                    iconSize: 60,
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(VRadius.iconBox),
                    child: Image(
                      key: const Key('img_sales_payment_qr'),
                      image: qrImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
          const VGap.horizontalMd(),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  bankTitle,
                  variant: VTextVariant.bodyDefault,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const VGap.xs(),
                VText(
                  accountNumber,
                  variant: VTextVariant.bodyDefault,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                VText(
                  accountName,
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
                const VGap.xs(),
                VText(
                  'Số tiền trên QR',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
                VText(
                  MoneyFormatter.formatMinor(amountMinor),
                  variant: VTextVariant.bodyDefaultMono,
                  color: colors.success,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
