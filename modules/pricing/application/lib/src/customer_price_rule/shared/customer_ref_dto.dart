final class CustomerRefDto {
  const CustomerRefDto({
    required this.customerId,
    required this.displayName,
    required this.status,
    this.phone,
  });

  final String customerId;
  final String displayName;
  final String status;
  final String? phone;
}
