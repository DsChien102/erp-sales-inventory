import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../support/send_invoice_copy.dart';

/// Shows a danger toast after determinate invoice email delivery failure.
///
/// Design feedback SG07-T03 / T04 (same implementation).
abstract final class SendFailureToast {
  static void show(BuildContext context) {
    VToast.show(
      context,
      title: '',
      message: SendInvoiceCopy.sendFailureMessage,
      type: VToastType.danger,
    );
  }
}
