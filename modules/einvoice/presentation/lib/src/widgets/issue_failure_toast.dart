import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../support/order_einvoice_copy.dart';

/// Shows a danger toast when E-Invoice issuance fails.
///
/// Used with [OrderEInvoiceRow] (`failed`) for SG03-R02 feedback.
/// Not a separate audit specimen.
abstract final class IssueFailureToast {
  static void show(BuildContext context) {
    VToast.show(
      context,
      title: '',
      message: OrderEInvoiceCopy.issueFailureMessage,
      type: VToastType.danger,
    );
  }
}
