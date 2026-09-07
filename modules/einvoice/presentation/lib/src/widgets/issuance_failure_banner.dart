import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../support/order_einvoice_copy.dart';

/// Presentation widget displaying safe allow-listed issuance failure feedback.
///
/// Never exposes raw provider payload, credentials, failureOrigin or internal retry internals.
class IssuanceFailureBanner extends StatelessWidget {
  const IssuanceFailureBanner({
    super.key,
    this.failureCode,
    this.lastFailureMessage,
  });

  final String? failureCode;
  final String? lastFailureMessage;

  @override
  Widget build(BuildContext context) {
    final message = OrderEInvoiceCopy.safeFailureMessage(
      failureCode: failureCode,
      lastFailureMessage: lastFailureMessage,
    );

    return VBanner(
      status: VBannerStatus.error,
      title: OrderEInvoiceCopy.failureBannerTitle,
      description: message,
    );
  }
}
