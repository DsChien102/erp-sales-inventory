import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/shared/sales_customer_picker_state.dart';
import '../models/shared/sales_customer_selection.dart';
import 'sales_customer_picker_body_empty_state.dart';
import 'sales_customer_picker_body_error_state.dart';
import 'sales_customer_picker_body_no_result_state.dart';
import 'sales_customer_picker_card.dart';
import 'sales_customer_picker_loading_state.dart';

/// Danh sách / empty / no-result / error cho SG-04 picker.
///
/// [onQuickCreate] tùy chọn — null thì empty/no-result không hiện CTA trong body
/// (sheet dùng nút đáy riêng).
class SalesCustomerPickerBody extends StatelessWidget {
  const SalesCustomerPickerBody({
    super.key,
    required this.state,
    required this.onTapCustomer,
    this.onClearSearch,
    this.onQuickCreate,
    this.selectedPartnerId,
    this.showResultCount = true,
  });

  final SalesCustomerPickerState state;
  final ValueChanged<SalesCustomerListItemVm> onTapCustomer;
  final VoidCallback? onClearSearch;
  final VoidCallback? onQuickCreate;
  final String? selectedPartnerId;
  final bool showResultCount;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      SalesCustomerPickerLoading() => SalesCustomerPickerLoadingState(
        showResultCount: showResultCount,
      ),
      SalesCustomerPickerEmpty() => SalesCustomerPickerBodyEmptyState(
        onQuickCreate: onQuickCreate,
      ),
      SalesCustomerPickerNoResult(:final query) => SalesCustomerPickerBodyNoResultState(
        query: query,
        onQuickCreate: onQuickCreate,
      ),
      SalesCustomerPickerError(:final title, :final description) =>
        SalesCustomerPickerBodyErrorState(
          title: title,
          description: description,
        ),
      SalesCustomerPickerLoaded(:final items, :final query) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showResultCount) ...[
            VPagePadding(
              child: VText(
                query.isEmpty ? '${items.length} khách hàng' : '${items.length} kết quả · “$query”',
                key: const Key('txt_sg04_result_count'),
                variant: VTextVariant.bodySmall,
                color: context.vColors.textSecondary,
              ),
            ),
            const VGap.sm(),
          ],
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                VSpacing.screenMobile,
                0,
                VSpacing.screenMobile,
                VSpacing.space8,
              ),
              itemCount: items.length,
              separatorBuilder: (_, _) => const VGap.sm(),
              itemBuilder: (context, index) {
                final item = items[index];
                return SalesCustomerPickerCard.fromItem(
                  item: item,
                  selected: selectedPartnerId == item.partnerId,
                  onTap: () => onTapCustomer(item),
                );
              },
            ),
          ),
        ],
      ),
    };
  }
}
