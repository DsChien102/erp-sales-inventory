/// Typed result for meInvoice client calls (ok / failed).
final class MeInvoiceResult<T> {
  const MeInvoiceResult.ok(this.data)
    : error = null,
      rateLimited = false;

  const MeInvoiceResult.failed(this.error, {this.rateLimited = false})
    : data = null;

  final T? data;
  final String? error;
  final bool rateLimited;

  bool get isSuccess => data != null && error == null;
}
