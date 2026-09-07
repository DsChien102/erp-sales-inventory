import 'package:async_query/async_query.dart';

abstract final class EinvoiceQueryKeys {
  static QueryKey providerConnection(String tenantId) => [
    'einvoice',
    'provider_connection',
    tenantId,
  ];
}
