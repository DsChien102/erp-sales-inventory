/// Contract for launching invoice viewer links without platform dependencies.
abstract interface class IInvoiceViewerLauncher {
  Future<bool> launch(String url);
}
