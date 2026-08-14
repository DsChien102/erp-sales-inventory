/// Bearer session issued by meInvoice (`/auth/token` or refresh).
final class MeInvoiceSessionToken {
  const MeInvoiceSessionToken({required this.value, required this.expiresAt});

  final String value;
  final DateTime expiresAt;
}
