import 'package:flutter/material.dart';
import 'package:erp/features/sales/presentation.dart';

import 'fixtures.dart';
import 'preview_helpers.dart';
import 'preview_section.dart';

class SalesSg04CustomerPickerTab extends StatelessWidget {
  const SalesSg04CustomerPickerTab({super.key});

  @override
  Widget build(BuildContext context) {
    return previewList([
      PreviewSection(
        title: 'SalesCustomerPickerSearchBar',
        child: SalesCustomerPickerSearchBar(
          onSearch: (_) {},
          initialQuery: 'Thu',
        ),
      ),
      PreviewSection(
        title: 'SalesCustomerPickerCard',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'Default',
              child: SalesCustomerPickerCard.fromItem(
                item: SalesPreviewFixtures.customerItem,
                onTap: () {},
              ),
            ),
            PreviewStateRow(
              label: 'Selected',
              child: SalesCustomerPickerCard.fromItem(
                item: SalesPreviewFixtures.customerItem,
                selected: true,
                onTap: () {},
              ),
            ),
            PreviewStateRow(
              label: 'Disabled / blocked',
              child: SalesCustomerPickerCard.fromItem(
                item: SalesPreviewFixtures.customerBlocked,
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'SalesCustomerPickerBody',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'Loading (skeleton)',
              child: PreviewEmbedFrame(
                height: 260,
                child: SalesCustomerPickerBody(
                  state: const SalesCustomerPickerLoading(),
                  onTapCustomer: (_) {},
                ),
              ),
            ),
            PreviewStateRow(
              label: 'Empty (+ CTA)',
              child: PreviewEmbedFrame(
                height: 240,
                child: SalesCustomerPickerBody(
                  state: const SalesCustomerPickerEmpty(),
                  onTapCustomer: (_) {},
                  onQuickCreate: () {},
                ),
              ),
            ),
            PreviewStateRow(
              label: 'Empty (no CTA — sheet)',
              child: PreviewEmbedFrame(
                height: 200,
                child: SalesCustomerPickerBody(
                  state: const SalesCustomerPickerEmpty(),
                  onTapCustomer: (_) {},
                ),
              ),
            ),
            PreviewStateRow(
              label: 'No result',
              child: PreviewEmbedFrame(
                height: 260,
                child: SalesCustomerPickerBody(
                  state: const SalesCustomerPickerNoResult(query: 'xyz'),
                  onTapCustomer: (_) {},
                  onQuickCreate: () {},
                ),
              ),
            ),
            PreviewStateRow(
              label: 'Error',
              child: PreviewEmbedFrame(
                height: 220,
                child: SalesCustomerPickerBody(
                  state: const SalesCustomerPickerError(
                    query: 'abc',
                    title: 'Không thể tìm kiếm',
                    description: 'Kiểm tra kết nối và thử lại.',
                  ),
                  onTapCustomer: (_) {},
                ),
              ),
            ),
            PreviewStateRow(
              label: 'Loaded + selected',
              child: PreviewEmbedFrame(
                height: 220,
                child: SalesCustomerPickerBody(
                  state: SalesCustomerPickerLoaded(
                    query: '',
                    items: SalesPreviewFixtures.customers,
                  ),
                  selectedPartnerId: SalesPreviewFixtures.customerItem.partnerId,
                  onTapCustomer: (_) {},
                ),
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'Sheets',
        description: 'SG-04 không có ERP page — chọn KH qua sheet từ compose.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PreviewActionButton(
              label: 'Select customer sheet',
              onPressed: () => showSalesCustomerSelectSheet(
                context,
                searchCustomers: (_) async => SalesPreviewFixtures.customers,
                onCreateCustomer: () {},
              ),
            ),
            PreviewActionButton(
              label: 'Quick create customer',
              onPressed: () => SalesCustomerQuickCreateSheet.show(
                context,
                checkDuplicate: (_) async => null,
                createCustomer: (draft, {required bool confirmDuplicate}) async {
                  return SalesCustomerSelection(
                    isWalkIn: false,
                    displayName: draft.displayName,
                    phone: draft.phone,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}
