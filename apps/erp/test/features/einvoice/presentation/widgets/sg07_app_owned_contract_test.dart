import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('th08_s5_sg07 runtime host owns send, resend and history surfaces', () {
    final source = File(
      'lib/features/einvoice/presentation/widgets/order_einvoice_section.dart',
    ).readAsStringSync();

    expect(source, contains("'send_invoice_sheet.dart'"));
    expect(source, contains("'resend_invoice_sheet.dart'"));
    expect(source, contains('InvoiceDeliveryHistoryPage'));
  });

  test('th08_s5_sg07 runtime host does not call module-owned SG-07 show helpers', () {
    final source = File(
      'lib/features/einvoice/presentation/widgets/order_einvoice_section.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('showSendInvoiceSheet(')));
    expect(source, isNot(contains('showResendInvoiceSheet(')));
  });
}
