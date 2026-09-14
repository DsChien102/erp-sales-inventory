import 'package:flutter/material.dart';

import 'sales_document_action_sheet.dart';

enum SalesResultReceiptAction { view, print, share }

Future<SalesResultReceiptAction?> showSalesResultReceiptSheet(
  BuildContext context,
) {
  return showSalesDocumentActionSheet<SalesResultReceiptAction>(
    context: context,
    copy: const SalesDocumentActionSheetCopy(
      title: 'Phiếu bán hàng',
      semanticLabel: 'Phiếu bán hàng',
      viewTitle: 'Xem phiếu',
      viewSubtitle: 'Kiểm tra phiếu trước khi in hoặc gửi',
      printTitle: 'In phiếu',
      printSubtitle: 'Chọn máy in và số bản cần in',
      shareTitle: 'Chia sẻ phiếu',
      shareSubtitle: 'Gửi qua ứng dụng khác',
      viewKey: Key('btn_receipt_action_view'),
      printKey: Key('btn_receipt_action_print'),
      shareKey: Key('btn_receipt_action_share'),
    ),
    view: SalesResultReceiptAction.view,
    print: SalesResultReceiptAction.print,
    share: SalesResultReceiptAction.share,
  );
}
