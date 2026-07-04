import 'package:vet45_catalog_domain/domain.dart';

abstract interface class IProductCommandGateway {
  Future<String> create({
    required Product product,
    required String idempotencyKey,
  });
}
