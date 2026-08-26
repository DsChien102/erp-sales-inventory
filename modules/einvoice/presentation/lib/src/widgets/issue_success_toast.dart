import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../support/order_einvoice_copy.dart';

/// Shows a success toast after E-Invoice issuance completes.
///
/// Implements SG03-T01 / SG03-T02.
abstract final class IssueSuccessToast {
  static void show(BuildContext context) {
    VToast.show(
      context,
      title: '',
      message: OrderEInvoiceCopy.issueSuccessMessage,
      type: VToastType.success,
    );
  }
}
