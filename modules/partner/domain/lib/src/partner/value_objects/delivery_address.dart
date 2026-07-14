import 'package:vet45_shared_domain/shared_kernel_domain.dart';

/// Delivery address fields.
final class DeliveryAddress extends ValueObject {
  const DeliveryAddress({
    this.province,
    this.commune,
    this.address,
  });

  final String? province;
  final String? commune;
  final String? address;

  @override
  List<Object?> get props => [province, commune, address];
}
