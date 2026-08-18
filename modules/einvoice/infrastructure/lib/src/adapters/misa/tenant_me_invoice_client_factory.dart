import 'package:http/http.dart' as http;
import 'package:vet45_misa/e_invoice.dart';

/// Per-tenant [MeInvoiceClient] cache (token scoped by client instance).
final class TenantMeInvoiceClientFactory {
  TenantMeInvoiceClientFactory();

  final Map<String, MeInvoiceClient> _clients = {};
  final Map<String, Object> _locks = {};

  MeInvoiceClient getOrCreate({
    required String tenantId,
    required MeInvoiceConfig config,
    http.Client? httpClient,
  }) {
    final existing = _clients[tenantId];
    if (existing != null) {
      return existing;
    }
    final client = MeInvoiceClient(config: config, httpClient: httpClient);
    _clients[tenantId] = client;
    _locks.putIfAbsent(tenantId, Object.new);
    return client;
  }

  void invalidate(String tenantId) {
    _clients.remove(tenantId);
  }
}
