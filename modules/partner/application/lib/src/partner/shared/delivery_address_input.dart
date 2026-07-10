/// Delivery address fields shared by person and organization profiles.
final class DeliveryAddressInput {
  const DeliveryAddressInput({
    this.province,
    this.commune,
    this.address,
  });

  final String? province;
  final String? commune;
  final String? address;
}
