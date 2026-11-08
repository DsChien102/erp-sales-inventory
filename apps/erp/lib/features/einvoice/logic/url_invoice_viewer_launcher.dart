import 'package:url_launcher/url_launcher.dart';

import 'i_invoice_viewer_launcher.dart';

/// URL launcher implementation for viewing electronic invoices in-app.
final class UrlInvoiceViewerLauncher implements IInvoiceViewerLauncher {
  const UrlInvoiceViewerLauncher({
    Future<bool> Function(Uri uri, {LaunchMode mode})? launchUrlFn,
  }) : _launchUrlFn = launchUrlFn;

  final Future<bool> Function(Uri uri, {LaunchMode mode})? _launchUrlFn;

  @override
  Future<bool> launch(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      return false;
    }

    final launchFn = _launchUrlFn ?? launchUrl;

    // Tier 1: Attempt in-app browser view
    try {
      final success = await launchFn(uri, mode: LaunchMode.inAppBrowserView);
      if (success) {
        return true;
      }
    } catch (_) {
      // In-app browser rejected (e.g. SFSafariViewController on file/ashx download handler)
    }

    // Tier 2: Fallback to external application (system Safari / browser)
    try {
      return await launchFn(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
