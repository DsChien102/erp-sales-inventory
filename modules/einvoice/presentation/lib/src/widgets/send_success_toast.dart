import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../support/send_invoice_copy.dart';

/// Shows a success toast after invoice email delivery succeeds.
///
/// Design feedback SG07-T01 / T02 (same implementation).
abstract final class SendSuccessToast {
  static void show(BuildContext context) {
    VToast.show(
      context,
      title: '',
      message: SendInvoiceCopy.sendSuccessMessage,
      type: VToastType.success,
    );
  }
}
