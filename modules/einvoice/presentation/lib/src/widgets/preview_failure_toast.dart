import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../support/order_einvoice_copy.dart';

/// Shows a toast when E-Invoice preview fails.
///
/// Implements SG02-T01.
abstract final class PreviewFailureToast {
  static void show(BuildContext context) {
    VToast.show(
      context,
      title: '',
      message: OrderEInvoiceCopy.previewFailureMessage,
      type: VToastType.danger,
    );
  }
}
