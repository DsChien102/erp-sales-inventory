import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

import '../navigation/sales_typed_routes.dart';

/// Safe deep-link / missing-extra state for checkout (`SalesCheckoutRoute`).
///
/// Does not fabricate lines, totals, store IDs, or customer IDs.
class SalesCheckoutInvalidEntryPage extends StatelessWidget {
  const SalesCheckoutInvalidEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return VPageScaffold(
      key: const Key('wgt_sg05_invalid_entry'),
      title: 'Thanh toán',
      showBackButton: true,
      body: VPagePadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const VText(
              'Không thể mở thanh toán từ liên kết này. '
              'Hãy quay lại tạo đơn và chọn Thanh toán từ đơn đang soạn.',
              variant: VTextVariant.bodyDefault,
            ),
            const VGap.md(),
            VButton(
              key: const Key('btn_sg05_invalid_return_compose'),
              label: 'Quay lại tạo đơn',
              tone: VComponentTone.success,
              fullWidth: true,
              onPressed: () => const SalesComposeRoute().go(context),
            ),
          ],
        ),
      ),
    );
  }
}
