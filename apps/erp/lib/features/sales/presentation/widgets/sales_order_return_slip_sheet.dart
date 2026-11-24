import 'package:flutter/material.dart';

import 'sales_document_action_sheet.dart';

enum SalesReturnExchangeSlipAction { view, print, share }

Future<SalesReturnExchangeSlipAction?> showSalesReturnExchangeSlipSheet(
  BuildContext context,
) {
  return showSalesDocumentActionSheet<SalesReturnExchangeSlipAction>(
    context: context,
    copy: const SalesDocumentActionSheetCopy(
      title: 'Phiếu đổi/trả',
      semanticLabel: 'Phiếu đổi/trả',
      viewTitle: 'Xem trước phiếu',
      viewSubtitle: 'Kiểm tra nội dung trước khi in hoặc chia sẻ',
      printTitle: 'In phiếu',
      printSubtitle: 'In phiếu đổi/trả cho khách',
      shareTitle: 'Chia sẻ phiếu',
      shareSubtitle: 'Gửi qua ứng dụng khác',
      viewKey: Key('btn_return_action_view'),
      printKey: Key('btn_return_action_print'),
      shareKey: Key('btn_return_action_share'),
    ),
    view: SalesReturnExchangeSlipAction.view,
    print: SalesReturnExchangeSlipAction.print,
    share: SalesReturnExchangeSlipAction.share,
  );
}
