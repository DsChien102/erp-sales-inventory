/// POST `/auth/token` body (§2).
final class MeInvoiceAuthTokenRequest {
  const MeInvoiceAuthTokenRequest({
    required this.appId,
    required this.taxCode,
    required this.username,
    required this.password,
  });

  final String appId;
  final String taxCode;
  final String username;
  final String password;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'appid': appId,
    'taxcode': taxCode,
    'username': username,
    'password': password,
  };
}
