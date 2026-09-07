import 'package:http/http.dart' as http;
import 'package:vet45_misa/e_invoice.dart';

/// Per-tenant [MeInvoiceClient] cache (token scoped by client instance).
final class TenantMeInvoiceClientFactory {
  TenantMeInvoiceClientFactory();

  final Map<String, IMeInvoiceClient> _clients = {};
  final Map<String, MeInvoiceConfig> _configs = {};
  final Map<String, Object> _locks = {};

  /// Registers a deterministic client for tests (bypasses credential-based creation).
  void setClientForTesting({
    required String tenantId,
    required IMeInvoiceClient client,
    MeInvoiceConfig? config,
  }) {
    _clients[tenantId] = client;
    if (config != null) {
      _configs[tenantId] = config;
    }
  }

  IMeInvoiceClient getOrCreate({
    required String tenantId,
    required MeInvoiceConfig config,
    http.Client? httpClient,
  }) {
    final existing = _clients[tenantId];
    final existingConfig = _configs[tenantId];
    if (existing != null &&
        existingConfig != null &&
        _sameConfig(existingConfig, config)) {
      return existing;
    }
    final client = MeInvoiceClient(config: config, httpClient: httpClient);
    _clients[tenantId] = client;
    _configs[tenantId] = config;
    _locks.putIfAbsent(tenantId, Object.new);
    return client;
  }

  void invalidate(String tenantId) {
    _clients.remove(tenantId);
    _configs.remove(tenantId);
  }

  static bool _sameConfig(MeInvoiceConfig left, MeInvoiceConfig right) {
    return left.baseUrl == right.baseUrl &&
        left.appId == right.appId &&
        left.taxCode == right.taxCode &&
        left.username == right.username &&
        left.password == right.password &&
        left.accessToken == right.accessToken &&
        left.accessTokenExpiresAt == right.accessTokenExpiresAt;
  }
}
