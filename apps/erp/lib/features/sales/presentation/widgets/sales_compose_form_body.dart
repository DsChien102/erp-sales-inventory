import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/sales/presentation.dart';

import '../lookups/sales_catalog_product_lookup.dart';

class SalesComposeFormBody extends StatelessWidget {
  const SalesComposeFormBody({
    super.key,
    required this.state,
    required this.onSelectCustomer,
    required this.onCreateCustomer,
    required this.onSelectSuggestedProduct,
    required this.onQuantityChanged,
    required this.onDiscount,
    required this.onDeleteLine,
    required this.onLineTap,
    required this.onStockExceeded,
    required this.onNoteChanged,
  });

  final SalesComposeState state;
  final VoidCallback onSelectCustomer;
  final VoidCallback onCreateCustomer;
  final ValueChanged<SalesSellableProductVm> onSelectSuggestedProduct;
  final String? Function(String lineId, int delta) onQuantityChanged;
  final ValueChanged<SalesComposeLineVm> onDiscount;
  final ValueChanged<String> onDeleteLine;
  final ValueChanged<SalesComposeLineVm> onLineTap;
  final VoidCallback onStockExceeded;
  final ValueChanged<String> onNoteChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const VGap.cozy(),
        VPagePadding(
          child: SalesComposeCustomerCard(
            customer: state.customer,
            onSelectCustomer: onSelectCustomer,
            onCreateCustomer: onCreateCustomer,
          ),
        ),
        if (state.customer.isOrganizationWithoutTaxCode) ...[
          const VGap(VSpacing.space2),
          const VPagePadding(
            child: VBanner(
              key: Key('banner_org_no_tax_code'),
              status: VBannerStatus.warning,
              title: 'Khách tổ chức chưa có mã số thuế',
              description:
                  'Vẫn có thể bán hàng nhưng chưa thể phát hành hóa đơn điện tử.',
            ),
          ),
        ],
        if (state.pricingMessage != null) ...[
          const VGap(VSpacing.space2),
          VPagePadding(
            child: VText(
              state.pricingMessage!,
              variant: VTextVariant.bodySmall,
              color: colors.warning,
            ),
          ),
        ],
        const VGap(VSpacing.space2),
        VPagePadding(
          child: SalesComposeProductSearchBar(
            onSelectProduct: onSelectSuggestedProduct,
            onScanTap: () => showSalesBarcodeSearchHint(context),
            searchProducts: SalesCatalogProductLookup.bindSearch(),
            resolveBarcode: SalesCatalogProductLookup.bindBarcode(),
          ),
        ),
        const VGap(VSpacing.space2),
        Expanded(
          child: VPagePadding(
            child: SalesComposeLinesSection(
              lines: state.lines,
              totals: state.totals,
              onQuantityChanged: onQuantityChanged,
              onDiscount: onDiscount,
              onDelete: (line) => onDeleteLine(line.identity.lineId),
              onLineTap: onLineTap,
              onStockExceeded: onStockExceeded,
            ),
          ),
        ),
        const VGap.sm(),
        VPagePadding(
          child: SalesComposeOrderNoteTile(
            note: state.orderNote,
            onChanged: onNoteChanged,
          ),
        ),
        const VGap.sm(),
      ],
    );
  }
}
